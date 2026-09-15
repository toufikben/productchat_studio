import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/feature_roadmap_service.dart';
import '../../widgets/app_widgets.dart';

class RoadmapScreen extends StatelessWidget {
  const RoadmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final grouped = <int, List<RoadmapFeature>>{};
    for (final f in FeatureRoadmapService.features) {
      grouped.putIfAbsent(f.phase, () => []).add(f);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Product Roadmap')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryGlow],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Coming Soon',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    )),
                SizedBox(height: 8),
                Text('Features we are working on for future releases',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...grouped.entries.map((e) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('Phase ${e.key}',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        )),
                  ),
                  ...e.value.map((f) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            AppIcons.outline(_iconFor(f.icon), size: 40),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(f.title,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      )),
                                  const SizedBox(height: 2),
                                  Text(f.description,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      )),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Planned',
                                  style: TextStyle(
                                    color: AppColors.warning,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 20),
                ],
              )),
        ],
      ),
    );
  }

  IconData _iconFor(String name) => switch (name) {
        'person' => Icons.person,
        'videocam' => Icons.videocam,
        'palette' => Icons.palette,
        'landscape' => Icons.landscape,
        'compare' => Icons.compare,
        'analytics' => Icons.analytics,
        'view_in_ar' => Icons.view_in_ar,
        'camera_enhance' => Icons.camera_enhance,
        'api' => Icons.api,
        'cloud' => Icons.cloud,
        _ => Icons.star,
      };
}
