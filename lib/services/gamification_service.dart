import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/badge.dart';
import '../models/user_achievement.dart';
import '../models/user_level.dart';
import '../models/quest.dart';
import '../services/workout_service.dart';
import '../services/program_day_completion_service.dart';
import '../services/notification_service.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WorkoutService _workoutService = WorkoutService();
  final ProgramDayCompletionService _completionService = ProgramDayCompletionService();

  // Varsayılan rozetler (Firestore'da saklanabilir veya hardcoded)
  static List<AchievementBadge> getDefaultBadges() {
    return [
      // İlk adımlar
      AchievementBadge(
        id: 'first_workout',
        name: 'İlk Adım',
        description: 'İlk antrenmanını tamamla',
        icon: '🎯',
        type: BadgeType.firstWorkout,
        requiredValue: 1,
        category: BadgeCategory.milestone,
      ),
      // Antrenman sayıları
      AchievementBadge(
        id: 'workout_5',
        name: 'Başlangıç',
        description: '5 antrenman tamamla',
        icon: '🔥',
        type: BadgeType.totalWorkouts,
        requiredValue: 5,
        category: BadgeCategory.milestone,
      ),
      AchievementBadge(
        id: 'workout_10',
        name: 'Kararlılık',
        description: '10 antrenman tamamla',
        icon: '💪',
        type: BadgeType.totalWorkouts,
        requiredValue: 10,
        category: BadgeCategory.milestone,
      ),
      AchievementBadge(
        id: 'workout_25',
        name: 'Deneyimli',
        description: '25 antrenman tamamla',
        icon: '🏆',
        type: BadgeType.totalWorkouts,
        requiredValue: 25,
        category: BadgeCategory.achievement,
      ),
      AchievementBadge(
        id: 'workout_50',
        name: 'Uzman',
        description: '50 antrenman tamamla',
        icon: '👑',
        type: BadgeType.totalWorkouts,
        requiredValue: 50,
        category: BadgeCategory.achievement,
      ),
      // Streak rozetleri
      AchievementBadge(
        id: 'streak_3',
        name: '3 Gün Serisi',
        description: '3 gün üst üste antrenman yap',
        icon: '🔥',
        type: BadgeType.streak,
        requiredValue: 3,
        category: BadgeCategory.consistency,
      ),
      AchievementBadge(
        id: 'streak_7',
        name: 'Haftalık Seri',
        description: '7 gün üst üste antrenman yap',
        icon: '⭐',
        type: BadgeType.streak,
        requiredValue: 7,
        category: BadgeCategory.consistency,
      ),
      AchievementBadge(
        id: 'streak_14',
        name: 'İki Haftalık Seri',
        description: '14 gün üst üste antrenman yap',
        icon: '🌟',
        type: BadgeType.streak,
        requiredValue: 14,
        category: BadgeCategory.consistency,
      ),
      AchievementBadge(
        id: 'streak_30',
        name: 'Aylık Seri',
        description: '30 gün üst üste antrenman yap',
        icon: '💎',
        type: BadgeType.streak,
        requiredValue: 30,
        category: BadgeCategory.consistency,
      ),
      // Süre rozetleri
      AchievementBadge(
        id: 'duration_500',
        name: '500 Dakika',
        description: 'Toplam 500 dakika antrenman yap',
        icon: '⏱️',
        type: BadgeType.totalDuration,
        requiredValue: 500,
        category: BadgeCategory.milestone,
      ),
      AchievementBadge(
        id: 'duration_1000',
        name: '1000 Dakika',
        description: 'Toplam 1000 dakika antrenman yap',
        icon: '⏰',
        type: BadgeType.totalDuration,
        requiredValue: 1000,
        category: BadgeCategory.achievement,
      ),
      // Program rozetleri
      AchievementBadge(
        id: 'program_week_1',
        name: 'İlk Hafta',
        description: 'Programın ilk haftasını tamamla',
        icon: '📅',
        type: BadgeType.weekCompletion,
        requiredValue: 1,
        category: BadgeCategory.milestone,
      ),
      AchievementBadge(
        id: 'program_complete',
        name: 'Program Tamamlandı',
        description: 'Bir programı tamamen tamamla',
        icon: '🎉',
        type: BadgeType.programCompletion,
        requiredValue: 1,
        category: BadgeCategory.achievement,
      ),
    ];
  }

  // Kullanıcının kazandığı rozetleri getir
  Future<List<UserAchievement>> getUserAchievements(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('user_achievements')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => UserAchievement.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Rozetler yüklenemedi: ${e.toString()}');
    }
  }

  // Kullanıcının seviyesini getir
  Future<UserLevel> getUserLevel(String userId) async {
    try {
      final doc = await _firestore
          .collection('user_levels')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        return UserLevel.fromMap(doc.data()!);
      }

      // İlk seviye oluştur
      final defaultLevel = UserLevel(
        userId: userId,
        level: 1,
        totalXP: 0,
        currentLevelXP: 0,
        xpForNextLevel: 100,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection('user_levels')
          .doc(userId)
          .set(defaultLevel.toMap());

      return defaultLevel;
    } catch (e) {
      throw Exception('Seviye yüklenemedi: ${e.toString()}');
    }
  }

  // XP ekle ve seviye kontrolü yap
  Future<void> addXP(String userId, int xp) async {
    try {
      final userLevel = await getUserLevel(userId);
      int newTotalXP = userLevel.totalXP + xp;
      int newCurrentLevelXP = userLevel.currentLevelXP + xp;
      int newLevel = userLevel.level;
      int xpForNextLevel = userLevel.xpForNextLevel;

      // Seviye atlama kontrolü
      while (newCurrentLevelXP >= xpForNextLevel) {
        newCurrentLevelXP -= xpForNextLevel;
        newLevel++;
        xpForNextLevel = _calculateXPForLevel(newLevel);
      }

      final updatedLevel = UserLevel(
        userId: userId,
        level: newLevel,
        totalXP: newTotalXP,
        currentLevelXP: newCurrentLevelXP,
        xpForNextLevel: xpForNextLevel,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection('user_levels')
          .doc(userId)
          .set(updatedLevel.toMap());
    } catch (e) {
      throw Exception('XP eklenemedi: ${e.toString()}');
    }
  }

  // Seviye için gereken XP hesapla (exponential growth)
  int _calculateXPForLevel(int level) {
    // Her seviye için XP artışı: 100 * (1.2 ^ level)
    return (100 * (1.2 * level)).round();
  }

  // Rozet kontrolü ve kazanma
  Future<List<AchievementBadge>> checkAndAwardBadges(String userId) async {
    try {
      final earnedBadges = <AchievementBadge>[];
      final existingAchievements = await getUserAchievements(userId);
      final existingBadgeIds = existingAchievements.map((a) => a.badgeId).toSet();

      // Kullanıcı istatistiklerini al
      final totalWorkouts = await _workoutService.getTotalWorkoutCount(userId);
      final streak = await _workoutService.calculateStreak(userId);
      final totalDuration = await _workoutService.getTotalWorkoutDuration(userId);

      // Program tamamlama kontrolü
      final programCompletions = await _completionService.getUserCompletions(userId);
      final completedPrograms = programCompletions
          .map((c) => c.programId)
          .toSet()
          .length;

      // Tüm rozetleri kontrol et
      for (final badge in getDefaultBadges()) {
        // Zaten kazanılmış mı?
        if (existingBadgeIds.contains(badge.id)) continue;

        bool shouldAward = false;

        switch (badge.type) {
          case BadgeType.firstWorkout:
            shouldAward = totalWorkouts >= badge.requiredValue;
            break;
          case BadgeType.totalWorkouts:
            shouldAward = totalWorkouts >= badge.requiredValue;
            break;
          case BadgeType.streak:
            shouldAward = streak >= badge.requiredValue;
            break;
          case BadgeType.totalDuration:
            shouldAward = totalDuration >= badge.requiredValue;
            break;
          case BadgeType.programCompletion:
            shouldAward = completedPrograms >= badge.requiredValue;
            break;
          case BadgeType.weekCompletion:
            // Hafta tamamlama kontrolü (basitleştirilmiş)
            shouldAward = programCompletions.length >= badge.requiredValue * 3; // Haftada ~3 gün varsayımı
            break;
          case BadgeType.weeklyGoal:
            // Haftalık hedef kontrolü (şimdilik atlanıyor)
            break;
        }

        if (shouldAward) {
          // Rozeti kazan
          await _awardBadge(userId, badge);
          earnedBadges.add(badge);

          // XP ödülü ver (rozet başına 25 XP)
          await addXP(userId, 25);
        }
      }

      return earnedBadges;
    } catch (e) {
      throw Exception('Rozet kontrolü yapılamadı: ${e.toString()}');
    }
  }

  // Rozet kazandır
  Future<void> _awardBadge(String userId, AchievementBadge badge) async {
    try {
      final achievement = UserAchievement(
        id: '${userId}_${badge.id}',
        userId: userId,
        badgeId: badge.id,
        earnedAt: DateTime.now(),
      );

      await _firestore
          .collection('user_achievements')
          .doc(achievement.id)
          .set(achievement.toMap());

      // Bildirim gönder (eğer kullanıcı tercihlerinde açıksa)
      try {
        final notificationService = NotificationService();
        final prefs = await notificationService.getNotificationPreferences(userId);
        if (prefs?.achievementNotificationsEnabled ?? true) {
          await notificationService.sendAchievementNotification(
            badgeName: badge.name,
            badgeIcon: badge.icon,
          );
        }
      } catch (e) {
        // Bildirim hatası sessizce geç
        print('Notification error: $e');
      }
    } catch (e) {
      throw Exception('Rozet kazandırılamadı: ${e.toString()}');
    }
  }

  // Antrenman sonrası otomatik kontrol (workout session kaydedildiğinde çağrılmalı)
  Future<void> onWorkoutCompleted(String userId, int workoutDuration) async {
    // Antrenman başına 10 XP
    await addXP(userId, 10);

    // Süre bazlı bonus XP (30 dakika üzeri için)
    if (workoutDuration >= 30) {
      await addXP(userId, 5);
    }
    if (workoutDuration >= 60) {
      await addXP(userId, 10);
    }

    // Rozet kontrolü
    await checkAndAwardBadges(userId);
  }
}

