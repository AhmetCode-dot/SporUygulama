import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/workout_service.dart';
import '../models/workout_session.dart';
import '../models/exercise_detail.dart';
import '../services/user_preferences_service.dart';
import '../services/program_template_service.dart';
import '../services/program_day_completion_service.dart';
import '../services/user_program_state_service.dart';
import '../models/program_template.dart';
import '../services/gamification_service.dart';
import '../models/user_level.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;

class ProgressView extends StatefulWidget {
  final bool hideAppBar;
  
  const ProgressView({
    Key? key,
    this.hideAppBar = false,
  }) : super(key: key);

  @override
  State<ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView> {
  final WorkoutService _workoutService = WorkoutService();
  final UserPreferencesService _preferencesService = UserPreferencesService();
  final ProgramTemplateService _templateService = ProgramTemplateService();
  final ProgramDayCompletionService _completionService = ProgramDayCompletionService();
  final UserProgramStateService _programStateService = UserProgramStateService();
  final GamificationService _gamificationService = GamificationService();
  bool _isLoading = true;
  
  int _totalWorkouts = 0;
  int _streak = 0;
  int _totalDuration = 0;
  int _thisWeekCount = 0;
  int _thisMonthActiveDays = 0;
  bool _hasWorkoutToday = false;
  List<bool> _last7DaysStatus = [];
  List<WorkoutSession> _recentWorkouts = [];
  int _weeklyGoal = 3; // Varsayılan haftalık hedef
  
  // Program ilerlemesi
  ProgramTemplate? _activeProgram;
  Set<String> _completedProgramDays = {};
  
  // Gamification
  UserLevel? _userLevel;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Haftalık hedefi yükle
      await _loadWeeklyGoal(user.uid);

      final totalWorkouts = await _workoutService.getTotalWorkoutCount(user.uid);
      final streak = await _workoutService.calculateStreak(user.uid);
      final totalDuration = await _workoutService.getTotalWorkoutDuration(user.uid);
      final thisWeekCount = await _workoutService.getThisWeekWorkoutCount(user.uid);
      final thisMonthActiveDays = await _workoutService.getThisMonthActiveDays(user.uid);
      final hasWorkoutToday = await _workoutService.hasWorkoutToday(user.uid);
      final last7DaysStatus = await _workoutService.getLast7DaysStatus(user.uid);
      final recentWorkouts = await _workoutService.getRecentWorkouts(user.uid, 30);

      // Program ilerlemesini yükle
      await _loadProgramProgress(user.uid);

      // Seviye bilgisini yükle
      final level = await _gamificationService.getUserLevel(user.uid);

      setState(() {
        _totalWorkouts = totalWorkouts;
        _streak = streak;
        _totalDuration = totalDuration;
        _thisWeekCount = thisWeekCount;
        _thisMonthActiveDays = thisMonthActiveDays;
        _hasWorkoutToday = hasWorkoutToday;
        _last7DaysStatus = last7DaysStatus;
        _recentWorkouts = recentWorkouts;
        _userLevel = level;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İlerleme yüklenirken hata: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Tekrar Dene',
              textColor: Colors.white,
              onPressed: _loadProgress,
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadProgramProgress(String userId) async {
    try {
      final programState = await _programStateService.getActiveProgram(userId);
      if (programState == null) return;

      final template = await _templateService.getAllTemplates();
      final activeTemplate = template.firstWhere(
        (t) => t.id == programState.programId,
        orElse: () => template.isNotEmpty ? template.first : throw Exception('Template bulunamadı'),
      );

      final completions = await _completionService.getCompletionsForProgram(
        userId: userId,
        programId: programState.programId,
      );

      setState(() {
        _activeProgram = activeTemplate;
        _completedProgramDays = completions
            .map((c) => '${c.weekIndex}_${c.dayIndex}')
            .toSet();
      });
    } catch (e) {
      // Program yoksa veya hata varsa sessizce devam et
    }
  }

  double _calculateProgramProgress() {
    if (_activeProgram == null || _activeProgram!.days.isEmpty) return 0.0;
    final totalDays = _activeProgram!.days.length;
    final completedDays = _completedProgramDays.length;
    return (completedDays / totalDays).clamp(0.0, 1.0);
  }

  Future<void> _loadWeeklyGoal(String userId) async {
    try {
      // Önce user_preferences koleksiyonundan haftalık hedefi oku
      final prefs = await _preferencesService.getPreferences(userId);
      if (prefs != null && prefs.weeklyWorkoutTarget > 0) {
        setState(() {
          _weeklyGoal = prefs.weeklyWorkoutTarget;
        });
        return;
      }

      // Geriye dönük uyumluluk: users koleksiyonundaki weeklyGoal alanını oku
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final data = doc.data();
      if (doc.exists && data != null && data['weeklyGoal'] != null) {
        setState(() {
          _weeklyGoal = data['weeklyGoal'] as int;
        });
      }
    } catch (e) {
      // Varsayılan değer kullanılacak
    }
  }

  Future<void> _setWeeklyGoal(int goal) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Eski alan: users.weeklyGoal (geri uyumluluk için)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'weeklyGoal': goal}, SetOptions(merge: true));

      // Yeni plan: user_preferences.weeklyWorkoutTarget
      await FirebaseFirestore.instance
          .collection('user_preferences')
          .doc(user.uid)
          .set({'weeklyWorkoutTarget': goal}, SetOptions(merge: true));

      setState(() {
        _weeklyGoal = goal;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Haftalık hedef $goal gün olarak ayarlandı')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hedef kaydedilemedi: ${e.toString()}')),
        );
      }
    }
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes dk';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '$hours saat';
    }
    return '$hours saat $mins dk';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final workoutDate = DateTime(date.year, date.month, date.day);
    
    if (workoutDate.isAtSameMomentAs(today)) {
      return 'Bugün';
    } else if (workoutDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      return 'Dün';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  String _getDayName(int daysAgo) {
    final now = DateTime.now();
    final date = now.subtract(Duration(days: daysAgo));
    final weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return weekdays[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.hideAppBar ? null : AppBar(
        title: const Text('İlerleme Takibi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, '/notification-settings');
            },
            tooltip: 'Bildirim Ayarları',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProgress,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProgress,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  // 1. BUGÜNÜN DURUMU (Büyük Kart)
                  _buildTodayStatusCard(),
                  const SizedBox(height: 16),

                  // Seviye Kartı
                  if (_userLevel != null) ...[
                    _buildLevelCard(_userLevel!),
                    const SizedBox(height: 16),
                  ],

                  // Program İlerlemesi (varsa)
                  if (_activeProgram != null) ...[
                    _buildProgramProgressCard(),
                    const SizedBox(height: 16),
                  ],

                  // 2. HAFTALIK ÖZET (7 Gün)
                  _buildWeeklySummary(),
                  const SizedBox(height: 16),

                  // 3. İSTATİSTİKLER
                  _buildStatsSection(),
                  const SizedBox(height: 16),

                  // 4. AYLIK TAKVİM
                  _buildMonthlyCalendar(),
                  const SizedBox(height: 16),

                  // 5. SON ANTRENMANLAR
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.history,
                          color: Colors.indigo.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Son Antrenmanlar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildRecentWorkoutsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTodayStatusCard() {
    final isDark = AppTheme.isDarkMode(context);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _hasWorkoutToday
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (_hasWorkoutToday ? Colors.green : Colors.orange).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Animasyonlu ikon container
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 3,
                ),
              ),
              child: Icon(
                _hasWorkoutToday ? Icons.check_circle : Icons.fitness_center,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _hasWorkoutToday ? 'Bugün Antrenman Yaptınız!' : 'Bugün Antrenman Yapmadınız',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _hasWorkoutToday
                  ? 'Harika iş çıkardınız! 🎉'
                  : 'Hadi bugün bir antrenman yapalım! 💪',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            if (!_hasWorkoutToday) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/home');
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Antrenman Başlat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.orange.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      onPressed: () => _addWorkoutForToday(),
                      icon: const Icon(Icons.add_task, color: Colors.white),
                      tooltip: 'Manuel Kaydet',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySummary() {
    final weekProgress = _last7DaysStatus.where((status) => status).length;
    final progressPercent = _weeklyGoal > 0 ? (weekProgress / _weeklyGoal).clamp(0.0, 1.0) : 0.0;
    final remaining = _weeklyGoal > 0 ? (_weeklyGoal - weekProgress).clamp(0, _weeklyGoal) : 0;
    final isDark = AppTheme.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Bu Hafta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _showWeeklyGoalDialog(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.flag, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Hedef: $_weeklyGoal',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Circular progress + Günler
          Row(
            children: [
              // Circular Progress Ring
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: progressPercent,
                        strokeWidth: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressPercent >= 1.0 ? Colors.green : Colors.blue,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$weekProgress',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '/$_weeklyGoal gün',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              
              // Haftalık günler
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(7, (index) {
                        final daysAgo = 6 - index;
                        final hasWorkout = index < _last7DaysStatus.length ? _last7DaysStatus[index] : false;
                        final isToday = daysAgo == 0;
                        
                        return Column(
                          children: [
                            Text(
                              _getDayName(daysAgo),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                color: isToday ? Colors.blue : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: hasWorkout
                                    ? LinearGradient(
                                        colors: [Colors.green.shade400, Colors.green.shade600],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: hasWorkout ? null : Colors.grey.shade200,
                                border: isToday
                                    ? Border.all(color: Colors.blue, width: 2)
                                    : null,
                                boxShadow: hasWorkout
                                    ? [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                hasWorkout ? Icons.check : Icons.remove,
                                color: hasWorkout ? Colors.white : Colors.grey.shade400,
                                size: 16,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Durum mesajı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: progressPercent >= 1.0
                  ? Colors.green.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  progressPercent >= 1.0 ? Icons.celebration : Icons.trending_up,
                  size: 18,
                  color: progressPercent >= 1.0 ? Colors.green : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  progressPercent >= 1.0
                      ? 'Haftalık hedefinize ulaştınız! 🎉'
                      : 'Hedefe $remaining gün kaldı',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: progressPercent >= 1.0 ? Colors.green.shade700 : Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final isDark = AppTheme.isDarkMode(context);
    final totalHours = _totalDuration ~/ 60;
    final totalMinutes = _totalDuration % 60;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildModernStatCard(
                title: 'Toplam Antrenman',
                value: '$_totalWorkouts',
                icon: Icons.fitness_center,
                gradient: [Colors.blue.shade400, Colors.blue.shade600],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernStatCard(
                title: 'Seri',
                value: '$_streak gün',
                icon: Icons.local_fire_department,
                gradient: [Colors.orange.shade400, Colors.orange.shade600],
                isHighlighted: _streak >= 3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildModernStatCard(
                title: 'Bu Ay',
                value: '$_thisMonthActiveDays gün',
                icon: Icons.calendar_month,
                gradient: [Colors.purple.shade400, Colors.purple.shade600],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernStatCard(
                title: 'Toplam Süre',
                value: totalHours > 0 ? '${totalHours}s ${totalMinutes}dk' : '$_totalDuration dk',
                icon: Icons.timer,
                gradient: [Colors.teal.shade400, Colors.teal.shade600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernStatCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradient,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              if (isHighlighted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '🔥',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyCalendar() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;
    final isDark = AppTheme.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_month,
                  color: Colors.purple.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_getMonthName(now.month)} ${now.year}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_thisMonthActiveDays aktif gün',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Hafta günleri başlıkları
          Row(
            children: ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: day == 'Cmt' || day == 'Paz'
                                ? Colors.red.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
          
          // Takvim günleri
          ...List.generate((daysInMonth + firstWeekday - 1) ~/ 7 + 1, (weekIndex) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: List.generate(7, (dayIndex) {
                  final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 2;
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const Expanded(child: SizedBox());
                  }

                  final date = DateTime(now.year, now.month, dayNumber);
                  final hasWorkout = _workoutService.hasWorkoutOnDate(_recentWorkouts, date);
                  final isToday = date.year == now.year &&
                      date.month == now.month &&
                      date.day == now.day;
                  final isPast = date.isBefore(DateTime(now.year, now.month, now.day));

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (!hasWorkout && isPast) {
                          _showAddWorkoutDialog(date);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: hasWorkout
                              ? LinearGradient(
                                  colors: [Colors.green.shade400, Colors.green.shade600],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: hasWorkout
                              ? null
                              : isToday
                                  ? Colors.blue.shade50
                                  : Colors.transparent,
                          border: isToday
                              ? Border.all(color: Colors.blue, width: 2)
                              : null,
                          boxShadow: hasWorkout
                              ? [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$dayNumber',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isToday || hasWorkout ? FontWeight.bold : FontWeight.normal,
                              color: hasWorkout
                                  ? Colors.white
                                  : isToday
                                      ? Colors.blue
                                      : isPast
                                          ? Colors.grey.shade700
                                          : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
          const SizedBox(height: 12),
          
          // Açıklama
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCalendarLegend(
                gradient: [Colors.green.shade400, Colors.green.shade600],
                label: 'Antrenman',
              ),
              const SizedBox(width: 16),
              _buildCalendarLegend(
                color: Colors.blue.shade50,
                borderColor: Colors.blue,
                label: 'Bugün',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarLegend({
    List<Color>? gradient,
    Color? color,
    Color? borderColor,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: gradient != null
                ? LinearGradient(colors: gradient)
                : null,
            color: color,
            border: borderColor != null ? Border.all(color: borderColor, width: 1.5) : null,
          ),
        ),
        const SizedBox(width: 6),
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

  Widget _buildRecentWorkoutsList() {
    final isDark = AppTheme.isDarkMode(context);
    
    if (_recentWorkouts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.fitness_center, size: 40, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            const Text(
              'Henüz antrenman kaydınız yok',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Egzersiz önerilerinden antrenman tamamlayarak başlayın!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/home'),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Antrenman Başlat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentWorkouts.length > 10 ? 10 : _recentWorkouts.length,
      itemBuilder: (context, index) {
        final workout = _recentWorkouts[index];
        return _buildWorkoutCard(workout, index);
      },
    );
  }

  Widget _buildWorkoutCard(WorkoutSession workout, int index) {
    final isDark = AppTheme.isDarkMode(context);
    final isToday = _isToday(workout.date);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/workout-detail',
              arguments: workout,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Tarih göstergesi
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isToday
                          ? [Colors.green.shade400, Colors.green.shade600]
                          : [Colors.blue.shade400, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (isToday ? Colors.green : Colors.blue).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        workout.date.day.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _getShortMonthName(workout.date.month),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                
                // Antrenman bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isToday ? 'Bugün' : _formatDate(workout.date),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'YENİ',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildWorkoutInfoChip(
                            icon: Icons.fitness_center,
                            label: '${workout.exerciseNames.length} egzersiz',
                            color: Colors.purple,
                          ),
                          const SizedBox(width: 8),
                          _buildWorkoutInfoChip(
                            icon: Icons.timer,
                            label: _formatDuration(workout.totalDuration),
                            color: Colors.teal,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Ok
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _getShortMonthName(int month) {
    const months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return months[month - 1];
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramProgressCard() {
    if (_activeProgram == null) return const SizedBox.shrink();

    final progress = _calculateProgramProgress();
    final totalDays = _activeProgram!.days.length;
    final completedDays = _completedProgramDays.length;
    final remainingDays = totalDays - completedDays;

    return Card(
      elevation: 3,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _activeProgram!.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      Text(
                        'Program İlerlemesi',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProgramStatItem(
                  icon: Icons.check_circle,
                  label: 'Tamamlanan',
                  value: '$completedDays',
                  color: Colors.green,
                ),
                _buildProgramStatItem(
                  icon: Icons.radio_button_unchecked,
                  label: 'Kalan',
                  value: '$remainingDays',
                  color: Colors.orange,
                ),
                _buildProgramStatItem(
                  icon: Icons.calendar_today,
                  label: 'Toplam',
                  value: '$totalDays',
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard(UserLevel level) {
    return Card(
      elevation: 3,
      color: Colors.amber.shade50,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/achievements'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.star, color: Colors.amber.shade700, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seviye ${level.level}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${level.totalXP} XP',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: level.progressPercentage,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${level.currentLevelXP} / ${level.xpForNextLevel} XP',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgramStatItem({
    required IconData icon,
    required String label,
    required String value,
    required MaterialColor color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color.shade700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  void _showWeeklyGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Haftalık Hedef'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Haftada kaç gün antrenman yapmak istiyorsunuz?'),
            const SizedBox(height: 16),
            ...List.generate(7, (index) {
              final goal = index + 1;
              return RadioListTile<int>(
                title: Text('$goal gün'),
                value: goal,
                groupValue: _weeklyGoal,
                onChanged: (value) {
                  if (value != null) {
                    Navigator.pop(context);
                    _setWeeklyGoal(value);
                  }
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return months[month - 1];
  }

  Future<void> _addWorkoutForToday() async {
    final today = DateTime.now();
    await _addWorkoutForDate(today);
  }

  Future<void> _addWorkoutForDate(DateTime date) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${date.day}.${date.month}.${date.year}'),
        content: const Text(
          'Bu güne antrenman eklemek istediğinizi onaylıyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Evet, Ekle'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Basit bir antrenman kaydı oluştur
      final session = WorkoutSession(
        id: '${date.millisecondsSinceEpoch}_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.uid,
        date: date,
        exerciseIds: ['manual'],
        exerciseNames: ['Manuel antrenman'],
        totalDuration: 30, // Varsayılan süre
        exerciseDetails: {
          'manual': ExerciseDetail(
            sets: 1,
            reps: 1,
          ),
        },
      );

      await _workoutService.saveWorkoutSession(session);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${date.day}.${date.month}.${date.year} tarihine antrenman eklendi'),
            backgroundColor: Colors.green,
          ),
        );
        // Verileri yenile
        _loadProgress();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Antrenman eklenemedi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddWorkoutDialog(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    
    // Gelecek tarihlere antrenman eklenemez
    if (targetDate.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gelecek tarihlere antrenman eklenemez'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _addWorkoutForDate(date);
  }
}
