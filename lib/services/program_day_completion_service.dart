import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/program_day_completion.dart';

class ProgramDayCompletionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'program_day_completions';

  /// Bir program gününü tamamlandı olarak işaretle
  Future<void> completeProgramDay({
    required String userId,
    required String programId,
    required int weekIndex,
    required int dayIndex,
    String? workoutSessionId,
  }) async {
    try {
      // Benzersiz ID: userId_programId_weekIndex_dayIndex
      final id = '${userId}_${programId}_${weekIndex}_${dayIndex}';
      
      final completion = ProgramDayCompletion(
        id: id,
        userId: userId,
        programId: programId,
        weekIndex: weekIndex,
        dayIndex: dayIndex,
        completedAt: DateTime.now(),
        workoutSessionId: workoutSessionId,
      );

      await _firestore
          .collection(_collection)
          .doc(id)
          .set(completion.toMap());
    } catch (e) {
      throw Exception('Program günü tamamlanamadı: ${e.toString()}');
    }
  }

  /// Kullanıcının bir program için tamamladığı günleri getir
  Future<List<ProgramDayCompletion>> getCompletionsForProgram({
    required String userId,
    required String programId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('programId', isEqualTo: programId)
          .get();

      return snapshot.docs
          .map((doc) => ProgramDayCompletion.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Tamamlanan günler yüklenemedi: ${e.toString()}');
    }
  }

  /// Belirli bir günün tamamlanıp tamamlanmadığını kontrol et
  Future<bool> isDayCompleted({
    required String userId,
    required String programId,
    required int weekIndex,
    required int dayIndex,
  }) async {
    try {
      final id = '${userId}_${programId}_${weekIndex}_${dayIndex}';
      final doc = await _firestore.collection(_collection).doc(id).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Tüm tamamlanan günleri getir (kullanıcı bazında)
  Future<List<ProgramDayCompletion>> getUserCompletions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => ProgramDayCompletion.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Tamamlanan günler yüklenemedi: ${e.toString()}');
    }
  }
}

