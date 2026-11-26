import 'dart:async';
import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();
  static const Uuid _uuid = Uuid();
  static const Duration _uploadTimeout = Duration(seconds: 6);

  /// Pick an image file from the device's gallery / file explorer.
  /// Works across Flutter Web, Android, iOS, Windows, macOS, and Linux.
  static Future<XFile?> pickProductImage() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 70,
      );
      return file;
    } catch (e) {
      return null;
    }
  }

  /// Uploads an image [XFile] to Firebase Storage under `products/` folder
  /// and returns its public HTTPS download URL, or falls back to a base64
  /// data URI if Firebase Storage does not respond within [_uploadTimeout].
  static Future<String> uploadProductImage({
    required XFile file,
    String? customName,
  }) async {
    final Uint8List bytes = await file.readAsBytes();
    final String extension = _resolveExtension(file.name);
    final String mimeType = _resolveMimeType(extension);

    final String fileName = customName != null && customName.isNotEmpty
        ? '$customName.$extension'
        : '${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}.$extension';

    return _uploadBytesWithFallback(
      bytes,
      fileName: fileName,
      mimeType: mimeType,
      customMetadata: {
        'uploadedAt': DateTime.now().toIso8601String(),
        'originalName': file.name,
      },
    );
  }

  /// Uploads raw [Uint8List] bytes directly to Firebase Storage, falling back
  /// to a base64 data URI if Firebase Storage is unavailable or times out.
  static Future<String> uploadProductImageBytes({
    required Uint8List bytes,
    String extension = 'jpg',
  }) async {
    final String mimeType = _resolveMimeType(extension);
    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}.$extension';

    return _uploadBytesWithFallback(
      bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  static Future<String> _uploadBytesWithFallback(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
    Map<String, String>? customMetadata,
  }) async {
    UploadTask? uploadTask;
    try {
      final Reference ref = _storage.ref().child('products/$fileName');
      uploadTask = ref.putData(
        bytes,
        SettableMetadata(
          contentType: mimeType,
          customMetadata: customMetadata,
        ),
      );

      final TaskSnapshot snapshot = await uploadTask.timeout(_uploadTimeout);
      return await snapshot.ref.getDownloadURL().timeout(_uploadTimeout);
    } catch (e) {
      unawaited(uploadTask?.cancel().catchError((_) => false));
      debugPrint('Firebase Storage upload fallback to base64 data URI: $e');
      return 'data:$mimeType;base64,${base64Encode(bytes)}';
    }
  }

  static String _resolveExtension(String filename) {
    final parts = filename.split('.');
    if (parts.length > 1) {
      final ext = parts.last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) {
        return ext == 'jpeg' ? 'jpg' : ext;
      }
    }
    return 'jpg';
  }

  static String _resolveMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
