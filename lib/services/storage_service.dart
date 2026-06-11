import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<String> uploadImage(File file, String folder) async {
    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage.ref().child(folder).child(fileName);
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> uploadXFile(XFile xfile, String folder) async {
    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage.ref().child(folder).child(fileName);
    
    if (kIsWeb) {
      final bytes = await xfile.readAsBytes();
      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await uploadTask.ref.getDownloadURL();
    } else {
      final file = File(xfile.path);
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    }
  }

  Future<void> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // Ignore or log errors if image not found
    }
  }
}
