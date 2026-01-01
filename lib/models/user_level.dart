import 'package:cloud_firestore/cloud_firestore.dart';

class UserLevel {
  final String userId;
  final int level;
  final int totalXP;
  final int currentLevelXP; // Bu seviyede kazanılan XP
  final int xpForNextLevel; // Bir sonraki seviye için gereken XP
  final DateTime lastUpdated;

  UserLevel({
    required this.userId,
    required this.level,
    required this.totalXP,
    required this.currentLevelXP,
    required this.xpForNextLevel,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'level': level,
      'totalXP': totalXP,
      'currentLevelXP': currentLevelXP,
      'xpForNextLevel': xpForNextLevel,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory UserLevel.fromMap(Map<String, dynamic> map) {
    return UserLevel(
      userId: map['userId'] ?? '',
      level: (map['level'] ?? 1) as int,
      totalXP: (map['totalXP'] ?? 0) as int,
      currentLevelXP: (map['currentLevelXP'] ?? 0) as int,
      xpForNextLevel: (map['xpForNextLevel'] ?? 100) as int,
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Seviye ilerleme yüzdesi (0.0 - 1.0)
  double get progressPercentage {
    if (xpForNextLevel == 0) return 1.0;
    return (currentLevelXP / xpForNextLevel).clamp(0.0, 1.0);
  }
}

