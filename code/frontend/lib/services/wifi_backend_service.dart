import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:iot_drink_mixer/models/gesture.dart';

import '../models/round_result.dart';
import 'backend_service.dart';

Gesture _parseGesture(int value) => switch (value) {
  0 => Gesture.rock,
  1 => Gesture.paper,
  _ => Gesture.scissors,
};

/// Communicates with the Arduino HTTP backend.
class WifiBackendService implements BackendService {
  final String baseUrl;
  final Duration timeout;

  WifiBackendService({required this.baseUrl, this.timeout = const Duration(seconds: 8)});

  Uri _uri(String path, [Map<String, String>? query]) {
    final root = Uri.parse(baseUrl);
    return root.replace(path: path, queryParameters: query);
  }

  Future<Map<String, dynamic>> _getJson(String path, [Map<String, String>? query]) async {
    final res = await http.get(_uri(path, query)).timeout(timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('HTTP ${res.statusCode} for $path: ${res.body}');
    }
    final body = jsonDecode(res.body);
    if (body is! Map<String, dynamic>) throw StateError('Invalid JSON from $path');
    return body;
  }

  Future<void> _expectMessage(String path, String expected, [Map<String, String>? query]) async {
    final json = await _getJson(path, query);
    final msg = json['message']?.toString();
    if (msg != expected) {
      throw StateError('Expected "$expected" from $path, got "$msg"');
    }
  }

  @override
  Future<void> startGame() async {
    await _expectMessage('/api/start', 'start_ok');
  }

  @override
  Future<RoundResult> getRoundResult(int round) async {
    final json = await _getJson('/api/nextRound', {'round': '$round'});
    final msg = json['message']?.toString() ?? '';
    if (!msg.startsWith('runde_')) {
      throw StateError('Expected round message, got "$msg"');
    }

    final parts = msg.split('_');
    if (parts.length != 4) {
      throw StateError('Invalid round message: "$msg"');
    }

    final p1 = _parseGesture(int.parse(parts[2]));
    final p2 = _parseGesture(int.parse(parts[3]));

    await _expectMessage('/api/rundeOk', 'runde_ok');
    return RoundResult(round: round, p1: p1, p2: p2);
  }
}
