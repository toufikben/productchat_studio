class PlatformSpec {
  final String name;
  final int minSize;
  final int recommendedSize;
  final bool squareOnly;
  final String bgHex;
  final String format;

  const PlatformSpec(
    this.name,
    this.minSize, {
    int? recommendedSize,
    this.squareOnly = false,
    this.bgHex = '#FFFFFF',
    this.format = 'jpg',
  }) : recommendedSize = recommendedSize ?? minSize;
}
