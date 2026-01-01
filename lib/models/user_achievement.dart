import 'package:cloud_firestore/cloud_firestore.dart';

class UserAchievement {
  final String id;
  final String userId;
  final String badgeId;
  final DateTime earnedAt;
  final int? progress; // İlerleme (opsiyonel, bazı rozetler için)

  UserAchievement({
    required this.id,
    required this.userId,
    required this.badgeId,
    required this.earnedAt,
    this.progress,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'badgeId': badgeId,
      'earnedAt': Timestamp.fromDate(earnedAt),
      if (progress != null) 'progress': progress,
    };
  }

  factory UserAchievement.fromMap(Map<String, dynamic> map) {
    return UserAchievement(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      badgeId: map['badgeId'] ?? '',
      earnedAt: (map['earnedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      progress: map['progress'] as int?,
    );
  }
}

