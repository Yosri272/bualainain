import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageStorageService {
  ImageStorageService._();

  static final ImagePicker _picker = ImagePicker();
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<XFile?> pickImageFromGallery() async {
    return _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
      requestFullMetadata: false,
    );
  }

  static String _getExtension(XFile image) {
    final String fileName = image.name.toLowerCase();

    if (fileName.endsWith('.png')) {
      return 'png';
    }

    if (fileName.endsWith('.webp')) {
      return 'webp';
    }

    if (fileName.endsWith('.heic')) {
      return 'heic';
    }

    return 'jpg';
  }

  static String _getContentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  static Future<String> _uploadImage({
    required XFile image,
    required String directoryPath,
    required String fileName,
  }) async {
    final String extension = _getExtension(image);

    final String storagePath =
        '$directoryPath/$fileName.$extension';

    final Reference reference =
    _storage.ref().child(storagePath);

    final SettableMetadata metadata = SettableMetadata(
      contentType: _getContentType(extension),
    );

    final UploadTask uploadTask = reference.putFile(
      File(image.path),
      metadata,
    );

    final TaskSnapshot snapshot = await uploadTask;

    return snapshot.ref.getDownloadURL();
  }

  static Future<String> uploadProfileImage({
    required XFile image,
  }) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        code: 'not-authenticated',
        message: 'يجب تسجيل الدخول أولاً',
      );
    }

    return _uploadImage(
      image: image,
      directoryPath: 'profile_images/${user.uid}',
      fileName: 'profile',
    );
  }

  static Future<String> uploadCategoryImage({
    required XFile image,
    required String categoryId,
  }) {
    return _uploadImage(
      image: image,
      directoryPath: 'categories/$categoryId',
      fileName: 'image',
    );
  }

  static Future<String> uploadNewsImage({
    required XFile image,
    required String newsId,
  }) {
    return _uploadImage(
      image: image,
      directoryPath: 'news/$newsId',
      fileName: 'image',
    );
  }

  static Future<void> deleteImageFromUrl(
      String imageUrl,
      ) async {
    if (imageUrl.trim().isEmpty) return;

    await _storage.refFromURL(imageUrl).delete();
  }
}