import 'package:cloud_firestore/cloud_firestore.dart';

class UserProgramState {
  final String userId;
  final String programId;
  final DateTime startDate;
  final DateTime? lastUpdated;

  UserProgramState({
    required this.userId,
    required this.programId,
    required this.startDate,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'programId': programId,
      'startDate': Timestamp.fromDate(startDate),
      if (lastUpdated != null) 'lastUpdated': Timestamp.fromDate(lastUpdated!),
    };
  }

  factory UserProgramState.fromMap(Map<String, dynamic> map) {
    return UserProgramState(
      userId: map['userId'] ?? '',
      programId: map['programId'] ?? '',
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  /// Başlangıç tarihinden itibaren kaç hafta geçtiğini hesapla (1-based)
  int calculateCurrentWeek(int totalWeeks) {
    final now = DateTime.now();
    final daysSinceStart = now.difference(startDate).inDays;
    final weeksSinceStart = (daysSinceStart / 7).floor() + 1; // 1. hafta = 0-6 gün, 2. hafta = 7-13 gün, vs.
    return weeksSinceStart.clamp(1, totalWeeks);
  }
}

