import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/program_template.dart';
import '../services/program_template_service.dart';
import '../services/program_day_completion_service.dart';
import '../services/workout_service.dart';
import '../models/workout_session.dart';
import '../models/exercise.dart';
import '../models/user_program_state.dart';
import '../services/user_program_state_service.dart';
import '../services/gamification_service.dart';
import '../models/badge.dart' as models;

class WeeklyPlanView extends StatefulWidget {
  const WeeklyPlanView({Key? key}) : super(key: key);

  @override
  State<WeeklyPlanView> createState() => _WeeklyPlanViewState();
}

class _WeeklyPlanViewState extends State<WeeklyPlanView> {
  final ProgramTemplateService _templateService = ProgramTemplateService();
  final ProgramDayCompletionService _completionService = ProgramDayCompletionService();
  final WorkoutService _workoutService = WorkoutService();
  final UserProgramStateService _programStateService = UserProgramStateService();
  final GamificationService _gamificationService = GamificationService();

  bool _isLoading = true;
  ProgramTemplate? _template;
  Set<String> _completedDays = {}; // "weekIndex_dayIndex" formatında
  UserProgramState? _programState;
  int _selectedWeekIndex = 1; // Manuel seçilen hafta (default: otomatik hesaplanan)

  // İlerleme hesaplama metodları
  double _calculateOverallProgress() {
    if (_template == null || _template!.days.isEmpty) return 0.0;
    final totalDays = _template!.days.length;
    final completedDays = _completedDays.length;
    return (completedDays / totalDays).clamp(0.0, 1.0);
  }

  double _calculateWeeklyProgress(int weekIndex) {
    if (_template == null) return 0.0;
    final weekDays = _template!.days.where((d) => d.weekIndex == weekIndex).toList();
    if (weekDays.isEmpty) return 0.0;
    
    final completedWeekDays = weekDays
        .where((d) => _completedDays.contains('${d.weekIndex}_${d.dayIndex}'))
        .length;
    return (completedWeekDays / weekDays.length).clamp(0.0, 1.0);
  }

  Map<String, int> _getProgressStats() {
    if (_template == null) {
      return {
        'totalDays': 0,
        'completedDays': 0,
        'remainingDays': 0,
        'completedWeeks': 0,
        'totalWeeks': 0,
      };
    }

    final totalDays = _template!.days.length;
    final completedDays = _completedDays.length;
    final remainingDays = totalDays - completedDays;

    // Tamamlanan hafta sayısı (tüm günleri tamamlanmış haftalar)
    final weeks = _template!.days.map((d) => d.weekIndex).toSet().toList()..sort();
    int completedWeeks = 0;
    for (final week in weeks) {
      final weekDays = _template!.days.where((d) => d.weekIndex == week).toList();
      final allCompleted = weekDays.every(
        (d) => _completedDays.contains('${d.weekIndex}_${d.dayIndex}'),
      );
      if (allCompleted && weekDays.isNotEmpty) completedWeeks++;
    }

    return {
      'totalDays': totalDays,
      'completedDays': completedDays,
      'remainingDays': remainingDays,
      'completedWeeks': completedWeeks,
      'totalWeeks': _template!.totalWeeks,
    };
  }

  String _goalLabel(String goal) {
    final value = goal.toLowerCase().trim();
    if (value.contains('weight_loss') || value.contains('kilo')) {
      return 'Kilo verme';
    }
    if (value.contains('muscle_gain') || value.contains('kas')) {
      return 'Kas kazanma';
    }
    if (value.contains('general_fitness') ||
        value.contains('genel') ||
        value.contains('fitness') ||
        value.contains('sağlık')) {
      return 'Genel fitness';
    }
    if (value.contains('mobility') ||
        value.contains('esnek') ||
        value.contains('mobil')) {
      return 'Esneklik / mobilite';
    }
    if (value.contains('performance') ||
        value.contains('performans') ||
        value.contains('dayanıklılık')) {
      return 'Performans';
    }
    return goal;
  }

