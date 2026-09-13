class StorageService { final Map<String, Object?> _memory = {}; Future<void> set(String key, Object? value) async => _memory[key] = value; Object? get(String key) => _memory[key]; }
