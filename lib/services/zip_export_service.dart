import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

/// ZipExportService — Package multiple images into a ZIP archive.
class ZipExportService {
  /// Create a ZIP from a list of image paths.
  Future<File> createZip(
    List<String> imagePaths, {
    String? zipName,
    Function(double progress)? onProgress,
  }) async {
    final archive = Archive();
    var added = 0;

    for (final path in imagePaths) {
      final file = File(path);
      if (!await file.exists()) continue;

      final bytes = await file.readAsBytes();
      final name = path.split('/').last;
      final archiveFile = ArchiveFile(name, bytes.length, bytes);
      archive.addFile(archiveFile);

      added++;
      onProgress?.call(added / imagePaths.length);
    }

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) throw Exception('Failed to create ZIP');

    final dir = await getApplicationDocumentsDirectory();
    final zipName_ = zipName ?? 'productchat_${DateTime.now().millisecondsSinceEpoch}.zip';
    final zipPath = '${dir.path}/$zipName_';
    final zipFile = File(zipPath);
    await zipFile.writeAsBytes(zipBytes);

    return zipFile;
  }

  /// Batch rename files with pattern.
  Future<List<String>> batchRename(
    List<String> paths, {
    required String pattern,
    required int startFrom,
    int padLength = 3,
  }) async {
    final results = <String>[];
    for (var i = 0; i < paths.length; i++) {
      final source = File(paths[i]);
      if (!await source.exists()) continue;

      final number = (startFrom + i).toString().padLeft(padLength, '0');
      final ext = paths[i].split('.').last;
      final newName = '${pattern}_$number.$ext';

      final dir = source.parent.path;
      final newPath = '$dir/$newName';

      await source.rename(newPath);
      results.add(newPath);
    }
    return results;
  }
}
