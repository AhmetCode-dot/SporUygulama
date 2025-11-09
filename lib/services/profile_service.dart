import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'user_profiles';

  // Profil bilgilerini kaydet
  Future<void> saveProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(profile.userId)
          .set(profile.toMap(), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      // Provide detailed Firestore error context
      final code = e.code;
      final message = e.message ?? 'FirebaseException';
      final details = e.stackTrace?.toString().split('\n').firstOrNull ?? '';
      throw Exception('Profil kaydedilemedi (code: $code): $message $details');
    } catch (e) {
      throw Exception('Profil kaydedilirken beklenmeyen hata: ${e.toString()}');
    }
  }

  // Profil bilgilerini getir
  Future<UserProfile?> getProfile(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!);
      }
      return null;
    } on FirebaseException catch (e) {
      final code = e.code;
      final message = e.message ?? 'FirebaseException';
      throw Exception('Profil alınamadı (code: $code): $message');
    } catch (e) {
      throw Exception('Profil bilgileri alınırken beklenmeyen hata: ${e.toString()}');
    }
  }

  // BMI hesapla
  double calculateBMI(double height, double weight) {
    return weight / (height * height);
  }
} 