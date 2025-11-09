class ExerciseDetail {
  final int sets;
  final int reps; // Ortalama tekrar veya her set için aynı tekrar
  final double? weight; // kg cinsinden, opsiyonel
  final String? notes; // Bu egzersiz için özel notlar

  ExerciseDetail({
    required this.sets,
    required this.reps,
    this.weight,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'notes': notes,
    };
  }

  factory ExerciseDetail.fromMap(Map<String, dynamic> map) {
    return ExerciseDetail(
      sets: map['sets'] ?? 1,
      reps: map['reps'] ?? 10,
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
      notes: map['notes'] as String?,
    );
  }

  String getDisplayText() {
    if (weight != null) {
      return '$sets set x $reps tekrar, ${weight!.toStringAsFixed(1)} kg';
    }
    return '$sets set x $reps tekrar';
  }
}

