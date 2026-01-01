import 'package:cloud_firestore/cloud_firestore.dart';

class ProgramDayCompletion {
  final String id;
  final String userId;
  final String programId;
  final int weekIndex;
  final int dayIndex;
  final DateTime completedAt;
  final String? workoutSessionId; // İlgili workout_sessions dokümanına referans (opsiyonel)

  ProgramDayCompletion({
    required this.id,
    required this.userId,
    required this.programId,
    required this.weekIndex,
    required this.dayIndex,
    required this.completedAt,
    this.workoutSessionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'programId': programId,
      'weekIndex': weekIndex,
      'dayIndex': dayIndex,
      'completedAt': Timestamp.fromDate(completedAt),
      if (workoutSessionId != null) 'workoutSessionId': workoutSessionId,
    };
  }

  factory ProgramDayCompletion.fromMap(Map<String, dynamic> map) {
    return ProgramDayCompletion(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      programId: map['programId'] ?? '',
      weekIndex: (map['weekIndex'] ?? 0) as int,
      dayIndex: (map['dayIndex'] ?? 0) as int,
      completedAt: (map['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      workoutSessionId: map['workoutSessionId'] as String?,
    );
  }
}

