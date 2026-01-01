class ProgramDay {
  final int weekIndex; // 1-based
  final int dayIndex; // 1-based, haftanın içindeki gün sırası
  final String title;
  final String? description;
  final List<String> bodyRegions;
  final List<String> exerciseIds;

  ProgramDay({
    required this.weekIndex,
    required this.dayIndex,
    required this.title,
    this.description,
    required this.bodyRegions,
    required this.exerciseIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'weekIndex': weekIndex,
      'dayIndex': dayIndex,
      'title': title,
      'description': description,
      'bodyRegions': bodyRegions,
      'exerciseIds': exerciseIds,
    };
  }

  factory ProgramDay.fromMap(Map<String, dynamic> map) {
    return ProgramDay(
      weekIndex: (map['weekIndex'] ?? 1) as int,
      dayIndex: (map['dayIndex'] ?? 1) as int,
      title: map['title'] ?? '',
      description: map['description'] as String?,
      bodyRegions: List<String>.from((map['bodyRegions'] ?? []) as List),
      exerciseIds: List<String>.from((map['exerciseIds'] ?? []) as List),
    );
  }
}

class ProgramTemplate {
  final String id;
  final String name;
  final String description;
  final List<String> goals; // weight_loss, muscle_gain, general_fitness, ...
  final List<String> experienceLevels; // beginner/intermediate/advanced
  final int totalWeeks;
  final int daysPerWeek;
  final int recommendedSessionDurationMin;
  final List<String> focusBodyRegions;
  final List<String> requiredEquipment;
  final List<ProgramDay> days;

  ProgramTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.goals,
    required this.experienceLevels,
    required this.totalWeeks,
    required this.daysPerWeek,
    required this.recommendedSessionDurationMin,
    required this.focusBodyRegions,
    required this.requiredEquipment,
    required this.days,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'goals': goals,
      'experienceLevels': experienceLevels,
      'totalWeeks': totalWeeks,
      'daysPerWeek': daysPerWeek,
      'recommendedSessionDurationMin': recommendedSessionDurationMin,
      'focusBodyRegions': focusBodyRegions,
      'requiredEquipment': requiredEquipment,
      'days': days.map((d) => d.toMap()).toList(),
    };
  }

  factory ProgramTemplate.fromMap(Map<String, dynamic> map) {
    final List<dynamic> rawDays = map['days'] as List<dynamic>? ?? [];
    final parsedDays = rawDays
        .whereType<Map<String, dynamic>>()
        .map((dayMap) => ProgramDay.fromMap(dayMap))
        .toList();

    return ProgramTemplate(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      goals: List<String>.from((map['goals'] ?? []) as List),
      experienceLevels: List<String>.from((map['experienceLevels'] ?? []) as List),
      totalWeeks: (map['totalWeeks'] ?? 4) as int,
      daysPerWeek: (map['daysPerWeek'] ?? 3) as int,
      recommendedSessionDurationMin:
          (map['recommendedSessionDurationMin'] ?? 30) as int,
      focusBodyRegions: List<String>.from((map['focusBodyRegions'] ?? []) as List),
      requiredEquipment: List<String>.from((map['requiredEquipment'] ?? []) as List),
      days: parsedDays,
    );
  }
}


