import 'package:cloud_firestore/cloud_firestore.dart';

class Quest {
  final String id;
  final String title;
  final String description;
  final QuestType type;
  final int targetValue;
  final int? currentValue;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCompleted;
  final int xpReward;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    this.currentValue,
    this.startDate,
    this.endDate,
    this.isCompleted = false,
    this.xpReward = 50,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isCompleted': isCompleted,
      'xpReward': xpReward,
    };
  }

  factory Quest.fromMap(Map<String, dynamic> map) {
    return Quest(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: QuestType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => QuestType.weeklyWorkouts,
      ),
      targetValue: (map['targetValue'] ?? 0) as int,
      currentValue: map['currentValue'] as int?,
      startDate: (map['startDate'] as Timestamp?)?.toDate(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      isCompleted: (map['isCompleted'] ?? false) as bool,
      xpReward: (map['xpReward'] ?? 50) as int,
    );
  }

  double get progressPercentage {
    if (targetValue == 0) return 0.0;
    final current = currentValue ?? 0;
    return (current / targetValue).clamp(0.0, 1.0);
  }
}

enum QuestType {
  weeklyWorkouts, // Bu hafta X antrenman
  streakDays, // X gün streak
  totalDuration, // Toplam X dakika
  tryNewExercise, // Yeni egzersiz dene
  completeProgramWeek, // Program haftası tamamla
}

