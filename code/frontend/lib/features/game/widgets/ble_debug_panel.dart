import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/ble_service.dart';

class BleDebugPanel extends StatefulWidget {
  const BleDebugPanel({super.key});

  @override
  State<BleDebugPanel> createState() => _BleDebugPanelState();
}

class _BleDebugPanelState extends State<BleDebugPanel> {
  final List<_Msg> _log = [];
  StreamSubscription? _sentSub;
  StreamSubscription? _recvSub;

  @override
  void initState() {
    super.initState();
    final ble = BleService.instance;
    _sentSub = ble.sentMessages.listen(
      (m) => setState(() => _log.add(_Msg('APP → ESP', m, sent: true))),
    );
    _recvSub = ble.messageStream.listen(
      (m) => setState(() => _log.add(_Msg('ESP → APP', m, sent: false))),
    );
  }

  @override
  void dispose() {
    _sentSub?.cancel();
    _recvSub?.cancel();
    super.dispose();
  }

  void _inject(String msg) {
    BleService.instance.inject(msg);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, scroll) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              if (_log.isNotEmpty) ...[_buildLog(), const SizedBox(height: 12)],
              const Text('Simuliere ESP → APP:',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 6),
              Expanded(child: _buildButtons(scroll)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(
    children: [
      const Text('BLE Test Modus',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('SIMULIERT',
            style: TextStyle(color: Colors.green, fontSize: 11)),
      ),
    ],
  );

  Widget _buildLog() => Container(
    height: 110,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.black26,
      borderRadius: BorderRadius.circular(8),
    ),
    child: ListView.builder(
      reverse: true,
      itemCount: _log.length,
      itemBuilder: (_, i) {
        final msg = _log[_log.length - 1 - i];
        return Text(
          '${msg.label}:  ${msg.text}',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: msg.sent ? Colors.blue[300] : Colors.green[300],
          ),
        );
      },
    ),
  );

  Widget _buildButtons(ScrollController scroll) => ListView(
    controller: scroll,
    children: [
      _btn('start_ok',   'Nach Spielstart',                  'start_ok'),
      const Divider(color: Colors.white12, height: 20),
      _btn('runde_1_0_2', 'Runde:  ✊ vs ✌️  →  P1 gewinnt', 'runde_1_0_2'),
      _btn('runde_1_1_0', 'Runde:  🖐 vs ✊  →  P1 gewinnt', 'runde_1_1_0'),
      _btn('runde_1_2_1', 'Runde:  ✌️ vs 🖐  →  P1 gewinnt', 'runde_1_2_1'),
      _btn('runde_2_0_2', 'Runde:  ✊ vs ✌️  →  P2 gewinnt', 'runde_2_0_2'),
      _btn('runde_2_0_1', 'Runde:  ✊ vs 🖐  →  P2 gewinnt', 'runde_2_0_1'),
      _btn('runde_1_0_0', 'Runde:  ✊ vs ✊  →  Unentschieden','runde_1_0_0'),
      const Divider(color: Colors.white12, height: 20),
      _btn('mix_ok',     'Mixer fertig',                     'mix_ok'),
    ],
  );

  Widget _btn(String cmd, String label, String message) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: OutlinedButton(
      onPressed: () => _inject(message),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white70,
        side: const BorderSide(color: Colors.white12),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(
            text: '$cmd  ',
            style: const TextStyle(fontFamily: 'monospace', color: Colors.green, fontSize: 12),
          ),
          TextSpan(
            text: label,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ]),
      ),
    ),
  );
}

class _Msg {
  final String label;
  final String text;
  final bool sent;
  const _Msg(this.label, this.text, {required this.sent});
}
