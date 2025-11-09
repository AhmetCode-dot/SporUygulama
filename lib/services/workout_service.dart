import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_session.dart';

class WorkoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'workout_sessions';

  // Antrenman kaydet
  Future<void> saveWorkoutSession(WorkoutSession session) async {
    try {
      final data = session.toMap();
      await _firestore
          .collection(_collection)
          .doc(session.id)
          .set(data);
    } on FirebaseException catch (e) {
      throw Exception('Antrenman kaydedilemedi (Firebase): ${e.code} - ${e.message}');
    } catch (e, stackTrace) {
      throw Exception('Antrenman kaydedilemedi: ${e.toString()}\nStack: ${stackTrace.toString()}');
    }
  }

  // Kullanıcının tüm antrenmanlarını getir
  Future<List<WorkoutSession>> getUserWorkouts(String userId) async {
    try {
      // Index gerektirmemek için orderBy kullanmadan çekip memory'de sıralıyoruz
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      final workouts = snapshot.docs
          .map((doc) => WorkoutSession.fromMap(doc.data()))
          .toList();
      
      // Tarihe göre sırala (en yeni önce)
      workouts.sort((a, b) => b.date.compareTo(a.date));
      
      return workouts;
    } catch (e) {
      throw Exception('Antrenmanlar yüklenemedi: ${e.toString()}');
    }
  }

  // Son N günün antrenmanlarını getir
  Future<List<WorkoutSession>> getRecentWorkouts(String userId, int days) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      // Index gerektirmemek için orderBy kullanmadan çekip memory'de filtreliyoruz
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      final allWorkouts = snapshot.docs
          .map((doc) => WorkoutSession.fromMap(doc.data()))
          .toList();
      
      // Tarihe göre filtrele ve sırala
      final recentWorkouts = allWorkouts
          .where((workout) => workout.date.isAfter(cutoffDate))
          .toList();
      
      recentWorkouts.sort((a, b) => b.date.compareTo(a.date));
      
      return recentWorkouts;
    } catch (e) {
      throw Exception('Son antrenmanlar yüklenemedi: ${e.toString()}');
    }
  }

  // Streak hesapla (kaç gün üst üste antrenman yapılmış)
  Future<int> calculateStreak(String userId) async {
    try {
      final workouts = await getUserWorkouts(userId);
      if (workouts.isEmpty) return 0;

      // Tarihleri sırala (en yeni önce)
      workouts.sort((a, b) => b.date.compareTo(a.date));

      int streak = 0;
      DateTime? lastWorkoutDate;

      for (final workout in workouts) {
        final workoutDate = DateTime(
          workout.date.year,
          workout.date.month,
          workout.date.day,
        );

        if (lastWorkoutDate == null) {
          // İlk antrenman - bugün mü?
          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);
          
          if (workoutDate.isAtSameMomentAs(todayDate) || 
              workoutDate.isAtSameMomentAs(todayDate.subtract(const Duration(days: 1)))) {
            streak = 1;
            lastWorkoutDate = workoutDate;
          } else {
            break; // Bugün veya dün antrenman yoksa streak bitmiş
          }
        } else {
          // Bir önceki antrenmanla arasındaki fark
          final diff = lastWorkoutDate.difference(workoutDate).inDays;
          
          if (diff == 1) {
            streak++;
            lastWorkoutDate = workoutDate;
          } else {
            break; // Streak kırıldı
          }
        }
      }

      return streak;
    } catch (e) {
      return 0;
    }
  }

  // Toplam antrenman sayısı
  Future<int> getTotalWorkoutCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      // Fallback: tüm antrenmanları say
      final workouts = await getUserWorkouts(userId);
      return workouts.length;
    }
  }

  // Toplam antrenman süresi (dakika)
  Future<int> getTotalWorkoutDuration(String userId) async {
    try {
      final workouts = await getUserWorkouts(userId);
      return workouts.fold<int>(0, (int sum, workout) => sum + workout.totalDuration);
    } catch (e) {
      return 0;
    }
  }

  // Bu hafta kaç antrenman yapılmış
  Future<int> getThisWeekWorkoutCount(String userId) async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

      // Index gerektirmemek için memory'de filtreliyoruz
      final workouts = await getUserWorkouts(userId);
      final thisWeekWorkouts = workouts.where((workout) {
        return workout.date.isAfter(startOfWeekDate.subtract(const Duration(seconds: 1)));
      }).toList();

      return thisWeekWorkouts.length;
    } catch (e) {
      return 0;
    }
  }

  // Bugün antrenman yapıldı mı?
  Future<bool> hasWorkoutToday(String userId) async {
    try {
      final workouts = await getUserWorkouts(userId);
      if (workouts.isEmpty) return false;

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      return workouts.any((workout) {
        final workoutDate = DateTime(
          workout.date.year,
          workout.date.month,
          workout.date.day,
        );
        return workoutDate.isAtSameMomentAs(todayDate);
      });
    } catch (e) {
      return false;
    }
  }

  // Belirli bir günde antrenman yapıldı mı?
  bool hasWorkoutOnDate(List<WorkoutSession> workouts, DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return workouts.any((workout) {
      final workoutDate = DateTime(
        workout.date.year,
        workout.date.month,
        workout.date.day,
      );
      return workoutDate.isAtSameMomentAs(targetDate);
    });
  }

  // Son 7 günün durumunu getir (her gün için true/false)
  Future<List<bool>> getLast7DaysStatus(String userId) async {
    try {
      final workouts = await getUserWorkouts(userId);
      final now = DateTime.now();
      final List<bool> status = [];

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        status.add(hasWorkoutOnDate(workouts, date));
      }

      return status;
    } catch (e) {
      return List.filled(7, false);
    }
  }

  // Bu ay kaç gün antrenman yapıldı
  Future<int> getThisMonthActiveDays(String userId) async {
    try {
      final workouts = await getUserWorkouts(userId);
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final monthWorkouts = workouts.where((workout) {
        return workout.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1)));
      }).toList();

      // Farklı günleri say
      final uniqueDays = <String>{};
      for (final workout in monthWorkouts) {
        final dayKey = '${workout.date.year}-${workout.date.month}-${workout.date.day}';
        uniqueDays.add(dayKey);
      }

      return uniqueDays.length;
    } catch (e) {
      return 0;
    }
  }
}

