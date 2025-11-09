class Exercise {
  final String id;
  final String name;
  final String description;
  final List<String> bodyRegions;
  final List<String> goals;
  final List<String> equipment;
  final List<String> environments;
  final int duration; // dakika
  final int difficulty; // 1-5 arası
  final String instructions;
  final String imageUrl;
  final List<String> benefits;
  final String? instructionGifUrl;
  final String? instructionVideoAsset;

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.bodyRegions,
    required this.goals,
    required this.equipment,
    required this.environments,
    required this.duration,
    required this.difficulty,
    required this.instructions,
    required this.imageUrl,
    required this.benefits,
    this.instructionGifUrl,
    this.instructionVideoAsset,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'bodyRegions': bodyRegions,
      'goals': goals,
      'equipment': equipment,
      'environments': environments,
      'duration': duration,
      'difficulty': difficulty,
      'instructions': instructions,
      'imageUrl': imageUrl,
      'benefits': benefits,
      if (instructionGifUrl != null) 'instructionGifUrl': instructionGifUrl,
      if (instructionVideoAsset != null) 'instructionVideoAsset': instructionVideoAsset,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      bodyRegions: List<String>.from(map['bodyRegions'] ?? []),
      goals: List<String>.from(map['goals'] ?? []),
      equipment: List<String>.from(map['equipment'] ?? []),
      environments: List<String>.from(map['environments'] ?? []),
      duration: map['duration'] ?? 0,
      difficulty: map['difficulty'] ?? 1,
      instructions: map['instructions'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      benefits: List<String>.from(map['benefits'] ?? []),
      instructionGifUrl: map['instructionGifUrl'] as String?,
      instructionVideoAsset: map['instructionVideoAsset'] as String?,
    );
  }

  String getDifficultyText() {
    switch (difficulty) {
      case 1:
        return 'Başlangıç';
      case 2:
        return 'Kolay';
      case 3:
        return 'Orta';
      case 4:
        return 'Zor';
      case 5:
        return 'İleri';
      default:
        return 'Bilinmiyor';
    }
  }

  String getDurationText() {
    if (duration < 60) {
      return '$duration dakika';
    } else {
      final hours = duration ~/ 60;
      final minutes = duration % 60;
      if (minutes == 0) {
        return '$hours saat';
      } else {
        return '$hours saat $minutes dakika';
      }
    }
  }
}
