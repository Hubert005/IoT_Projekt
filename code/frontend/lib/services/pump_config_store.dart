import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PumpConfig {
  final String drinkName;
  final int amountMl;

  const PumpConfig({required this.drinkName, required this.amountMl});

  const PumpConfig.empty()
      : drinkName = '',
        amountMl = 0;

  PumpConfig copyWith({String? drinkName, int? amountMl}) => PumpConfig(
        drinkName: drinkName ?? this.drinkName,
        amountMl: amountMl ?? this.amountMl,
      );

  Map<String, dynamic> toJson() => {
        'drinkName': drinkName,
        'amountMl': amountMl,
      };

  factory PumpConfig.fromJson(Map<String, dynamic> json) => PumpConfig(
        drinkName: (json['drinkName'] as String?) ?? '',
        amountMl: (json['amountMl'] as num?)?.toInt() ?? 0,
      );

  bool get isConfigured => drinkName.trim().isNotEmpty && amountMl > 0;
}

/// Persistent store for the mapping pump-index → drink/ingredient.
///
/// The hardware has 4 pumps (a, b, c, d). This store is a singleton so any
/// other class (e.g. the AI drink-selection service) can read the current
/// configuration synchronously after [load] has been called once at startup.
class PumpConfigStore extends ChangeNotifier {
  static const int pumpCount = 4;
  static const String _prefsKey = 'pump_config_v1';

  PumpConfigStore._();
  static final PumpConfigStore instance = PumpConfigStore._();

  List<PumpConfig> _configs =
      List<PumpConfig>.filled(pumpCount, const PumpConfig.empty());
  bool _loaded = false;

  List<PumpConfig> get configs => List.unmodifiable(_configs);
  bool get isLoaded => _loaded;

  PumpConfig pump(int index) => _configs[index];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List)
            .cast<Map<String, dynamic>>()
            .map(PumpConfig.fromJson)
            .toList();
        if (list.length == pumpCount) {
          _configs = list;
        }
      } catch (_) {
        // ignore corrupt data, keep defaults
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> save(List<PumpConfig> next) async {
    assert(next.length == pumpCount);
    _configs = List<PumpConfig>.from(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(_configs.map((c) => c.toJson()).toList()),
    );
    notifyListeners();
  }

  /// Convenience for the AI: a compact map of available pump ingredients.
  /// Only configured pumps are included.
  Map<String, Map<String, dynamic>> availableForAi() {
    final result = <String, Map<String, dynamic>>{};
    for (var i = 0; i < _configs.length; i++) {
      final c = _configs[i];
      if (c.isConfigured) {
        result['pump${i + 1}'] = c.toJson();
      }
    }
    return result;
  }
}