  String _experienceLabel(String? level) {
    switch (level) {
      case 'beginner':
        return 'Yeni başlıyorum';
      case 'intermediate':
        return 'Orta seviye';
      case 'advanced':
        return 'İleri seviye';
      default:
        return 'Belirtilmedi';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final usersRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final prefsRef = FirebaseFirestore.instance
          .collection('user_preferences')
          .doc(user.uid);

      final results = await Future.wait([usersRef.get(), prefsRef.get()]);
      final userDoc = results[0];
      final prefsDoc = results[1];

      String goal = '';
      List<String> equipment = [];

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        goal = (data['goal'] as String?) ?? '';
        equipment = List<String>.from((data['equipment'] ?? []) as List);
      }

      String? experienceLevel;
      int? weeklyWorkoutTarget;
      int? sessionDurationMin;

      if (prefsDoc.exists && prefsDoc.data() != null) {
        final data = prefsDoc.data()!;
        experienceLevel = data['experienceLevel'] as String?;
        weeklyWorkoutTarget = data['weeklyWorkoutTarget'] as int?;
        sessionDurationMin = data['sessionDurationMin'] as int?;

        // user_preferences içinde daha güncel goal/ekipman varsa onları kullan
        goal = (data['goal'] as String?) ?? goal;
        if (data['availableEquipment'] is List) {
          equipment =
              List<String>.from((data['availableEquipment'] ?? []) as List);
        }
      }

      if (goal.isEmpty) {
        setState(() {
          _template = null;
          _isLoading = false;
        });
        return;
      }

      final template = await _templateService.getBestTemplateForUser(
        goal: goal,
        experienceLevel: experienceLevel,
        weeklyWorkoutTarget: weeklyWorkoutTarget,
        sessionDurationMin: sessionDurationMin,
        availableEquipment: equipment,
      );

      // Program durumunu yükle
      UserProgramState? programState;
      try {
        programState = await _programStateService.getActiveProgram(user.uid);
      } catch (e) {
        // Hata durumunda devam et
      }

      // Eğer program başlatılmamışsa ve template varsa, otomatik başlat
      if (programState == null && template != null) {
        await _programStateService.startProgram(
          userId: user.uid,
          programId: template.id,
        );
        programState = await _programStateService.getActiveProgram(user.uid);
      }

      // Otomatik hafta hesaplama
      int autoWeekIndex = 1;
      if (template != null && programState != null) {
        autoWeekIndex = programState.calculateCurrentWeek(template.totalWeeks);
      }

      // Tamamlanan günleri yükle
      Set<String> completedDays = {};
      if (template != null) {
        final completions = await _completionService.getCompletionsForProgram(
          userId: user.uid,
          programId: template.id,
        );
        completedDays = completions
            .map((c) => '${c.weekIndex}_${c.dayIndex}')
            .toSet();
      }

      setState(() {
        _template = template;
        _programState = programState;
        _selectedWeekIndex = autoWeekIndex; // İlk yüklemede otomatik haftayı seç
        _completedDays = completedDays;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plan yüklenirken hata oluştu: $e'),
          action: SnackBarAction(
            label: 'Tekrar Dene',
            onPressed: _loadPlan,
          ),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Haftalık Planım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlan,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _template == null
              ? _buildEmptyState(context)
              : _buildPlanContent(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Henüz sana uygun bir program bulunamadı.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hedef ve plan ayarlarını gözden geçirip tekrar deneyebilirsin.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/onboarding-plan');
              },
              icon: const Icon(Icons.settings),
              label: const Text('Hedef ve Planı Düzenle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanContent(BuildContext context) {
    final template = _template!;
    final currentWeekIndex = _selectedWeekIndex;

    final currentWeekDays = template.days
        .where((d) => d.weekIndex == currentWeekIndex)
        .toList()
      ..sort((a, b) => a.dayIndex.compareTo(b.dayIndex));

    return RefreshIndicator(
      onRefresh: _loadPlan,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderCard(template, currentWeekIndex),
            const SizedBox(height: 16),
            _buildProgressCard(template, currentWeekIndex),
            const SizedBox(height: 16),
            if (currentWeekDays.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Bu hafta için detaylı gün planı tanımlanmamış.\nYine de haftada ${template.daysPerWeek} gün, yaklaşık ${template.recommendedSessionDurationMin} dk antrenman hedefleyebilirsin.',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              )
            else
              ...currentWeekDays.map(_buildDayCard),
          ],
        ),
      ),
    );
  }

  int _getAutoWeekIndex() {
    if (_template == null || _programState == null) return 1;
    return _programState!.calculateCurrentWeek(_template!.totalWeeks);
  }

  Widget _buildProgressCard(ProgramTemplate template, int currentWeekIndex) {
    final overallProgress = _calculateOverallProgress();
    final weeklyProgress = _calculateWeeklyProgress(currentWeekIndex);
    final stats = _getProgressStats();

    return Card(
      elevation: 2,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Program İlerlemesi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Genel ilerleme
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Genel İlerleme',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: overallProgress,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(overallProgress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$currentWeekIndex. Hafta İlerlemesi',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: weeklyProgress,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.green.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(weeklyProgress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // İstatistikler
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.check_circle,
                  label: 'Tamamlanan',
                  value: '${stats['completedDays']}',
                  color: Colors.green,
                ),
                _buildStatItem(
                  icon: Icons.radio_button_unchecked,
                  label: 'Kalan',
                  value: '${stats['remainingDays']}',
                  color: Colors.orange,
                ),
                _buildStatItem(
                  icon: Icons.calendar_today,
                  label: 'Hafta',
                  value: '${stats['completedWeeks']}/${stats['totalWeeks']}',
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required MaterialColor color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color.shade700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(ProgramTemplate template, int currentWeekIndex) {
    final goalLabel =
        template.goals.isNotEmpty ? _goalLabel(template.goals.first) : '';
    final autoWeekIndex = _getAutoWeekIndex();
    final isAutoWeek = currentWeekIndex == autoWeekIndex;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              template.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              template.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  avatar: const Icon(Icons.flag, size: 16),
                  label: Text(goalLabel.isEmpty ? 'Program' : goalLabel),
                ),
                Chip(
                  avatar: const Icon(Icons.timer, size: 16),
                  label:
                      Text('Haftada ${template.daysPerWeek} gün · ${template.recommendedSessionDurationMin} dk'),
                ),
                Chip(
                  avatar: const Icon(Icons.calendar_today, size: 16),
                  label: Text('${template.totalWeeks} haftalık plan'),
                ),
                if (template.experienceLevels.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.fitness_center, size: 16),
                    label: Text(
                      _experienceLabel(template.experienceLevels.first),
                    ),
                  ),
                // İlerleme chip'i
                Chip(
                  avatar: Icon(
                    Icons.trending_up,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  label: Text(
                    '${(_calculateOverallProgress() * 100).toStringAsFixed(0)}% tamamlandı',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.blue.shade50,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Hafta seçici
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (isAutoWeek)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 14, color: Colors.blue.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Şu an ${autoWeekIndex}. haftadasın',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        '$currentWeekIndex. haftayı görüntülüyorsun',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: currentWeekIndex > 1
                          ? () => setState(() => _selectedWeekIndex = currentWeekIndex - 1)
                          : null,
                      tooltip: 'Önceki hafta',
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$currentWeekIndex / ${template.totalWeeks}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: currentWeekIndex < template.totalWeeks
                          ? () => setState(() => _selectedWeekIndex = currentWeekIndex + 1)
                          : null,
                      tooltip: 'Sonraki hafta',
                    ),
                  ],
                ),
              ],
            ),
            if (!isAutoWeek) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() => _selectedWeekIndex = autoWeekIndex),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Şu anki haftaya dön'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(ProgramDay day) {
    final dayKey = '${day.weekIndex}_${day.dayIndex}';
    final isCompleted = _completedDays.contains(dayKey);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isCompleted ? Colors.green.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (isCompleted)
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade700,
                        size: 20,
                      )
                    else
                      Icon(
                        Icons.radio_button_unchecked,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      '${day.weekIndex}. Hafta - Gün ${day.dayIndex}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.green.shade700 : null,
                      ),
                    ),
                  ],
                ),
                if (day.bodyRegions.isNotEmpty)
                  Text(
                    day.bodyRegions.join(', '),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              day.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (day.description != null && day.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                day.description!,
                style: const TextStyle(fontSize: 13),
              ),
            ],
            if (day.exerciseIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Egzersizler: ${day.exerciseIds.join(', ')}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (isCompleted)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Bu gün tamamlandı',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _completeDay(day),
                  icon: const Icon(Icons.check),
                  label: const Text('Günü Tamamla'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeDay(ProgramDay day) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _template == null) return;

    // Onay dialogu
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Günü Tamamla'),
        content: Text(
          '${day.title} gününü tamamladığını onaylıyor musun?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tamamla'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Loading göster
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // 1. Egzersiz isimlerini al
      List<String> exerciseNames = [];
      if (day.exerciseIds.isNotEmpty) {
        try {
          final exercisesSnapshot = await FirebaseFirestore.instance
              .collection('exercises')
              .where(FieldPath.documentId, whereIn: day.exerciseIds)
              .get();
          
          final exerciseMap = {
            for (var doc in exercisesSnapshot.docs)
              doc.id: Exercise.fromMap(doc.data() as Map<String, dynamic>).name
          };
          
          exerciseNames = day.exerciseIds
              .map((id) => exerciseMap[id] ?? id)
              .toList();
        } catch (e) {
          // Hata durumunda ID'leri kullan
          exerciseNames = day.exerciseIds;
        }
      }

      // 2. Otomatik workout session oluştur
      final workoutId = DateTime.now().millisecondsSinceEpoch.toString();
      final workoutSession = WorkoutSession(
        id: workoutId,
        userId: user.uid,
        date: DateTime.now(),
        exerciseIds: day.exerciseIds,
        exerciseNames: exerciseNames,
        totalDuration: _template!.recommendedSessionDurationMin,
        programId: _template!.id,
        programWeekIndex: day.weekIndex,
        programDayIndex: day.dayIndex,
      );

      await _workoutService.saveWorkoutSession(workoutSession);

      // 3. Program day completion kaydet
      await _completionService.completeProgramDay(
        userId: user.uid,
        programId: _template!.id,
        weekIndex: day.weekIndex,
        dayIndex: day.dayIndex,
        workoutSessionId: workoutId,
      );

      // 4. Gamification: XP ve rozet kontrolü
      try {
        await _gamificationService.onWorkoutCompleted(
          user.uid,
          workoutSession.totalDuration,
        );
        
        // Yeni kazanılan rozetleri kontrol et
        final newBadges = await _gamificationService.checkAndAwardBadges(user.uid);
        if (newBadges.isNotEmpty && mounted) {
          // Rozet kazanıldı bildirimi göster
          _showBadgeEarnedDialog(newBadges);
        }
      } catch (e) {
        // Gamification hataları sessizce geç
      }

      // Loading'i kapat
      if (!mounted) return;
      Navigator.pop(context);

      // State'i güncelle
      setState(() {
        _completedDays.add('${day.weekIndex}_${day.dayIndex}');
      });

      // Başarı mesajı
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gün başarıyla tamamlandı! 🎉'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Loading'i kapat
      if (!mounted) return;
      Navigator.pop(context);

      // Hata mesajı
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showBadgeEarnedDialog(List<models.AchievementBadge> badges) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(badges.first.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Rozet Kazandın!',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: badges.map((badge) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Text(
                    badge.icon,
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    badge.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    badge.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/achievements');
            },
            child: const Text('Rozetlerimi Gör'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}


