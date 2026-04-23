import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/drink.dart';
import 'mixer_service.dart';

/// Sends mix command to Arduino via WiFi HTTP API.
class WifiMixerService implements MixerService {
  final String baseUrl;
  final Duration timeout;

  WifiMixerService({required this.baseUrl, this.timeout = const Duration(seconds: 12)});

  Uri _uri(String path, [Map<String, String>? query]) {
    final root = Uri.parse(baseUrl);
    return root.replace(path: path, queryParameters: query);
  }

  @override
  Future<void> orderDrink(Drink drink) async {
    final p = drink.pumpAmounts;

    final res = await http
        .get(
          _uri('/api/mix', {
            'a': '${p[0]}',
            'b': '${p[1]}',
            'c': '${p[2]}',
            'd': '${p[3]}',
          }),
        )
        .timeout(timeout);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('HTTP ${res.statusCode} /api/mix: ${res.body}');
    }

    final body = jsonDecode(res.body);
    if (body is! Map<String, dynamic>) throw StateError('Invalid JSON from /api/mix');

    final msg = body['message']?.toString();
    if (msg != 'mix_ok') {
      throw StateError('Expected "mix_ok", got "$msg"');
    }
  }
}
