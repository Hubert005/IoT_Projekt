import 'dart:convert';

import '../models/generated_cocktail.dart';
import '../models/mood_tags.dart';
import '../models/pump_setup.dart';

const int kMaxPerPump = 80;
const int kMinPerPump = 20;
const int kMaxTotal = 250;
const int kMaxCocktails = 6;
const String kRecipeSystemInstruction =
    'Du bist ein kreativer Barkeeper für einen automatischen Cocktail-Mixer mit '
    'genau vier Pumpen. Du darfst ausschließlich die vier angegebenen Zutaten '
    'verwenden. Antworte IMMER nur mit gültigem JSON, ohne Erklärtext, ohne '
    'Markdown-Codeblöcke.';

String buildRecipePrompt(PumpSetup setup) {
  final pumps = <String>[];
  for (var i = 0; i < setup.drinks.length; i++) {
    final name = setup.drinks[i].trim();
    pumps.add('Pumpe ${i + 1} = "${name.isEmpty ? 'leer' : name}"');
  }

  return '''
Erzeuge 4 bis 6 verschiedene Cocktails, die sich aus diesen vier Pumpen mischen lassen:
${pumps.join('\n')}

Regeln:
- Gib NUR ein JSON-Array zurück, kein weiterer Text.
- Jedes Objekt hat die Felder: "name" (String, muss mindestens eine der Zutaten enthalten),
  "description" (kurzer deutscher Satz), "tags" (Array aus dieser Liste: ${kMoodTags.join(', ')}),
  "pumpAmounts" (Array aus genau 4 ganzen Zahlen, Reihenfolge = Pumpe 1..4, Einheit ml),
  "refinementTip" (kurzer deutscher Tipp zum Verfeinern).
- Jede Zahl in "pumpAmounts" liegt zwischen 0 und $kMaxPerPump; mindestens zwei Pumpen
  haben einen Wert > 0; die Summe ist höchstens $kMaxTotal.

Beispiel:
[{"name":"Wilder Mango Smash","description":"Ein fruchtiger Mix aus Mango und Limette.","tags":["happy","fresh"],"pumpAmounts":[60,40,0,30],"refinementTip":"Mit Eis auffüllen."}]
''';
}

List<GeneratedCocktail> parseGemmaCocktails(String rawText, PumpSetup setup) {
  final decoded = jsonDecode(_extractJson(rawText));
  final List<dynamic> items;
  if (decoded is List) {
    items = decoded;
  } else if (decoded is Map && decoded['cocktails'] is List) {
    items = decoded['cocktails'] as List;
  } else {
    throw const FormatException('expected a JSON array of cocktails');
  }
  return sanitizeCocktails(items, setup);
}

List<GeneratedCocktail> sanitizeCocktails(List<dynamic> items, PumpSetup setup) {
  final names = setup.drinks.map((d) => d.trim()).toList();
  final out = <GeneratedCocktail>[];
  for (var i = 0; i < items.length && out.length < kMaxCocktails; i++) {
    final item = items[i];
    if (item is! Map) continue;
    final map = item.cast<String, dynamic>();
    final amounts = _sanitizeAmounts(map['pumpAmounts']);
    out.add(GeneratedCocktail(
      id: 'gen_${i}_${_seedFor(names)}',
      name: _sanitizeName(map['name'], names, amounts),
      description: _cleanString(map['description']) ??
          'Ein Mix aus ${_usedNames(amounts, names).join(', ')}.',
      tags: _sanitizeTags(map['tags']),
      pumpAmounts: amounts,
      refinementTip: _cleanString(map['refinementTip']) ?? 'Auf Eis servieren.',
    ));
  }
  return out;
}

String _extractJson(String text) {
  final arrStart = text.indexOf('[');
  final arrEnd = text.lastIndexOf(']');
  if (arrStart != -1 && arrEnd > arrStart) {
    return text.substring(arrStart, arrEnd + 1);
  }
  final objStart = text.indexOf('{');
  final objEnd = text.lastIndexOf('}');
  if (objStart != -1 && objEnd > objStart) {
    return text.substring(objStart, objEnd + 1);
  }
  throw const FormatException('no JSON structure found in model output');
}

List<int> _sanitizeAmounts(dynamic raw) {
  final amounts = List<int>.filled(4, 0);
  if (raw is List) {
    for (var i = 0; i < 4 && i < raw.length; i++) {
      final v = raw[i];
      final n = v is num ? v.toInt() : int.tryParse('$v') ?? 0;
      amounts[i] = n.clamp(0, kMaxPerPump);
    }
  }

  var used = amounts.where((a) => a > 0).length;
  for (var i = 0; i < 4 && used < 2; i++) {
    if (amounts[i] == 0) {
      amounts[i] = kMinPerPump;
      used++;
    }
  }

  final total = amounts.fold(0, (s, v) => s + v);
  if (total > kMaxTotal) {
    final scale = kMaxTotal / total;
    for (var i = 0; i < amounts.length; i++) {
      if (amounts[i] > 0) amounts[i] = (amounts[i] * scale).floor();
    }
  }
  return amounts;
}

String _sanitizeName(dynamic raw, List<String> names, List<int> amounts) {
  final clean = _cleanString(raw) ?? '';
  final mentions = names.any(
    (n) => n.isNotEmpty && clean.toLowerCase().contains(n.toLowerCase()),
  );
  if (clean.isNotEmpty && mentions) return clean;

  final hero = _heroPump(amounts);
  final heroName = names[hero].isEmpty ? 'Pumpe ${hero + 1}' : names[hero];
  return clean.isEmpty ? '$heroName Cocktail' : '$heroName $clean';
}

List<String> _sanitizeTags(dynamic raw) {
  final out = <String>[];
  if (raw is List) {
    for (final t in raw) {
      final s = '$t'.trim().toLowerCase();
      if (kMoodTags.contains(s) && !out.contains(s)) out.add(s);
    }
  }
  if (out.isEmpty) out.add('classic');
  return out;
}

List<String> _usedNames(List<int> amounts, List<String> names) {
  final used = <String>[];
  for (var i = 0; i < amounts.length; i++) {
    if (amounts[i] > 0) used.add(names[i].isEmpty ? 'Pumpe ${i + 1}' : names[i]);
  }
  return used;
}

int _heroPump(List<int> amounts) {
  var hero = 0;
  for (var i = 1; i < amounts.length; i++) {
    if (amounts[i] > amounts[hero]) hero = i;
  }
  return hero;
}

String? _cleanString(dynamic raw) {
  if (raw == null) return null;
  final s = '$raw'.trim();
  return s.isEmpty ? null : s;
}

int _seedFor(List<String> names) {
  var seed = 7;
  for (final code in names.join('|').toLowerCase().codeUnits) {
    seed = (seed * 31 + code) & 0x7fffffff;
  }
  return seed;
}

enum GemmaModelPhase { idle, downloading, loading, ready, unavailable }

class GemmaModelStatus {
  final GemmaModelPhase phase;
  final int downloadPercent;
  final String? error;

  const GemmaModelStatus._(this.phase, this.downloadPercent, this.error);

  const GemmaModelStatus.idle() : this._(GemmaModelPhase.idle, 0, null);
  const GemmaModelStatus.downloading(int percent)
      : this._(GemmaModelPhase.downloading, percent, null);
  const GemmaModelStatus.loading() : this._(GemmaModelPhase.loading, 0, null);
  const GemmaModelStatus.ready() : this._(GemmaModelPhase.ready, 100, null);
  const GemmaModelStatus.unavailable(String error)
      : this._(GemmaModelPhase.unavailable, 0, error);
}
