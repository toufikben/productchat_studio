import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Small durable key/value store for app settings and lightweight metadata.
/// Binary model/image files remain in application support/cache directories.
class StorageService {
  SharedPreferences? _preferences;
  final Map<String, Object?> _memory = {};

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  Future<void> set(String key, Object? value) async {
    _memory[key] = value;
    final prefs = _preferences;
    if (prefs == null) return;
    if (value == null) {
      await prefs.remove(key);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    } else {
      await prefs.setString(key, jsonEncode(value));
    }
  }

  Object? get(String key) => _preferences?.get(key) ?? _memory[key];

  String? getString(String key) => _preferences?.getString(key) ?? _memory[key] as String?;

  Future<void> remove(String key) async {
    _memory.remove(key);
    await _preferences?.remove(key);
  }
}

final storageService = StorageService();
