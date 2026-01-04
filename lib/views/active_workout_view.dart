import 'package:flutter/material.dart';
import 'dart:async';
import '../models/exercise.dart';
import '../models/workout_session.dart';
import '../models/exercise_detail.dart';
import '../services/workout_service.dart';
import '../services/gamification_service.dart';
import '../models/badge.dart' as models;
import '../widgets/exercise_media_widget.dart';
import '../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActiveWorkoutView extends StatefulWidget {
  final List<Exercise> exercises;

  const ActiveWorkoutView({
    Key? key,
    required this.exercises,
  }) : super(key: key);

  @override
  State<ActiveWorkoutView> createState() => _ActiveWorkoutViewState();
}

class _ActiveWorkoutViewState extends State<ActiveWorkoutView>
    with TickerProviderStateMixin {
  final WorkoutService _workoutService = WorkoutService();
  final GamificationService _gamificationService = GamificationService();
  
  int _currentExerciseIndex = 0;
  Set<int> _completedExercises = {};
  bool _isResting = false;
  int _restSeconds = 30;
  Timer? _restTimer;
  
  // Toplam süre takibi
  late DateTime _workoutStartTime;
  Timer? _durationTimer;
  int _totalSeconds = 0;
  
  // Animasyonlar
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _workoutStartTime = DateTime.now();
    _startDurationTimer();
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _durationTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _totalSeconds++;
      });
    });
  }

  void _startRestTimer() {
    setState(() {
      _isResting = true;
      _restSeconds = 30;
    });
    
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _restSeconds--;
        if (_restSeconds <= 0) {
          _isResting = false;
          timer.cancel();
          _goToNextExercise();
        }
      });
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
    });
    _goToNextExercise();
  }

  void _markExerciseComplete() {
    setState(() {
      _completedExercises.add(_currentExerciseIndex);
    });
    
    // Tüm egzersizler tamamlandı mı?
    if (_completedExercises.length == widget.exercises.length) {
      _finishWorkout();
    } else {
      _startRestTimer();
    }
  }

  void _goToNextExercise() {
    if (_currentExerciseIndex < widget.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
      });
      _progressController.forward(from: 0);
    }
  }

  void _goToPreviousExercise() {
    if (_currentExerciseIndex > 0) {
      setState(() {
        _currentExerciseIndex--;
      });
      _progressController.forward(from: 0);
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _finishWorkout() async {
    _durationTimer?.cancel();
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final totalDuration = (_totalSeconds / 60).ceil();
    
    final exerciseDetails = <String, ExerciseDetail>{};
    for (final exercise in widget.exercises) {
      exerciseDetails[exercise.id] = ExerciseDetail(
        sets: 3,
        reps: 12,
        notes: 'Tamamlandı',
      );
    }

    final workout = WorkoutSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.uid,
      date: DateTime.now(),
      exerciseIds: widget.exercises.map((e) => e.id).toList(),
      exerciseNames: widget.exercises.map((e) => e.name).toList(),
      totalDuration: totalDuration,
      exerciseDetails: exerciseDetails,
    );

    await _workoutService.saveWorkoutSession(workout);
    
    // Gamification kontrolü
    final earnedBadges = await _gamificationService.checkAndAwardBadges(user.uid);

    if (!mounted) return;

    // Başarı dialogu göster
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildCompletionDialog(totalDuration, earnedBadges),
    );

    if (!mounted) return;
    Navigator.pop(context, true); // true = antrenman tamamlandı
  }

  Widget _buildCompletionDialog(int duration, List<models.AchievementBadge> badges) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.successGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.celebration,
              color: Colors.white,
              size: 50,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Tebrikler!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Antrenmanı tamamladın!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                icon: Icons.fitness_center,
                value: '${widget.exercises.length}',
                label: 'Egzersiz',
              ),
              _buildStatItem(
                icon: Icons.timer,
                value: '$duration dk',
                label: 'Süre',
              ),
            ],
          ),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            Text(
              '🏆 Yeni Rozet${badges.length > 1 ? 'ler' : ''}!',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...badges.map((badge) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(badge.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(badge.name),
                ],
              ),
            )),
          ],
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Tamam',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercises[_currentExerciseIndex];
    final progress = (_currentExerciseIndex + 1) / widget.exercises.length;
    final completedCount = _completedExercises.length;
    
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Antrenmanı iptal et?'),
            content: const Text('Antrenman kaydedilmeyecek. Çıkmak istediğinize emin misiniz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Devam Et'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Çık', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () async {
              final shouldPop = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Antrenmanı iptal et?'),
                  content: const Text('Antrenman kaydedilmeyecek.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Devam Et'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Çık', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (shouldPop == true && mounted) {
                Navigator.pop(context, false);
              }
            },
          ),
          title: Column(
            children: [
              Text(
                '${_currentExerciseIndex + 1} / ${widget.exercises.length}',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatDuration(_totalSeconds),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: _isResting ? _buildRestScreen() : _buildExerciseScreen(exercise, progress),
      ),
    );
  }

  Widget _buildRestScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Dinlenme',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$_restSeconds',
                style: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Sonraki: ${widget.exercises[_currentExerciseIndex + 1 < widget.exercises.length ? _currentExerciseIndex + 1 : _currentExerciseIndex].name}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _skipRest,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Atla',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseScreen(Exercise exercise, double progress) {
    return Column(
      children: [
        // İlerleme çubuğu
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade500),
            ),
          ),
        ),
        const SizedBox(height: 10),
        
        // Egzersiz içeriği
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Egzersiz başlığı
                Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Süre ve zorluk
                Row(
                  children: [
                    _buildExerciseChip(
                      icon: Icons.timer,
                      label: '${exercise.duration} dk',
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 10),
                    _buildExerciseChip(
                      icon: Icons.speed,
                      label: exercise.getDifficultyText(),
                      color: _getDifficultyColor(exercise.difficulty),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Video/Resim
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: ExerciseMediaWidget(
                      exercise: exercise,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                      autoPlayVideo: true,
                      loopingVideo: true,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Talimatlar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                              Icons.play_circle_outline,
                              color: Colors.blue.shade700,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Nasıl Yapılır',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        exercise.instructions,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Alt butonlar
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              if (_currentExerciseIndex > 0)
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: _goToPreviousExercise,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Icon(Icons.arrow_back),
                  ),
                ),
              if (_currentExerciseIndex > 0) const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: _completedExercises.contains(_currentExerciseIndex)
                      ? (_currentExerciseIndex < widget.exercises.length - 1 ? _goToNextExercise : null)
                      : _markExerciseComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _completedExercises.contains(_currentExerciseIndex)
                        ? Colors.grey
                        : Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _completedExercises.contains(_currentExerciseIndex)
                        ? (_currentExerciseIndex < widget.exercises.length - 1 ? 'Sonraki' : 'Tamamlandı')
                        : (_completedExercises.length == widget.exercises.length - 1
                            ? 'Antrenmanı Bitir'
                            : 'Tamamla'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
