import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Service for compressing images and converting them to Base64 strings
class ImageCompressionService {
  static final ImageCompressionService _instance =
      ImageCompressionService._internal();

  factory ImageCompressionService() {
    return _instance;
  }

  ImageCompressionService._internal();

  /// Maximum allowed file size in bytes (800KB to ensure Firestore document limit)
  static const int maxFileSizeBytes = 800 * 1024; // 800 KB

  /// Compress image and convert to Base64 string
  /// Returns the Base64 encoded string of the compressed image
  /// Automatically reduces quality if needed to stay under 800KB
  Future<String> compressImageToBase64({
    required String imagePath,
    int initialQuality = 90,
  }) async {
    try {
      // Read the original file
      final File originalFile = File(imagePath);
      if (!await originalFile.exists()) {
        throw Exception('Image file does not exist: $imagePath');
      }

      // Get the file extension
      final String extension = imagePath.split('.').last.toLowerCase();

      // Compress the image
      final List<int>? compressedBytes =
          await FlutterImageCompress.compressWithFile(
            imagePath,
            quality: initialQuality,
            format: _getCompressFormat(extension),
          );

      if (compressedBytes == null || compressedBytes.isEmpty) {
        throw Exception('Failed to compress image');
      }

      // Check size and re-compress if needed
      int currentQuality = initialQuality;
      List<int> finalBytes = compressedBytes;

      while (finalBytes.length > maxFileSizeBytes && currentQuality > 10) {
        currentQuality -= 10;
        final List<int>? recompressed =
            await FlutterImageCompress.compressWithFile(
              imagePath,
              quality: currentQuality,
              format: _getCompressFormat(extension),
            );

        if (recompressed != null && recompressed.isNotEmpty) {
          finalBytes = recompressed;
        } else {
          break;
        }
      }

      // Final size check
      if (finalBytes.length > maxFileSizeBytes) {
        throw Exception(
          'Image is too large even after compression. '
          'Final size: ${(finalBytes.length / 1024).toStringAsFixed(2)}KB, '
          'max allowed: ${(maxFileSizeBytes / 1024).toStringAsFixed(2)}KB',
        );
      }

      // Convert to Base64
      final String base64String = base64Encode(finalBytes);
      return base64String;
    } catch (e) {
      throw Exception('Failed to compress image to Base64: ${e.toString()}');
    }
  }

  /// Get the appropriate CompressFormat based on file extension
  CompressFormat _getCompressFormat(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return CompressFormat.jpeg;
      case 'png':
        return CompressFormat.png;
      case 'webp':
        return CompressFormat.webp;
      default:
        return CompressFormat.jpeg;
    }
  }

  /// Convert Base64 string to bytes (for displaying in Image.memory widget)
  List<int> decodeBase64ToBytes(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      throw Exception('Failed to decode Base64 string: ${e.toString()}');
    }
  }

  /// Get the size of a Base64 encoded string in KB
  double getBase64SizeInKB(String base64String) {
    return base64String.length / 1024;
  }
}
