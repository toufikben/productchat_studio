import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../../widgets/app_widgets.dart';

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<String>>(
  (_) => FavoritesNotifier());

class FavoritesNotifier extends StateNotifier<List<String>> {
  FavoritesNotifier() : super([]) { _load(); }

  void _load() {
    final box = Hive.box('favorites');
    state = box.values.cast<String>().toList();
  }

  Future<void> add(String imagePath) async {
    await Hive.box('favorites').add(imagePath);
    _load();
  }

  Future<void> remove(String imagePath) async {
    final box = Hive.box('favorites');
    final keys = box.keys.where((k) => box.get(k) == imagePath).toList();
    for (final k in keys) await box.delete(k);
    _load();
  }
}

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favorites.isEmpty
          ? const EmptyState(
              icon: Icons.favorite_border,
              title: 'No favorites yet',
              subtitle: 'Tap the heart icon to save your best images',
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: favorites.length,
              itemBuilder: (_, i) {
                final path = favorites[i];
                return GestureDetector(
                  onLongPress: () {
                    ref.read(favoritesProvider.notifier).remove(path);
                  },
                  onTap: () {
                    Share.shareXFiles([XFile(path)]);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: File(path).existsSync()
                        ? Image.file(File(path), fit: BoxFit.cover)
                        : Container(color: AppColors.surfaceAlt),
                  ),
                );
              },
            ),
    );
  }
}
