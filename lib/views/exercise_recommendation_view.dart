import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/exercise.dart';
import '../services/exercise_recommendation_service.dart';
import '../services/workout_service.dart';
import '../models/workout_session.dart';
import '../models/exercise_detail.dart';
import '../services/gamification_service.dart';
import '../models/badge.dart' as models;
import '../widgets/exercise_media_widget.dart';
import '../widgets/smart_image_widget.dart';
import 'active_workout_view.dart';

class ExerciseRecommendationView extends StatefulWidget {
  final bool hideAppBar;
  
  const ExerciseRecommendationView({
    Key? key,
    this.hideAppBar = false,
  }) : super(key: key);

  @override
  _ExerciseRecommendationViewState createState() => _ExerciseRecommendationViewState();
}

class _ExerciseRecommendationViewState extends State<ExerciseRecommendationView> {
  final _exerciseService = ExerciseRecommendationService();
  final _workoutService = WorkoutService();
  final _gamificationService = GamificationService();
  bool _isLoading = true;
  List<Exercise> _recommendedExercises = [];
  String _selectedGoal = '';
  String _experienceLevel = '';
  List<String> _selectedBodyRegions = [];
  List<String> _selectedEquipment = [];
  String _selectedEnvironment = '';
  int? _weeklyWorkoutTarget;
  int? _sessionDurationMin;
  List<String> _preferredBodyRegions = [];
  Set<String> _selectedExerciseIds = {}; // Seçili egzersizler

