class NotificationPreferences {
  final String userId;
  final bool dailyRemindersEnabled;
  final bool streakWarningsEnabled;
  final bool weeklySummaryEnabled;
  final bool achievementNotificationsEnabled;
  final String? reminderTime; // "HH:mm" formatında (örn: "18:00")
  final List<int> reminderDays; // 1=Pazartesi, 7=Pazar

  NotificationPreferences({
    required this.userId,
    this.dailyRemindersEnabled = true,
    this.streakWarningsEnabled = true,
    this.weeklySummaryEnabled = true,
    this.achievementNotificationsEnabled = true,
    this.reminderTime,
    List<int>? reminderDays,
  }) : reminderDays = reminderDays ?? [1, 2, 3, 4, 5, 6, 7]; // Varsayılan: Her gün

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'dailyRemindersEnabled': dailyRemindersEnabled,
      'streakWarningsEnabled': streakWarningsEnabled,
      'weeklySummaryEnabled': weeklySummaryEnabled,
      'achievementNotificationsEnabled': achievementNotificationsEnabled,
      'reminderTime': reminderTime,
      'reminderDays': reminderDays,
    };
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      userId: map['userId'] ?? '',
      dailyRemindersEnabled: (map['dailyRemindersEnabled'] ?? true) as bool,
      streakWarningsEnabled: (map['streakWarningsEnabled'] ?? true) as bool,
      weeklySummaryEnabled: (map['weeklySummaryEnabled'] ?? true) as bool,
      achievementNotificationsEnabled: (map['achievementNotificationsEnabled'] ?? true) as bool,
      reminderTime: map['reminderTime'] as String?,
      reminderDays: List<int>.from((map['reminderDays'] ?? [1, 2, 3, 4, 5, 6, 7]) as List),
    );
  }

  NotificationPreferences copyWith({
    bool? dailyRemindersEnabled,
    bool? streakWarningsEnabled,
    bool? weeklySummaryEnabled,
    bool? achievementNotificationsEnabled,
    String? reminderTime,
    List<int>? reminderDays,
  }) {
    return NotificationPreferences(
      userId: userId,
      dailyRemindersEnabled: dailyRemindersEnabled ?? this.dailyRemindersEnabled,
      streakWarningsEnabled: streakWarningsEnabled ?? this.streakWarningsEnabled,
      weeklySummaryEnabled: weeklySummaryEnabled ?? this.weeklySummaryEnabled,
      achievementNotificationsEnabled: achievementNotificationsEnabled ?? this.achievementNotificationsEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderDays: reminderDays ?? this.reminderDays,
    );
  }
}

