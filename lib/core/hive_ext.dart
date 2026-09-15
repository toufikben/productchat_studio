import 'package:hive_flutter/hive_flutter.dart';

/// Safe typed access helpers for values stored in Hive boxes.
extension HiveExt on Box<dynamic> {
  Map<String, dynamic> getMap(dynamic key) {
    final raw = get(key);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> getMapList() {
    return values
        .where((value) => value is Map)
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList();
  }

  String getString(dynamic key, [String def = '']) =>
      get(key) as String? ?? def;

  int getInt(dynamic key, [int def = 0]) => get(key) as int? ?? def;

  double getDouble(dynamic key, [double def = 0.0]) =>
      (get(key) as num?)?.toDouble() ?? def;

  bool getBool(dynamic key, [bool def = false]) =>
      get(key) as bool? ?? def;

  List<String> getStringList(dynamic key) {
    final raw = get(key);
    if (raw is List) return raw.map((value) => value.toString()).toList();
    return <String>[];
  }
}
