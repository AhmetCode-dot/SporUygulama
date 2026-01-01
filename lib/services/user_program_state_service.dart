import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_program_state.dart';

class UserProgramStateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'user_program_states';

  /// Kullanıcının aktif program durumunu getir
  Future<UserProgramState?> getActiveProgram(String userId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        return UserProgramState.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Program durumu yüklenemedi: ${e.toString()}');
    }
  }

  /// Yeni bir program başlat (veya mevcut programı güncelle)
  Future<void> startProgram({
    required String userId,
    required String programId,
    DateTime? startDate,
  }) async {
    try {
      final state = UserProgramState(
        userId: userId,
        programId: programId,
        startDate: startDate ?? DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(userId)
          .set(state.toMap());
    } catch (e) {
      throw Exception('Program başlatılamadı: ${e.toString()}');
    }
  }

  /// Program durumunu güncelle
  Future<void> updateProgramState(String userId, UserProgramState state) async {
    try {
      final updatedState = UserProgramState(
        userId: state.userId,
        programId: state.programId,
        startDate: state.startDate,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(userId)
          .set(updatedState.toMap());
    } catch (e) {
      throw Exception('Program durumu güncellenemedi: ${e.toString()}');
    }
  }

  /// Programı sonlandır (sil)
  Future<void> endProgram(String userId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(userId)
          .delete();
    } catch (e) {
      throw Exception('Program sonlandırılamadı: ${e.toString()}');
    }
  }
}

