import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/workout_session.dart';
import '../models/exercise.dart';
import '../models/program_template.dart';
import 'user_role_service.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRoleService _userRoleService = UserRoleService();

  // Kullanıcının admin olup olmadığını kontrol et
  Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Admin check: No user logged in');
        return false;
      }

      print('🔍 Admin check: Checking user ${user.uid}');
      final isAdmin = await _userRoleService.isAdmin(user.uid);
      print('✅ Admin check result: isAdmin = $isAdmin for user ${user.uid}');
      return isAdmin;
    } catch (e, stackTrace) {
      print('❌ Admin check error: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  // Kullanıcıyı admin yap
  Future<void> setAdminStatus(String userId, bool isAdmin) async {
    try {
      if (isAdmin) {
        await _userRoleService.makeAdmin(userId, assignedBy: _auth.currentUser?.uid);
      } else {
        await _userRoleService.removeAdmin(userId);
      }
    } catch (e) {
      throw Exception('Admin durumu güncellenemedi: ${e.toString()}');
    }
  }

  // Tüm kullanıcıları getir
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('user_profiles').get();
      final users = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        try {
          final profileData = doc.data();
          final userId = doc.id;

          // Kullanıcı bilgilerini al
          final userDoc = await _firestore.collection('users').doc(userId).get();
          final userData = userDoc.data() ?? {};

          // Admin kontrolü - user_roles koleksiyonundan
          final isAdmin = await _userRoleService.isAdmin(userId);

          // Antrenman istatistiklerini al
          final workoutSnapshot = await _firestore
              .collection('workout_sessions')
              .where('userId', isEqualTo: userId)
              .get();

          final totalWorkouts = workoutSnapshot.docs.length;
          final totalDuration = workoutSnapshot.docs.fold<int>(
            0,
            (sum, workoutDoc) {
              final duration = workoutDoc.data()['totalDuration'];
              if (duration is int) {
                return sum + duration;
              } else if (duration is num) {
                return sum + duration.toInt();
              }
              return sum;
            },
          );

          users.add({
            'userId': userId,
            'email': profileData['email'] ?? '',
            'height': (profileData['height'] ?? 0.0) is num 
                ? (profileData['height'] as num).toDouble() 
                : 0.0,
            'weight': (profileData['weight'] ?? 0.0) is num 
                ? (profileData['weight'] as num).toDouble() 
                : 0.0,
            'age': profileData['age'] is num 
                ? (profileData['age'] as num).toInt() 
                : 0,
            'gender': profileData['gender'] ?? '',
            'bmi': (profileData['bmi'] ?? 0.0) is num 
                ? (profileData['bmi'] as num).toDouble() 
                : 0.0,
            'isAdmin': isAdmin,
            'totalWorkouts': totalWorkouts,
            'totalDuration': totalDuration,
            'createdAt': userDoc.data()?['createdAt'],
          });
        } catch (e) {
          print('Error processing user ${doc.id}: $e');
          // Bu kullanıcıyı atla ve devam et
          continue;
        }
      }

      return users;
    } catch (e, stackTrace) {
      print('Get all users error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Kullanıcılar yüklenemedi: ${e.toString()}');
    }
  }

  // Kullanıcının antrenmanlarını getir
  Future<List<WorkoutSession>> getUserWorkouts(String userId) async {
    try {
      // orderBy index gerektirebilir, bu yüzden önce where ile çekip memory'de sıralayalım
      final snapshot = await _firestore
          .collection('workout_sessions')
          .where('userId', isEqualTo: userId)
          .get();

      final workouts = snapshot.docs
          .map((doc) {
            try {
              return WorkoutSession.fromMap(doc.data());
            } catch (e) {
              print('Error parsing workout ${doc.id}: $e');
              return null;
            }
          })
          .whereType<WorkoutSession>()
          .toList();

      // Tarihe göre sırala (en yeni önce)
      workouts.sort((a, b) => b.date.compareTo(a.date));

      return workouts;
    } catch (e, stackTrace) {
      print('Get user workouts error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Antrenmanlar yüklenemedi: ${e.toString()}');
    }
  }

  // Tüm egzersizleri getir
  Future<List<Exercise>> getAllExercises() async {
    try {
      final snapshot = await _firestore.collection('exercises').get();
      final exercises = <Exercise>[];
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          exercises.add(Exercise.fromMap(data));
        } catch (e) {
          print('Error parsing exercise ${doc.id}: $e');
          // Bu egzersizi atla ve devam et
          continue;
        }
      }
      
      return exercises;
    } catch (e, stackTrace) {
      print('Get all exercises error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Egzersizler yüklenemedi: ${e.toString()}');
    }
  }

  // Tüm program şablonlarını getir
  Future<List<ProgramTemplate>> getAllProgramTemplates() async {
    try {
      final snapshot = await _firestore.collection('program_templates').get();
      final templates = <ProgramTemplate>[];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          templates.add(ProgramTemplate.fromMap(data));
        } catch (e) {
          print('Error parsing program template ${doc.id}: $e');
          continue;
        }
      }

      return templates;
    } catch (e, stackTrace) {
      print('Get all program templates error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Program şablonları yüklenemedi: ${e.toString()}');
    }
  }

  // Program şablonu ekle
  Future<void> addProgramTemplate(ProgramTemplate template) async {
    try {
      await _firestore
          .collection('program_templates')
          .doc(template.id)
          .set(template.toMap());
    } catch (e) {
      throw Exception('Program şablonu eklenemedi: ${e.toString()}');
    }
  }

  // Program şablonu güncelle
  Future<void> updateProgramTemplate(ProgramTemplate template) async {
    try {
      await _firestore
          .collection('program_templates')
          .doc(template.id)
          .update(template.toMap());
    } catch (e) {
      throw Exception('Program şablonu güncellenemedi: ${e.toString()}');
    }
  }

  // Program şablonu sil
  Future<void> deleteProgramTemplate(String templateId) async {
    try {
      await _firestore.collection('program_templates').doc(templateId).delete();
    } catch (e) {
      throw Exception('Program şablonu silinemedi: ${e.toString()}');
    }
  }

  // Egzersiz ekle
  Future<void> addExercise(Exercise exercise) async {
    try {
      await _firestore
          .collection('exercises')
          .doc(exercise.id)
          .set(exercise.toMap());
    } catch (e) {
      throw Exception('Egzersiz eklenemedi: ${e.toString()}');
    }
  }

  // Egzersiz güncelle
  Future<void> updateExercise(Exercise exercise) async {
    try {
      await _firestore
          .collection('exercises')
          .doc(exercise.id)
          .update(exercise.toMap());
    } catch (e) {
      throw Exception('Egzersiz güncellenemedi: ${e.toString()}');
    }
  }

  // Egzersiz sil
  Future<void> deleteExercise(String exerciseId) async {
    try {
      await _firestore.collection('exercises').doc(exerciseId).delete();
    } catch (e) {
      throw Exception('Egzersiz silinemedi: ${e.toString()}');
    }
  }

  // Dashboard istatistikleri
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Toplam kullanıcı sayısı - count() yerine get() kullan
      final usersSnapshot = await _firestore.collection('user_profiles').get();
      final totalUsers = usersSnapshot.docs.length;

      // Toplam antrenman sayısı
      final workoutsSnapshot = await _firestore.collection('workout_sessions').get();
      final totalWorkouts = workoutsSnapshot.docs.length;

      // Toplam egzersiz sayısı
      final exercisesSnapshot = await _firestore.collection('exercises').get();
      final totalExercises = exercisesSnapshot.docs.length;

      // Bugünkü antrenmanlar - tüm antrenmanları çekip memory'de filtrele
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final todayWorkoutCount = workoutsSnapshot.docs.where((doc) {
        final date = doc.data()['date'];
        if (date == null) return false;
        Timestamp timestamp;
        if (date is Timestamp) {
          timestamp = date;
        } else {
          return false;
        }
        final workoutDate = timestamp.toDate();
        return workoutDate.isAfter(startOfDay.subtract(const Duration(seconds: 1)));
      }).length;

      // Bu haftaki antrenmanlar
      final startOfWeek = startOfDay.subtract(Duration(days: today.weekday - 1));
      final weekWorkoutCount = workoutsSnapshot.docs.where((doc) {
        final date = doc.data()['date'];
        if (date == null) return false;
        Timestamp timestamp;
        if (date is Timestamp) {
          timestamp = date;
        } else {
          return false;
        }
        final workoutDate = timestamp.toDate();
        return workoutDate.isAfter(startOfWeek.subtract(const Duration(seconds: 1)));
      }).length;

      // En popüler egzersizler
      final exerciseCounts = <String, int>{};
      for (var doc in workoutsSnapshot.docs) {
        final data = doc.data();
        final exerciseNames = data['exerciseNames'] as List<dynamic>? ?? [];
        for (var name in exerciseNames) {
          if (name is String) {
            exerciseCounts[name] = (exerciseCounts[name] ?? 0) + 1;
          }
        }
      }
      final popularExercises = exerciseCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return {
        'totalUsers': totalUsers,
        'totalWorkouts': totalWorkouts,
        'totalExercises': totalExercises,
        'todayWorkouts': todayWorkoutCount,
        'weekWorkouts': weekWorkoutCount,
        'popularExercises': popularExercises.take(5).map((e) => {
              'name': e.key,
              'count': e.value,
            }).toList(),
      };
    } catch (e, stackTrace) {
      print('Dashboard stats error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('İstatistikler yüklenemedi: ${e.toString()}');
    }
  }

  // Kullanıcı sil
  Future<void> deleteUser(String userId) async {
    try {
      // Kullanıcı profilini sil
      await _firestore.collection('user_profiles').doc(userId).delete();
      
      // Kullanıcı verilerini sil
      await _firestore.collection('users').doc(userId).delete();
      
      // Kullanıcı rollerini sil
      await _firestore.collection('user_roles').doc(userId).delete();
      
      // Kullanıcının antrenmanlarını sil
      final workouts = await _firestore
          .collection('workout_sessions')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in workouts.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Kullanıcı silinemedi: ${e.toString()}');
    }
  }

  // Varsayılan egzersizleri Firestore'a yükle
  Future<void> loadDefaultExercises() async {
    try {
      // ExerciseRecommendationService'ten varsayılan egzersizleri al
      // Bu metod private olduğu için, direkt olarak çağıramayız
      // Bunun yerine, admin panelinde bir buton ile kullanıcıya seçenek sunabiliriz
      // Veya bu servisi import edip kullanabiliriz
      
      // Şimdilik, kullanıcıya admin panelinde bir buton ekleyeceğiz
      // ve bu buton ExerciseRecommendationService.saveExercisesToFirestore() metodunu çağıracak
      
      throw Exception('Bu metod ExerciseRecommendationService üzerinden çağrılmalı');
    } catch (e) {
      throw Exception('Varsayılan egzersizler yüklenemedi: ${e.toString()}');
    }
  }
}

