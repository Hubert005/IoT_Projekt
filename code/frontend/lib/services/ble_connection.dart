import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Verbindungs-Singleton fuer das ESP32-BLE-Backend.
///
/// Wire-Protokoll: zeilenbasiert, UTF-8, '\n'-terminiert. Unterstuetzt
/// sowohl Request/Response (Ping, Mix) als auch Push-Nachrichten vom
/// ESP (z. B. `runde_<i>_<p1>_<p2>` im laufenden Spiel) - daher gibt
/// es eine kleine Inbox-Queue und einen [nextLine]-Mechanismus.
class BleConnection {
  BleConnection._();
  static final BleConnection instance = BleConnection._();

  // Nordic-UART-Profil - matched code/backend/code_esp32-c3/src/main.cpp
  static const String deviceName  = 'DrDrDrSams';
  static const String serviceUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const String rxUuid      = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
  static const String txUuid      = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  BluetoothDevice? _device;
  BluetoothCharacteristic? _rx; // App schreibt darauf
  BluetoothCharacteristic? _tx; // App empfaengt Notifications

  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<BluetoothConnectionState>? _stateSub;

  String _buf = '';

  // Inbox: bereits empfangene Zeilen, die noch niemand abgeholt hat.
  final Queue<String> _inbox = Queue<String>();
  // Wartender Consumer fuer die naechste Zeile.
  Completer<String>? _waiter;

  bool get isConnected => _device?.isConnected ?? false;
  String? get connectedDeviceId => _device?.remoteId.str;

  // ---------- Verbinden / Trennen ----------

  Future<bool> connect({
    Duration scanTimeout = const Duration(seconds: 6),
  }) async {
    if (isConnected) return true;

    final supported = await FlutterBluePlus.isSupported;
    if (!supported) return false;

    try {
      await FlutterBluePlus.adapterState
          .firstWhere((s) => s == BluetoothAdapterState.on)
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      return false;
    }

    BluetoothDevice? found;
    final scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final name = r.advertisementData.advName.isNotEmpty
            ? r.advertisementData.advName
            : r.device.platformName;
        if (name == deviceName) {
          found = r.device;
          FlutterBluePlus.stopScan();
          break;
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: scanTimeout,
        withServices: [Guid(serviceUuid)],
      );
      await FlutterBluePlus.isScanning.firstWhere((v) => v == false);
    } finally {
      await scanSub.cancel();
    }

    if (found == null) return false;
    final device = found!;

    try {
      await device.connect(autoConnect: false, mtu: 185);
    } catch (_) {
      return false;
    }

    _device = device;
    _stateSub = device.connectionState.listen((s) {
      if (s == BluetoothConnectionState.disconnected) {
        _cleanupAfterDisconnect();
      }
    });

    final services = await device.discoverServices();
    for (final s in services) {
      if (s.uuid.str128.toLowerCase() != serviceUuid) continue;
      for (final c in s.characteristics) {
        final id = c.uuid.str128.toLowerCase();
        if (id == rxUuid) _rx = c;
        if (id == txUuid) _tx = c;
      }
    }
    if (_rx == null || _tx == null) {
      await disconnect();
      return false;
    }

    _buf = '';
    _inbox.clear();

    await _tx!.setNotifyValue(true);
    _notifySub = _tx!.onValueReceived.listen(_onIncomingBytes);

    return true;
  }

  Future<void> disconnect() async {
    await _notifySub?.cancel();
    _notifySub = null;
    await _stateSub?.cancel();
    _stateSub = null;
    try {
      await _device?.disconnect();
    } catch (_) {}
    _cleanupAfterDisconnect();
  }

  void _cleanupAfterDisconnect() {
    _device = null;
    _rx = null;
    _tx = null;
    _buf = '';
    _inbox.clear();
    final w = _waiter;
    _waiter = null;
    if (w != null && !w.isCompleted) {
      w.completeError(StateError('BLE getrennt'));
    }
  }

  // ---------- Empfang ----------

  void _onIncomingBytes(List<int> bytes) {
    if (bytes.isEmpty) return;
    _buf += utf8.decode(bytes, allowMalformed: true);

    var idx = _buf.indexOf('\n');
    while (idx >= 0) {
      final line = _buf.substring(0, idx).trim();
      _buf = _buf.substring(idx + 1);
      if (line.isNotEmpty) _deliverLine(line);
      idx = _buf.indexOf('\n');
    }
  }

  void _deliverLine(String line) {
    final w = _waiter;
    if (w != null && !w.isCompleted) {
      _waiter = null;
      w.complete(line);
    } else {
      _inbox.addLast(line);
    }
  }

  // ---------- Senden ----------

  /// Schreibt [cmd] (mit angehaengtem '\n') ohne auf eine Antwort zu warten.
  Future<void> send(String cmd) async {
    if (_rx == null || !isConnected) {
      throw StateError('BLE nicht verbunden');
    }
    final data = utf8.encode('$cmd\n');
    await _rx!.write(data, withoutResponse: false);
  }

  /// Wartet auf die naechste Zeile vom ESP, ohne selbst etwas zu senden.
  Future<String> nextLine({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_inbox.isNotEmpty) return _inbox.removeFirst();
    if (_waiter != null) {
      throw StateError('BLE: anderer Consumer wartet bereits');
    }
    final c = Completer<String>();
    _waiter = c;
    return c.future.timeout(timeout, onTimeout: () {
      _waiter = null;
      throw TimeoutException('BLE-Timeout beim Warten auf Zeile');
    });
  }

  /// Sendet [cmd] und wartet auf genau eine Antwortzeile.
  Future<String> request(
    String cmd, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_inbox.isNotEmpty) {
      // alte unbeobachtete Nachrichten verwerfen, damit request()
      // wirklich auf die FRISCHE Antwort wartet
      _inbox.clear();
    }
    if (_waiter != null) {
      throw StateError('BLE: andere Anfrage laeuft noch');
    }
    final c = Completer<String>();
    _waiter = c;

    try {
      await send(cmd);
    } catch (e) {
      _waiter = null;
      rethrow;
    }

    return c.future.timeout(timeout, onTimeout: () {
      _waiter = null;
      throw TimeoutException('BLE-Timeout fuer "$cmd"');
    });
  }

  /// Optionaler Health-Check.
  Future<bool> ping() async {
    try {
      final r = await request('ping', timeout: const Duration(seconds: 4));
      return r == 'pong';
    } catch (_) {
      return false;
    }
  }
}