  String? _experienceLevelLabel() {
    switch (_experienceLevel) {
      case 'beginner':
        return 'Yeni başlıyorum';
      case 'intermediate':
        return 'Bir süredir yapıyorum';
      case 'advanced':
        return 'Uzun süredir düzenli yapıyorum';
      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final usersRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        final prefsRef = FirebaseFirestore.instance
            .collection('user_preferences')
            .doc(user.uid);

        final results = await Future.wait([usersRef.get(), prefsRef.get()]);
        final userDoc = results[0];
        final prefsDoc = results[1];

        String goal = '';
        List<String> bodyRegions = [];
        List<String> equipment = [];
        String environment = '';

        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          goal = (data['goal'] as String?) ?? '';
          bodyRegions = List<String>.from((data['bodyRegions'] ?? []) as List);
          equipment = List<String>.from((data['equipment'] ?? []) as List);
          environment = (data['environment'] as String?) ?? '';
        }

        String experienceLevel = '';
        int? weeklyWorkoutTarget;
        int? sessionDurationMin;
        List<String> preferredBodyRegions = [];

        if (prefsDoc.exists && prefsDoc.data() != null) {
          final data = prefsDoc.data()!;
          experienceLevel = (data['experienceLevel'] as String?) ?? '';
          weeklyWorkoutTarget = data['weeklyWorkoutTarget'] as int?;
          sessionDurationMin = data['sessionDurationMin'] as int?;

          preferredBodyRegions =
              List<String>.from((data['preferredBodyRegions'] ?? []) as List);

          // Eğer user_preferences içinde daha güncel goal / environment / equipment varsa kullan
          goal = (data['goal'] as String?) ?? goal;
          environment =
              (data['preferredEnvironment'] as String?) ?? environment;
          if (data['availableEquipment'] is List) {
            equipment =
                List<String>.from((data['availableEquipment'] ?? []) as List);
          }
        }

        // Eğer preferredBodyRegions boşsa, bodyRegions ile doldur (geri uyumluluk)
        if (preferredBodyRegions.isEmpty && bodyRegions.isNotEmpty) {
          preferredBodyRegions = List<String>.from(bodyRegions);
        }

        setState(() {
          _selectedGoal = goal;
          _selectedBodyRegions = bodyRegions;
          _selectedEquipment = equipment;
          _selectedEnvironment = environment;
          _experienceLevel = experienceLevel;
          _weeklyWorkoutTarget = weeklyWorkoutTarget;
          _sessionDurationMin = sessionDurationMin;
          _preferredBodyRegions = preferredBodyRegions;
        });

        await _loadRecommendedExercises();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tercihler yüklenirken hata oluştu: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadRecommendedExercises() async {
    setState(() => _isLoading = true);
    try {
      final exercises = await _exerciseService.getRecommendedExercises(
        bodyRegions: _selectedBodyRegions,
        goal: _selectedGoal,
        equipment: _selectedEquipment,
        environment: _selectedEnvironment,
        experienceLevel:
            _experienceLevel.isEmpty ? null : _experienceLevel,
        sessionDurationMin: _sessionDurationMin,
        preferredBodyRegions:
            _preferredBodyRegions.isEmpty ? null : _preferredBodyRegions,
      );
      
      setState(() {
        _recommendedExercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Egzersizler yüklenirken hata oluştu: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Tekrar Dene',
              textColor: Colors.white,
              onPressed: _loadRecommendedExercises,
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
      );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.hideAppBar ? null : AppBar(
        title: const Text('Kişisel Egzersiz Önerileri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecommendedExercises,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/fitness_bg.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Column(
                  children: [
                    // Özet Kartı - Modern Tasarım
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hedef başlığı
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.flag,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Hedefiniz',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white60,
                                      ),
                                    ),
                                    Text(
                                      _selectedGoal.isNotEmpty ? _selectedGoal : 'Belirtilmedi',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // İstatistik chip'leri
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (_experienceLevelLabel() != null)
                                _buildSummaryChip(
                                  icon: Icons.trending_up,
                                  label: _experienceLevelLabel()!,
                                  color: Colors.orange,
                                ),
                              if (_weeklyWorkoutTarget != null)
                                _buildSummaryChip(
                                  icon: Icons.calendar_today,
                                  label: 'Haftalık $_weeklyWorkoutTarget gün',
                                  color: Colors.green,
                                ),
                              if (_sessionDurationMin != null)
                                _buildSummaryChip(
                                  icon: Icons.timer,
                                  label: '$_sessionDurationMin dk',
                                  color: Colors.purple,
                                ),
                            ],
                          ),
                          
                          // Bölgeler
                          if (_selectedBodyRegions.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _selectedBodyRegions.map((region) => 
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Text(
                                    region,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Egzersiz listesi
                    Expanded(
                      child: _recommendedExercises.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.fitness_center,
                                    size: 64,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                'Seçtiğiniz kriterlere uygun egzersiz bulunamadı.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/body-region-goal');
                                    },
                                    child: const Text(
                                      'Bölge ve Hedef Seçimini Güncelle',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadRecommendedExercises,
                              child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _recommendedExercises.length,
                              itemBuilder: (context, index) {
                                final exercise = _recommendedExercises[index];
                                return _buildExerciseCard(exercise);
                              },
                              ),
                            ),
                    ),
                    
                    // Butonlar
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _selectedExerciseIds.isEmpty
                                ? null
                                : _startWorkout,
                            icon: const Icon(Icons.play_arrow),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              minimumSize: const Size(double.infinity, 55),
                              elevation: 5,
                            ),
                            label: Text(
                              _selectedExerciseIds.isEmpty
                                  ? 'Egzersiz Seçin'
                                  : '${_selectedExerciseIds.length} Egzersiz ile Başla',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _loadRecommendedExercises,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              minimumSize: const Size(double.infinity, 55),
                            ),
                            child: const Text(
                              'Yenile',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    final isSelected = _selectedExerciseIds.contains(exercise.id);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSelected
              ? [Colors.blue.shade50, Colors.blue.shade100]
              : [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.blue.shade400 : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected 
                ? Colors.blue.withOpacity(0.2)
                : Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: EdgeInsets.zero,
          leading: GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedExerciseIds.remove(exercise.id);
                } else {
                  _selectedExerciseIds.add(exercise.id);
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          ),
          title: Row(
            children: [
              // Egzersiz Resmi
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SmartImageWidget(
                    imageUrl: exercise.imageUrl,
                    fit: BoxFit.cover,
                    width: 70,
                    height: 70,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Egzersiz Bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.blue.shade800 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Info Badges
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildMiniChip(
                          icon: Icons.timer_outlined,
                          label: '${exercise.duration} dk',
                          color: Colors.blue,
                        ),
                        _buildMiniChip(
                          icon: Icons.speed,
                          label: exercise.getDifficultyText(),
                          color: _getDifficultyColor(exercise.difficulty),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey.shade500,
          ),
          children: [
            // Detay Bölümü
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video/Resim ve Talimatlar
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Media Widget
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final double side = (MediaQuery.of(context).size.width * 0.28).clamp(100.0, 180.0);
                              return SizedBox(
                                width: side,
                                height: side,
                                child: ExerciseMediaWidget(
                                  exercise: exercise,
                                  width: side,
                                  height: side,
                                  fit: BoxFit.cover,
                                  autoPlayVideo: true,
                                  loopingVideo: true,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Talimatlar
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.play_circle_outline,
                                    color: Colors.blue.shade700,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Nasıl Yapılır',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              exercise.instructions,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Faydalar
                  _buildDetailSection(
                    icon: Icons.favorite_outline,
                    iconColor: Colors.purple,
                    title: 'Faydaları',
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: exercise.benefits.map((benefit) => 
                        _buildDetailChip(benefit, Colors.purple)
                      ).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Çalıştırdığı Bölgeler
                  _buildDetailSection(
                    icon: Icons.accessibility_new,
                    iconColor: Colors.red,
                    title: 'Çalıştırdığı Bölgeler',
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: exercise.bodyRegions.map((region) => 
                        _buildDetailChip(region, Colors.red)
                      ).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChip({
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

  Widget _buildDetailSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildDetailChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _startWorkout() async {
    if (_selectedExerciseIds.isEmpty) return;

    // Seçili egzersizleri al
    final selectedExercises = _recommendedExercises
        .where((e) => _selectedExerciseIds.contains(e.id))
        .toList();

    if (selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seçili egzersiz bulunamadı')),
      );
      return;
    }

    // ActiveWorkoutView'a yönlendir
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveWorkoutView(exercises: selectedExercises),
      ),
    );

    // Antrenman tamamlandıysa seçimleri temizle ve listeyi yenile
    if (result == true && mounted) {
      setState(() {
        _selectedExerciseIds.clear();
      });
      _loadRecommendedExercises();
    }
  }

  Future<void> _completeWorkout() async {
    if (_selectedExerciseIds.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen giriş yapın')),
        );
      }
      return;
    }

    // Seçili egzersizleri bul
    final selectedExercises = _recommendedExercises
        .where((e) => _selectedExerciseIds.contains(e.id))
        .toList();

    if (selectedExercises.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seçili egzersiz bulunamadı')),
        );
      }
      return;
    }

    // Toplam süreyi hesapla
    final totalDuration = selectedExercises.fold<int>(
      0,
      (sum, exercise) => sum + exercise.duration,
    );

    // Onay ekranını göster (set/tekrar ve ağırlık girişi ile)
    final result = await _showWorkoutConfirmationDialog(
      selectedExercises,
      totalDuration,
    );

    if (result == null) return; // Kullanıcı iptal etti

    final exerciseDetails = result['exerciseDetails'] as Map<String, ExerciseDetail>;
    final notes = result['notes'] as String?;
    final difficulty = result['difficulty'] as int?;

    setState(() => _isLoading = true);

    try {
      // Workout session oluştur
      final session = WorkoutSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        date: DateTime.now(),
        exerciseIds: selectedExercises.map((e) => e.id).toList(),
        exerciseNames: selectedExercises.map((e) => e.name).toList(),
        totalDuration: totalDuration,
        notes: notes,
        difficulty: difficulty,
        exerciseDetails: exerciseDetails,
      );

      await _workoutService.saveWorkoutSession(session);

      // Gamification: XP ve rozet kontrolü
      List<models.AchievementBadge> newBadges = [];
      try {
        await _gamificationService.onWorkoutCompleted(
          user.uid,
          totalDuration,
        );
        
        // Yeni kazanılan rozetleri kontrol et
        newBadges = await _gamificationService.checkAndAwardBadges(user.uid);
      } catch (e) {
        // Gamification hataları sessizce geç
        debugPrint('Gamification error: $e');
      }

      // Seçimleri temizle
      setState(() {
        _selectedExerciseIds.clear();
        _isLoading = false;
      });

      if (mounted) {
        // Rozet kazanıldıysa önce onu göster
        if (newBadges.isNotEmpty) {
          _showBadgeEarnedDialog(newBadges);
        } else {
          // Normal başarı mesajı
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tebrikler! ${selectedExercises.length} egzersiz tamamlandı.',
              ),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'İlerleme',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pushNamed(context, '/progress');
                },
              ),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      setState(() => _isLoading = false);
      if (mounted) {
        // Hata mesajını daha detaylı göster
        final errorMessage = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Antrenman kaydedilemedi: $errorMessage'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
        // Debug için console'a yazdır
        debugPrint('Workout save error: $errorMessage');
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  Future<Map<String, dynamic>?> _showWorkoutConfirmationDialog(
    List<Exercise> exercises,
    int totalDuration,
  ) async {
    final exerciseDetails = <String, ExerciseDetail>{};
    final notesController = TextEditingController();
    int? selectedDifficulty;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Antrenman Detayları'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Toplam süre: ${_formatDuration(totalDuration)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Her egzersiz için set/tekrar/ağırlık
                  ...exercises.map((exercise) {
                    final detail = exerciseDetails[exercise.id] ?? ExerciseDetail(
                      sets: 3,
                      reps: 10,
                    );
                    if (!exerciseDetails.containsKey(exercise.id)) {
                      exerciseDetails[exercise.id] = detail;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      labelText: 'Set',
                                      isDense: true,
                                    ),
                                    keyboardType: TextInputType.number,
                                    controller: TextEditingController(
                                      text: detail.sets.toString(),
                                    ),
                                    onChanged: (value) {
                                      final sets = int.tryParse(value) ?? 3;
                                      exerciseDetails[exercise.id] = ExerciseDetail(
                                        sets: sets,
                                        reps: detail.reps,
                                        weight: detail.weight,
                                        notes: detail.notes,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      labelText: 'Tekrar',
                                      isDense: true,
                                    ),
                                    keyboardType: TextInputType.number,
                                    controller: TextEditingController(
                                      text: detail.reps.toString(),
                                    ),
                                    onChanged: (value) {
                                      final reps = int.tryParse(value) ?? 10;
                                      exerciseDetails[exercise.id] = ExerciseDetail(
                                        sets: detail.sets,
                                        reps: reps,
                                        weight: detail.weight,
                                        notes: detail.notes,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      labelText: 'Ağırlık (kg)',
                                      isDense: true,
                                      hintText: 'Opsiyonel',
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    controller: TextEditingController(
                                      text: detail.weight?.toString() ?? '',
                                    ),
                                    onChanged: (value) {
                                      final weight = double.tryParse(value);
                                      exerciseDetails[exercise.id] = ExerciseDetail(
                                        sets: detail.sets,
                                        reps: detail.reps,
                                        weight: weight,
                                        notes: detail.notes,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  // Zorluk seviyesi
                  const Text(
                    'Zorluk Seviyesi:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      final level = index + 1;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDifficulty = level;
                          });
                        },
                        child: Icon(
                          selectedDifficulty != null && level <= selectedDifficulty!
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.orange,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  // Notlar
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notlar (Opsiyonel)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'exerciseDetails': exerciseDetails,
                    'notes': notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                    'difficulty': selectedDifficulty,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );

    return result;
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

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSummaryChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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

