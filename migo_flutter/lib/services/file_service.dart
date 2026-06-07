import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class FileService {
  final SupabaseService _supabaseService;

  FileService(this._supabaseService);

  final ImagePicker _imagePicker = ImagePicker();

  // =========================================================================
  // Upload
  // =========================================================================

  /// Upload a file to a Supabase Storage bucket.
  /// Returns the storage path of the uploaded file.
  Future<String> uploadFile({
    required String filePath,
    required String bucket,
    required String path,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      final fileBytes = await file.readAsBytes();
      final fileName = path.split('/').last;
      final extension = fileName.contains('.') ? fileName.split('.').last : '';
      final contentType = _contentTypeFor(extension);

      await _supabaseService.client.storage.from(bucket).uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );

      return path;
    } catch (e) {
      rethrow;
    }
  }

  // =========================================================================
  // Download
  // =========================================================================

  /// Download a file from a URL and save it to [savePath].
  /// If [savePath] is not provided, it will be saved to the app's temporary
  /// directory with a generated name.
  Future<String> downloadFile({
    required String url,
    String? savePath,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final fileName = url.split('/').last.split('?').first;
      final targetPath = savePath ?? '${dir.path}/$fileName';

      await Dio().download(url, targetPath);
      return targetPath;
    } catch (e) {
      rethrow;
    }
  }

  // =========================================================================
  // Delete
  // =========================================================================

  /// Delete a file from a Supabase Storage bucket.
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await _supabaseService.client.storage.from(bucket).remove([path]);
    } catch (e) {
      rethrow;
    }
  }

  // =========================================================================
  // Public URL
  // =========================================================================

  /// Get the public URL for a file in a Supabase Storage bucket.
  String getPublicUrl({
    required String bucket,
    required String path,
  }) {
    return _supabaseService.client.storage
        .from(bucket)
        .getPublicUrl(path);
  }

  // =========================================================================
  // File Pickers
  // =========================================================================

  /// Open a file picker and return the selected file, or null if cancelled.
  Future<File?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Open an image picker (camera or gallery) and return the selected image.
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final xFile = await _imagePicker.pickImage(source: source);
      if (xFile != null) {
        return File(xFile.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // =========================================================================
  // Private Helpers
  // =========================================================================

  String _contentTypeFor(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod Providers
// ---------------------------------------------------------------------------

final fileServiceProvider = Provider<FileService>((ref) {
  return FileService(ref.watch(supabaseServiceProvider));
});
