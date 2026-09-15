import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image/image.dart' as img;

class BrandProfile {
  final String? logoPath;
  final String primaryColor;
  final String secondaryColor;
  final String fontFamily;
  final String? tagline;
  final bool showWatermark;

  const BrandProfile({
    this.logoPath,
    this.primaryColor = '#6C5CE7',
    this.secondaryColor = '#00D2A8',
    this.fontFamily = 'Inter',
    this.tagline,
    this.showWatermark = true,
  });

  Map<String, dynamic> toMap() => {
        'logoPath': logoPath,
        'primaryColor': primaryColor,
        'secondaryColor': secondaryColor,
        'fontFamily': fontFamily,
        'tagline': tagline,
        'showWatermark': showWatermark,
      };

  factory BrandProfile.fromMap(Map<String, dynamic> map) => BrandProfile(
        logoPath: map['logoPath'] as String?,
        primaryColor: map['primaryColor'] as String? ?? '#6C5CE7',
        secondaryColor: map['secondaryColor'] as String? ?? '#00D2A8',
        fontFamily: map['fontFamily'] as String? ?? 'Inter',
        tagline: map['tagline'] as String?,
        showWatermark: map['showWatermark'] as bool? ?? true,
      );

  BrandProfile copyWith({
    String? logoPath,
    String? primaryColor,
    String? secondaryColor,
    String? fontFamily,
    String? tagline,
    bool? showWatermark,
    bool clearLogo = false,
  }) =>
      BrandProfile(
        logoPath: clearLogo ? null : (logoPath ?? this.logoPath),
        primaryColor: primaryColor ?? this.primaryColor,
        secondaryColor: secondaryColor ?? this.secondaryColor,
        fontFamily: fontFamily ?? this.fontFamily,
        tagline: tagline ?? this.tagline,
        showWatermark: showWatermark ?? this.showWatermark,
      );
}

class BrandService {
  static const _key = 'brand_profile';

  BrandProfile load() {
    final box = Hive.box<dynamic>('settings');
    final data = box.get(_key);
    if (data == null) return const BrandProfile();
    try {
      return BrandProfile.fromMap(Map<String, dynamic>.from(jsonDecode(data as String)));
    } catch (_) {
      return const BrandProfile();
    }
  }

  Future<void> save(BrandProfile profile) async {
    final box = Hive.box<dynamic>('settings');
    await box.put(_key, jsonEncode(profile.toMap()));
  }

  Future<void> clear() async {
    final box = Hive.box<dynamic>('settings');
    await box.delete(_key);
  }

  /// يطبق الشعار على الصورة في الركن السفلي الأيمن.
  Future<String> applyLogo(String imagePath, BrandProfile profile, {double scale = 0.15}) async {
    if (profile.logoPath == null || !File(profile.logoPath!).existsSync()) {
      return imagePath;
    }
    final imageBytes = await File(imagePath).readAsBytes();
    final logoBytes = await File(profile.logoPath!).readAsBytes();
    final image = img.decodeImage(imageBytes);
    final logo = img.decodeImage(logoBytes);
    if (image == null || logo == null) return imagePath;

    final logoWidth = (image.width * scale).toInt();
    final logoHeight = (logo.height * logoWidth / logo.width).toInt();
    final resizedLogo = img.copyResize(logo, width: logoWidth, height: logoHeight);

    final x = image.width - logoWidth - 24;
    final y = image.height - logoHeight - 24;

    img.compositeImage(image, resizedLogo, dstX: x, dstY: y);

    final outPath = imagePath.replaceAll(RegExp(r'\.[^.]+$'), '_branded.png');
    await File(outPath).writeAsBytes(img.encodePng(image));
    return outPath;
  }
}
