import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Singleton BLE service using the Nordic UART Service (NUS) profile.
///
/// UUIDs match the standard NUS layout that the ESP32 firmware exposes:
///   Service  6E400001-B5A3-F393-E0A9-E50E24DCCA9E
///   TX char  6E400002  (app → ESP, write)
///   RX char  6E400003  (ESP → app, notify)
class BleService {
  BleService._();
  static final instance = BleService._();

  static const _svcUuid = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
  static const _txUuid  = '6E400002-B5A3-F393-E0A9-E50E24DCCA9E';
  static const _rxUuid  = '6E400003-B5A3-F393-E0A9-E50E24DCCA9E';

  BluetoothDevice?         _device;
  BluetoothCharacteristic? _txChar;
  StreamSubscription?      _notifySub;
  StreamSubscription?      _connStateSub;
  bool                     _testMode = false;

  final _msgCtrl  = StreamController<String>.broadcast();
  final _connCtrl = StreamController<bool>.broadcast();
  final _sentCtrl = StreamController<String>.broadcast();
  bool _connected = false;

  Stream<String> get messageStream    => _msgCtrl.stream;
  Stream<bool>   get connectionStream => _connCtrl.stream;

  /// Stream of messages the app sends (visible in test mode).
  Stream<String> get sentMessages     => _sentCtrl.stream;

  bool   get isConnected => _connected;
  bool   get isTestMode  => _testMode;

  String? get deviceName {
    if (_testMode) return 'Test Modus';
    final name = _device?.platformName;
    return (name != null && name.isNotEmpty) ? name : _device?.remoteId.str;
  }

  // ── Test Mode ─────────────────────────────────────────────────────────────

  /// Simulates a BLE connection without real hardware.
  /// send() logs to sentMessages instead of writing to Bluetooth.
  void enableTestMode() {
    _testMode = true;
    _connected = true;
    _connCtrl.add(true);
  }

  void disableTestMode() {
    _testMode = false;
    _connected = false;
    _connCtrl.add(false);
  }

  /// Simulates a message arriving from the ESP32.
  void inject(String message) => _msgCtrl.add(message);

  // ── Scan ─────────────────────────────────────────────────────────────────

  Future<void> startScan() => FlutterBluePlus.startScan(
    timeout: const Duration(seconds: 10),
  );

  Future<void> stopScan() => FlutterBluePlus.stopScan();

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
  Stream<bool>             get isScanning  => FlutterBluePlus.isScanning;

  // ── Connect / Disconnect ─────────────────────────────────────────────────

  Future<void> connect(BluetoothDevice device) async {
    if (_connected) await disconnect();

    _device = device;
    await device.connect(autoConnect: false);

    _connStateSub = device.connectionState.listen((state) {
      final conn = state == BluetoothConnectionState.connected;
      if (_connected != conn) {
        _connected = conn;
        _connCtrl.add(conn);
      }
      if (!conn) _cleanup();
    });

    final services = await device.discoverServices();
    final svc = services.firstWhere(
      (s) => s.serviceUuid == Guid(_svcUuid),
    );

    _txChar = svc.characteristics.firstWhere(
      (c) => c.characteristicUuid == Guid(_txUuid),
    );
    final rxChar = svc.characteristics.firstWhere(
      (c) => c.characteristicUuid == Guid(_rxUuid),
    );

    await rxChar.setNotifyValue(true);
    _notifySub = rxChar.onValueReceived.listen((bytes) {
      final msg = utf8.decode(bytes).trim();
      if (msg.isNotEmpty) _msgCtrl.add(msg);
    });

    _connected = true;
    _connCtrl.add(true);
  }

  Future<void> disconnect() async {
    if (_testMode) {
      disableTestMode();
      return;
    }
    _cleanup();
    await _device?.disconnect();
    _device = null;
    _connected = false;
    _connCtrl.add(false);
  }

  void _cleanup() {
    _notifySub?.cancel();
    _notifySub = null;
    _connStateSub?.cancel();
    _connStateSub = null;
    _txChar = null;
  }

  // ── Send / Receive ───────────────────────────────────────────────────────

  Future<void> send(String message) async {
    if (_testMode) {
      _sentCtrl.add(message);
      return;
    }
    if (_txChar == null) throw StateError('BLE not connected');
    await _txChar!.write(utf8.encode('$message\n'), withoutResponse: false);
  }

  /// Resolves when the next incoming message starting with [prefix] arrives.
  Future<String> waitForMessage(String prefix,
      {Duration timeout = const Duration(seconds: 60)}) {
    final completer = Completer<String>();
    late StreamSubscription sub;
    final timer = Timer(timeout, () {
      sub.cancel();
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException('BLE timeout waiting for "$prefix"', timeout),
        );
      }
    });
    sub = messageStream.listen((msg) {
      if (msg.startsWith(prefix)) {
        timer.cancel();
        sub.cancel();
        if (!completer.isCompleted) completer.complete(msg);
      }
    });
    return completer.future;
  }
}
