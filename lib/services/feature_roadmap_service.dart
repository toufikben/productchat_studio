/// FeatureRoadmapService — يوثق الميزات المستقبلية ويظهر حالتها.
class FeatureRoadmapService {
  static const features = <RoadmapFeature>[
    RoadmapFeature(
      id: 'virtual_models',
      title: 'AI Virtual Models',
      description: 'Replace mannequin with AI-generated human model',
      phase: 4,
      status: 'planned',
      icon: 'person',
    ),
    RoadmapFeature(
      id: 'image_to_video',
      title: 'Image to Video',
      description: 'Turn product photo into 5-second video',
      phase: 4,
      status: 'planned',
      icon: 'videocam',
    ),
    RoadmapFeature(
      id: 'color_change',
      title: 'Product Color Change',
      description: 'Change product colors without re-shooting',
      phase: 4,
      status: 'planned',
      icon: 'palette',
    ),
    RoadmapFeature(
      id: 'lifestyle_scenes',
      title: 'Lifestyle Scenes',
      description: 'Place product on wooden table, marble, etc.',
      phase: 4,
      status: 'planned',
      icon: 'landscape',
    ),
    RoadmapFeature(
      id: 'ab_testing',
      title: 'A/B Testing',
      description: 'Compare two images to find the best',
      phase: 4,
      status: 'planned',
      icon: 'compare',
    ),
    RoadmapFeature(
      id: 'competitor_analysis',
      title: 'Competitor Analysis',
      description: 'See how your images compare to competitors',
      phase: 4,
      status: 'planned',
      icon: 'analytics',
    ),
    RoadmapFeature(
      id: '3d_visualization',
      title: '3D Product Visualization',
      description: 'Convert photo to 3D model',
      phase: 5,
      status: 'planned',
      icon: 'view_in_ar',
    ),
    RoadmapFeature(
      id: 'ar_preview',
      title: 'AR Preview',
      description: 'Preview product in real space',
      phase: 5,
      status: 'planned',
      icon: 'camera_enhance',
    ),
    RoadmapFeature(
      id: 'b2b_api',
      title: 'B2B API',
      description: 'Connect with Shopify/WooCommerce',
      phase: 5,
      status: 'planned',
      icon: 'api',
    ),
    RoadmapFeature(
      id: 'cloud_sync',
      title: 'Cloud Sync',
      description: 'Sync between devices',
      phase: 5,
      status: 'planned',
      icon: 'cloud',
    ),
  ];
}

class RoadmapFeature {
  final String id;
  final String title;
  final String description;
  final int phase;
  final String status; // planned, in_progress, done
  final String icon;

  const RoadmapFeature({
    required this.id,
    required this.title,
    required this.description,
    required this.phase,
    required this.status,
    required this.icon,
  });
}
