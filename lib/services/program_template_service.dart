import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/program_template.dart';

class ProgramTemplateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'program_templates';

  Future<List<ProgramTemplate>> getAllTemplates() async {
    final snapshot = await _firestore.collection(_collection).get();
    return snapshot.docs
        .map((doc) => ProgramTemplate.fromMap(doc.data()))
        .toList();
  }

  /// Kullanıcının hedefi, deneyim seviyesi ve haftalık hedefi baz alınarak
  /// en uygun program şablonunu döndürür.
  Future<ProgramTemplate?> getBestTemplateForUser({
    required String goal,
    required String? experienceLevel,
    required int? weeklyWorkoutTarget,
    required int? sessionDurationMin,
    required List<String> availableEquipment,
  }) async {
    final all = await getAllTemplates();
    if (all.isEmpty) return null;

    ProgramTemplate? best;
    int bestScore = -999999;

    for (final template in all) {
      final score = _scoreTemplate(
        template,
        goal: goal,
        experienceLevel: experienceLevel,
        weeklyWorkoutTarget: weeklyWorkoutTarget,
        sessionDurationMin: sessionDurationMin,
        availableEquipment: availableEquipment,
      );

      if (score > bestScore) {
        bestScore = score;
        best = template;
      }
    }

    return best;
  }

  int _scoreTemplate(
    ProgramTemplate template, {
    required String goal,
    required String? experienceLevel,
    required int? weeklyWorkoutTarget,
    required int? sessionDurationMin,
    required List<String> availableEquipment,
  }) {
    int score = 0;

    // Hedefleri normalize et (Türkçe metin veya kod fark etmesin)
    final normalizedUserGoal = _normalizeGoal(goal);
    final normalizedTemplateGoals =
        template.goals.map(_normalizeGoal).toSet();

    // Hedef uyumu
    if (normalizedTemplateGoals.contains(normalizedUserGoal)) {
      score += 40;
    }

    // Deneyim seviyesi uyumu
    if (experienceLevel != null && experienceLevel.isNotEmpty) {
      if (template.experienceLevels.contains(experienceLevel)) {
        score += 30;
      } else if (template.experienceLevels.isEmpty) {
        score += 5;
      }
    }

    // Haftalık hedefe yakınlık
    if (weeklyWorkoutTarget != null && weeklyWorkoutTarget > 0) {
      final diff = (template.daysPerWeek - weeklyWorkoutTarget).abs();
      if (diff == 0) {
        score += 20;
      } else if (diff == 1) {
        score += 10;
      } else if (diff == 2) {
        score += 5;
      } else {
        score -= diff * 2;
      }
    }

    // Seans süresine yakınlık
    if (sessionDurationMin != null && sessionDurationMin > 0) {
      final diff =
          (template.recommendedSessionDurationMin - sessionDurationMin).abs();
      if (diff <= 5) {
        score += 15;
      } else if (diff <= 10) {
        score += 8;
      } else if (diff >= 20) {
        score -= 5;
      }
    }

    // Ekipman uyumu
    if (template.requiredEquipment.isNotEmpty) {
      final matches = template.requiredEquipment
          .where((eq) => availableEquipment.contains(eq))
          .length;
      if (matches == template.requiredEquipment.length) {
        score += 15; // Tüm ekipmanlar var
      } else if (matches > 0) {
        score += 5; // Kısmi uyum
      } else {
        score -= 10; // Hiçbiri yok
      }
    }

    return score;
  }

  String _normalizeGoal(String raw) {
    final value = raw.toLowerCase().trim();

    if (value.contains('weight_loss') || value.contains('kilo')) {
      return 'weight_loss';
    }
    if (value.contains('muscle_gain') ||
        value.contains('kas') ||
        value.contains('güç')) {
      return 'muscle_gain';
    }
    if (value.contains('general_fitness') ||
        value.contains('genel') ||
        value.contains('fitness') ||
        value.contains('sağlık')) {
      return 'general_fitness';
    }
    if (value.contains('mobility') ||
        value.contains('esnek') ||
        value.contains('mobil')) {
      return 'mobility';
    }
    if (value.contains('performance') ||
        value.contains('performans') ||
        value.contains('dayanıklılık')) {
      return 'performance';
    }

    return value;
  }
}


