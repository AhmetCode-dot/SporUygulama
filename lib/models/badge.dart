class AchievementBadge {
  final String id;
  final String name;
  final String description;
  final String icon; // Emoji veya icon adı
  final BadgeType type;
  final int requiredValue; // Gerekli değer (örn: 7 gün streak için 7)
  final BadgeCategory category;

  AchievementBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.requiredValue,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'type': type.toString().split('.').last,
      'requiredValue': requiredValue,
      'category': category.toString().split('.').last,
    };
  }

  factory AchievementBadge.fromMap(Map<String, dynamic> map) {
    return AchievementBadge(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '🏆',
      type: BadgeType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => BadgeType.totalWorkouts,
      ),
      requiredValue: (map['requiredValue'] ?? 0) as int,
      category: BadgeCategory.values.firstWhere(
        (e) => e.toString().split('.').last == map['category'],
        orElse: () => BadgeCategory.milestone,
      ),
    );
  }
}

enum BadgeType {
  totalWorkouts, // Toplam antrenman sayısı
  totalDuration, // Toplam süre (dakika)
  streak, // Art arda gün
  weeklyGoal, // Haftalık hedef
  programCompletion, // Program tamamlama
  firstWorkout, // İlk antrenman
  weekCompletion, // Hafta tamamlama
}

enum BadgeCategory {
  milestone, // Kilometre taşları
  consistency, // Tutarlılık
  achievement, // Başarılar
  special, // Özel
}

