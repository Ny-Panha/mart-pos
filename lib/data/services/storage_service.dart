import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();
  static const Uuid _uuid = Uuid();

  /// Pick an image file from the device's gallery / file explorer.
  /// Works across Flutter Web, Android, iOS, Windows, macOS, and Linux.
  static Future<XFile?> pickProductImage() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      return file;
    } catch (e) {
      return null;
    }
  }

  /// Uploads an image [XFile] to Firebase Storage under `products/` folder
  /// and returns its public HTTPS download URL.
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

    final Reference ref = _storage.ref().child('products/$fileName');

    final UploadTask uploadTask = ref.putData(
      bytes,
      SettableMetadata(
        contentType: mimeType,
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalName': file.name,
        },
      ),
    );

    final TaskSnapshot snapshot = await uploadTask;
    final String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  /// Uploads raw [Uint8List] bytes directly to Firebase Storage.
  static Future<String> uploadProductImageBytes({
    required Uint8List bytes,
    String extension = 'jpg',
  }) async {
    final String mimeType = _resolveMimeType(extension);
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}.$extension';

    final Reference ref = _storage.ref().child('products/$fileName');
    final UploadTask uploadTask = ref.putData(
      bytes,
      SettableMetadata(contentType: mimeType),
    );

    final TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
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
