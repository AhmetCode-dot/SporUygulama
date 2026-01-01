import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise_detail.dart';

class WorkoutSession {
  final String id;
  final String userId;
  final DateTime date;
  final List<String> exerciseIds; // Tamamlanan egzersizlerin ID'leri
  final List<String> exerciseNames; // Egzersiz isimleri (hızlı erişim için)
  final int totalDuration; // Toplam süre (dakika)
  final String? notes; // Genel kullanıcı notları
  final int? difficulty; // Zorluk seviyesi (1-5 arası)
  final Map<String, ExerciseDetail> exerciseDetails; // Her egzersiz için detaylar
  
  // Program referansları (opsiyonel - plan gününden oluşturulduysa)
  final String? programId;
  final int? programWeekIndex;
  final int? programDayIndex;

  WorkoutSession({
    required this.id,
    required this.userId,
    required this.date,
    required this.exerciseIds,
    required this.exerciseNames,
    required this.totalDuration,
    this.notes,
    this.difficulty,
    Map<String, ExerciseDetail>? exerciseDetails,
    this.programId,
    this.programWeekIndex,
    this.programDayIndex,
  }) : exerciseDetails = exerciseDetails ?? {};

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'exerciseIds': exerciseIds,
      'exerciseNames': exerciseNames,
      'totalDuration': totalDuration,
      'notes': notes,
      'difficulty': difficulty,
      'exerciseDetails': exerciseDetails.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      if (programId != null) 'programId': programId,
      if (programWeekIndex != null) 'programWeekIndex': programWeekIndex,
      if (programDayIndex != null) 'programDayIndex': programDayIndex,
    };
  }

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    final exerciseDetailsMap = map['exerciseDetails'] as Map<String, dynamic>? ?? {};
    final exerciseDetails = exerciseDetailsMap.map(
      (key, value) => MapEntry(
        key,
        ExerciseDetail.fromMap(value as Map<String, dynamic>),
      ),
    );

    return WorkoutSession(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      exerciseIds: List<String>.from(map['exerciseIds'] ?? []),
      exerciseNames: List<String>.from(map['exerciseNames'] ?? []),
      totalDuration: map['totalDuration'] ?? 0,
      notes: map['notes'] as String?,
      difficulty: map['difficulty'] as int?,
      exerciseDetails: exerciseDetails,
      programId: map['programId'] as String?,
      programWeekIndex: map['programWeekIndex'] as int?,
      programDayIndex: map['programDayIndex'] as int?,
    );
  }

  // Streak hesaplama için yardımcı metod
  static bool isConsecutiveDay(DateTime date1, DateTime date2) {
    final diff = date1.difference(date2).inDays;
    return diff == 1 || diff == -1;
  }
}

