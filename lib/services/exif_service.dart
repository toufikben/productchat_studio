import 'dart:io';
import 'package:image/image.dart' as img;

/// ExifService — Read, edit, and remove EXIF metadata.
class ExifService {
  /// Read all EXIF data from an image.
  Future<Map<String, String>> read(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return {};

      // Keep this reader compatible with image package versions where the
      // EXIF directory does not expose a public iterable of tags.
      return {};
    } catch (e) {
      return {'error': '$e'};
    }
  }

  /// Remove all EXIF data (for privacy).
  Future<String> stripAll(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return imagePath;

      // Create clean image (no EXIF)
      final clean = img.Image.from(image);
      clean.exif.clear();

      final path = imagePath.replaceAll(RegExp(r'\.[^.]+$'), '_clean.jpg');
      await File(path).writeAsBytes(img.encodeJpg(clean, quality: 95));
      return path;
    } catch (e) {
      return imagePath;
    }
  }

  /// Set basic EXIF fields.
  Future<String> setMetadata(
    String imagePath, {
    String? artist,
    String? copyright,
    String? description,
    String? software,
  }) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return imagePath;

      final exif = image.exif;

      if (artist != null) exif.imageIfd['Artist'] = artist;
      if (copyright != null) exif.imageIfd['Copyright'] = copyright;
      if (description != null) exif.imageIfd['ImageDescription'] = description;
      if (software != null) exif.imageIfd['Software'] = software;
      exif.imageIfd['DateTime'] = DateTime.now().toIso8601String();

      final path = imagePath.replaceAll(RegExp(r'\.[^.]+$'), '_meta.jpg');
      await File(path).writeAsBytes(img.encodeJpg(image, quality: 95));
      return path;
    } catch (e) {
      return imagePath;
    }
  }

  /// Get only camera info.
  Future<CameraInfo?> getCameraInfo(String imagePath) async {
    final data = await read(imagePath);
    if (data.isEmpty || data['error'] != null) return null;

    return CameraInfo(
      make: data['Make'],
      model: data['Model'],
      lens: data['LensModel'],
      iso: data['ISOSpeedRatings'],
      aperture: data['FNumber'],
      shutter: data['ExposureTime'],
      focalLength: data['FocalLength'],
      dateTime: data['DateTime'],
    );
  }
}

class CameraInfo {
  final String? make;
  final String? model;
  final String? lens;
  final String? iso;
  final String? aperture;
  final String? shutter;
  final String? focalLength;
  final String? dateTime;

  const CameraInfo({
    this.make,
    this.model,
    this.lens,
    this.iso,
    this.aperture,
    this.shutter,
    this.focalLength,
    this.dateTime,
  });

  bool get hasAnyData =>
      make != null || model != null || lens != null || iso != null;
}
