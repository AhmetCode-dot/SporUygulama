class UserPreferences {
  final String userId;
  final String goal;
  final String experienceLevel;
  final int weeklyWorkoutTarget;
  final int sessionDurationMin;
  final String preferredEnvironment;
  final List<String> availableEquipment;
  final List<String> preferredBodyRegions;
  final List<String> limitations;

  UserPreferences({
    required this.userId,
    required this.goal,
    required this.experienceLevel,
    required this.weeklyWorkoutTarget,
    required this.sessionDurationMin,
    required this.preferredEnvironment,
    required this.availableEquipment,
    required this.preferredBodyRegions,
    required this.limitations,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'goal': goal,
      'experienceLevel': experienceLevel,
      'weeklyWorkoutTarget': weeklyWorkoutTarget,
      'sessionDurationMin': sessionDurationMin,
      'preferredEnvironment': preferredEnvironment,
      'availableEquipment': availableEquipment,
      'preferredBodyRegions': preferredBodyRegions,
      'limitations': limitations,
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      userId: map['userId'] ?? '',
      goal: map['goal'] ?? '',
      experienceLevel: map['experienceLevel'] ?? '',
      weeklyWorkoutTarget: (map['weeklyWorkoutTarget'] ?? 0) as int,
      sessionDurationMin: (map['sessionDurationMin'] ?? 0) as int,
      preferredEnvironment: map['preferredEnvironment'] ?? '',
      availableEquipment: List<String>.from((map['availableEquipment'] ?? []) as List),
      preferredBodyRegions: List<String>.from((map['preferredBodyRegions'] ?? []) as List),
      limitations: List<String>.from((map['limitations'] ?? []) as List),
    );
  }
}


