import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Firebase Storage yönetim servisi
/// Görsel ve videoları Firebase Storage'a yükler ve URL'lerini Firestore'a kaydeder
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Egzersiz görseli URL'ini al
  /// Firestore'dan imageUrl alanını kontrol eder, yoksa asset path'i döner
  Future<String> getExerciseImageUrl(String exerciseId, String? fallbackAssetPath) async {
    // Firestore'dan egzersiz verisini çek
    try {
      final exerciseDoc = await _firestore
          .collection('exercises')
          .doc(exerciseId)
          .get();
      
      if (exerciseDoc.exists) {
        final data = exerciseDoc.data();
        if (data != null) {
          // Firestore'da imageUrl varsa onu kullan
          if (data['imageUrl'] != null && 
              data['imageUrl'].toString().isNotEmpty) {
            final url = data['imageUrl'] as String;
            // HTTP URL veya Firebase Storage URL ise direkt kullan
            if (url.startsWith('http') || url.startsWith('gs://')) {
              return url;
            }
          }
        }
      }
    } catch (e) {
      // Hata durumunda fallback kullan
    }
    
    // Firestore'da yoksa veya hata varsa asset path'i kullan
    return fallbackAssetPath ?? 'assets/exercises/default.jpg';
  }

  /// Egzersiz video URL'ini al
  Future<String?> getExerciseVideoUrl(String exerciseId, String? fallbackAssetPath) async {
    // Firestore'dan egzersiz verisini çek
    try {
      final exerciseDoc = await _firestore
          .collection('exercises')
          .doc(exerciseId)
          .get();
      
      if (exerciseDoc.exists) {
        final data = exerciseDoc.data();
        if (data != null) {
          // Firestore'da videoUrl varsa onu kullan
          if (data['videoUrl'] != null && 
              data['videoUrl'].toString().isNotEmpty) {
            final url = data['videoUrl'] as String;
            if (url.startsWith('http') || url.startsWith('gs://')) {
              return url;
            }
          }
          // instructionVideoAsset varsa onu kullan
          if (data['instructionVideoAsset'] != null) {
            final url = data['instructionVideoAsset'] as String;
            if (url.startsWith('http') || url.startsWith('gs://')) {
              return url;
            }
            // Asset path ise olduğu gibi döndür
            return url;
          }
        }
      }
    } catch (e) {
      // Hata durumunda fallback kullan
    }
    
    // Firestore'da yoksa asset path'i kullan
    return fallbackAssetPath;
  }

  /// Görseli Firebase Storage'a yükle ve URL'ini döndür
  /// 
  /// [file]: Yüklenecek dosya (File veya html.File)
  /// [exerciseId]: Egzersiz ID'si
  /// [onProgress]: İlerleme callback'i (0.0 - 1.0 arası)
  /// 
  /// Returns: Firebase Storage download URL
  Future<String> uploadExerciseImage({
    required dynamic file,
    required String exerciseId,
    Function(double)? onProgress,
  }) async {
    try {
      final fileName = 'exercises/images/$exerciseId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(fileName);

      UploadTask uploadTask;
      if (kIsWeb) {
        // Web için - Uint8List (bytes) kullan
        uploadTask = ref.putData(
          file as Uint8List,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        // Mobil için - File path'ten File objesi oluştur
        uploadTask = ref.putFile(
          File(file as String),
          SettableMetadata(contentType: 'image/jpeg'),
        );
      }

      // İlerleme takibi
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      // Yükleme tamamlanana kadar bekle
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Firestore'da URL'yi güncelle
      await _firestore
          .collection('exercises')
          .doc(exerciseId)
          .update({'imageUrl': downloadUrl});

      return downloadUrl;
    } catch (e) {
      throw Exception('Görsel yüklenemedi: $e');
    }
  }

  /// Videoyu Firebase Storage'a yükle ve URL'ini döndür
  /// 
  /// [file]: Yüklenecek dosya (File veya html.File)
  /// [exerciseId]: Egzersiz ID'si
  /// [onProgress]: İlerleme callback'i (0.0 - 1.0 arası)
  /// 
  /// Returns: Firebase Storage download URL
  Future<String> uploadExerciseVideo({
    required dynamic file,
    required String exerciseId,
    Function(double)? onProgress,
  }) async {
    try {
      final fileName = 'exercises/videos/$exerciseId/${DateTime.now().millisecondsSinceEpoch}.mp4';
      final ref = _storage.ref().child(fileName);

      UploadTask uploadTask;
      if (kIsWeb) {
        // Web için - Uint8List (bytes) kullan
        uploadTask = ref.putData(
          file as Uint8List,
          SettableMetadata(contentType: 'video/mp4'),
        );
      } else {
        // Mobil için - File path'ten File objesi oluştur
        uploadTask = ref.putFile(
          File(file as String),
          SettableMetadata(contentType: 'video/mp4'),
        );
      }

      // İlerleme takibi
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      // Yükleme tamamlanana kadar bekle
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Firestore'da URL'yi güncelle
      await _firestore
          .collection('exercises')
          .doc(exerciseId)
          .update({'instructionVideoAsset': downloadUrl});

      return downloadUrl;
    } catch (e) {
      throw Exception('Video yüklenemedi: $e');
    }
  }

  /// Firestore'da egzersiz görsel URL'ini güncelle (manuel URL girişi için)
  Future<void> updateExerciseImageUrl(String exerciseId, String imageUrl) async {
    try {
      await _firestore
          .collection('exercises')
          .doc(exerciseId)
          .update({'imageUrl': imageUrl});
    } catch (e) {
      throw Exception('Görsel URL güncellenemedi: $e');
    }
  }

  /// Firestore'da egzersiz video URL'ini güncelle (manuel URL girişi için)
  Future<void> updateExerciseVideoUrl(String exerciseId, String videoUrl) async {
    try {
      await _firestore
          .collection('exercises')
          .doc(exerciseId)
          .update({'instructionVideoAsset': videoUrl});
    } catch (e) {
      throw Exception('Video URL güncellenemedi: $e');
    }
  }

  /// Firebase Storage'dan görseli sil
  Future<void> deleteExerciseImage(String imageUrl) async {
    try {
      // URL'den storage path'i çıkar
      if (imageUrl.contains('/o/')) {
        final uri = Uri.parse(imageUrl);
        final path = uri.pathSegments[uri.pathSegments.indexOf('o') + 1];
        final decodedPath = Uri.decodeComponent(path);
        final ref = _storage.ref(decodedPath);
        await ref.delete();
      }
    } catch (e) {
      // Silme hatası önemli değil, log'la
      print('Görsel silinemedi: $e');
    }
  }

  /// Firebase Storage'dan videoyu sil
  Future<void> deleteExerciseVideo(String videoUrl) async {
    try {
      // URL'den storage path'i çıkar
      if (videoUrl.contains('/o/')) {
        final uri = Uri.parse(videoUrl);
        final path = uri.pathSegments[uri.pathSegments.indexOf('o') + 1];
        final decodedPath = Uri.decodeComponent(path);
        final ref = _storage.ref(decodedPath);
        await ref.delete();
      }
    } catch (e) {
      // Silme hatası önemli değil, log'la
      print('Video silinemedi: $e');
    }
  }

  /// Kullanıcı profil fotoğrafı URL'ini al (Firestore'dan)
  Future<String?> getProfilePhotoUrl(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('user_profiles')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data?['profilePhotoUrl'] != null) {
          return data!['profilePhotoUrl'] as String;
        }
      }
    } catch (e) {
      // Hata durumunda null döner
    }
    return null;
  }

  /// Kullanıcı profil fotoğrafı URL'ini güncelle (Firestore'da)
  Future<void> updateProfilePhotoUrl(String userId, String photoUrl) async {
    try {
      await _firestore
          .collection('user_profiles')
          .doc(userId)
          .update({'profilePhotoUrl': photoUrl});
    } catch (e) {
      throw Exception('Profil fotoğrafı URL güncellenemedi: $e');
    }
  }
}
