import 'dart:io';
import 'package:image/image.dart' as img;

class ExportVerificationService {
  Future<ExportCheck> verify({required String filePath, int? expectedWidth, int? expectedHeight, required String expectedFormat}) async {
    try {
      final f = File(filePath);
      if (!await f.exists() || await f.length() == 0) return const ExportCheck(false, 'file missing or empty');
      final decoded = img.decodeImage(await f.readAsBytes());
      if (decoded == null) return const ExportCheck(false, 'invalid image');
      if (expectedWidth != null && decoded.width != expectedWidth) return const ExportCheck(false, 'width mismatch');
      if (expectedHeight != null && decoded.height != expectedHeight) return const ExportCheck(false, 'height mismatch');
      final ext = filePath.split('.').last.toLowerCase();
      if (expectedFormat.isNotEmpty && ext != expectedFormat.toLowerCase()) return const ExportCheck(false, 'format mismatch');
      return const ExportCheck(true, null);
    } catch (e) { return ExportCheck(false, '$e'); }
  }
}
class ExportCheck {
  final bool ok; final String? issue;
  const ExportCheck(this.ok, this.issue);
}
