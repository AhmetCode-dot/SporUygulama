import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/exercise.dart';
import '../services/exercise_recommendation_service.dart';
import '../services/workout_service.dart';
import '../models/workout_session.dart';
import '../models/exercise_detail.dart';
import 'package:video_player/video_player.dart';

class ExerciseRecommendationView extends StatefulWidget {
  const ExerciseRecommendationView({Key? key}) : super(key: key);

  @override
  _ExerciseRecommendationViewState createState() => _ExerciseRecommendationViewState();
}

class _ExerciseRecommendationViewState extends State<ExerciseRecommendationView> {
  final _exerciseService = ExerciseRecommendationService();
  final _workoutService = WorkoutService();
  bool _isLoading = true;
  List<Exercise> _recommendedExercises = [];
  String _selectedGoal = '';
  List<String> _selectedBodyRegions = [];
  List<String> _selectedEquipment = [];
  String _selectedEnvironment = '';
  Set<String> _selectedExerciseIds = {}; // Seçili egzersizler

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _selectedGoal = data['goal'] ?? '';
            _selectedBodyRegions = List<String>.from(data['bodyRegions'] ?? []);
            _selectedEquipment = List<String>.from(data['equipment'] ?? []);
            _selectedEnvironment = data['environment'] ?? '';
          });
          
          await _loadRecommendedExercises();
        }
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
      );
      
      setState(() {
        _recommendedExercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Egzersizler yüklenirken hata oluştu: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kişisel Egzersiz Önerileri'),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                currentAccountPicture: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                accountName: Text(
                  (FirebaseAuth.instance.currentUser?.email ?? '').split('@').first,
                  overflow: TextOverflow.ellipsis,
                ),
                accountEmail: Text(FirebaseAuth.instance.currentUser?.email ?? ''),
                otherAccountsPictures: [
                  if (_selectedGoal.isNotEmpty)
                    const Icon(Icons.flag, color: Colors.white),
                ],
              ),
              if (_selectedGoal.isNotEmpty || _selectedBodyRegions.isNotEmpty)
                ListTile(
                  title: const Text('Özet'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedGoal.isNotEmpty)
                        Text('Hedef: $_selectedGoal'),
                      if (_selectedBodyRegions.isNotEmpty)
                        Text('Bölgeler: ${_selectedBodyRegions.join(', ')}'),
                    ],
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profil'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.fitness_center),
                title: const Text('Ekipman / Ortam'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/equipment');
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag),
                title: const Text('Bölge / Hedef'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/body-region-goal');
                },
              ),
              ListTile(
                leading: const Icon(Icons.trending_up),
                title: const Text('İlerleme Takibi'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/progress');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Çıkış'),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
                },
              ),
            ],
          ),
        ),
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
                    // Özet
                    Container(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            'Hedefiniz: $_selectedGoal',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            'Bölgeler: ${_selectedBodyRegions.join(', ')}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Egzersiz listesi
                    Expanded(
                      child: _recommendedExercises.isEmpty
                          ? const Center(
                              child: Text(
                                'Seçtiğiniz kriterlere uygun egzersiz bulunamadı.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _recommendedExercises.length,
                              itemBuilder: (context, index) {
                                final exercise = _recommendedExercises[index];
                                return _buildExerciseCard(exercise);
                              },
                            ),
                    ),
                    
                    // Butonlar
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: _selectedExerciseIds.isEmpty
                                ? null
                                : _completeWorkout,
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
                            child: Text(
                              _selectedExerciseIds.isEmpty
                                  ? 'Egzersiz Seçin'
                                  : '${_selectedExerciseIds.length} Egzersizi Tamamla',
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
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Checkbox(
          value: _selectedExerciseIds.contains(exercise.id),
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedExerciseIds.add(exercise.id);
              } else {
                _selectedExerciseIds.remove(exercise.id);
              }
            });
          },
        ),
        trailing: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade200,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              exercise.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade300,
                  child: const Icon(
                    Icons.fitness_center,
                    color: Colors.grey,
                    size: 30,
                  ),
                );
              },
            ),
          ),
        ),
        title: Text(
          exercise.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                _buildInfoChip('${exercise.duration} dk', Colors.blue),
                const SizedBox(width: 8),
                _buildInfoChip(exercise.getDifficultyText(), Colors.orange),
                const SizedBox(width: 8),
                _buildInfoChip('${exercise.bodyRegions.length} bölge', Colors.green),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Talimatlar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double side = (MediaQuery.of(context).size.width * 0.28).clamp(90, 220);
                        return SizedBox(
                          width: side,
                          height: side,
                          child: exercise.instructionVideoAsset != null
                              ? InstructionVideoWidget(assetPath: exercise.instructionVideoAsset!)
                              : (exercise.instructionGifUrl != null
                                  ? Image.network(
                                      exercise.instructionGifUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.grey.shade300,
                                        child: const Icon(Icons.fitness_center, size: 40, color: Colors.grey),
                                      ),
                                    )
                                  : (exercise.imageUrl.startsWith('http')
                                      ? Image.network(
                                          exercise.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: Colors.grey.shade300,
                                            child: const Icon(Icons.fitness_center, size: 40, color: Colors.grey),
                                          ),
                                        )
                                      : Image.asset(
                                          exercise.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: Colors.grey.shade300,
                                            child: const Icon(Icons.fitness_center, size: 40, color: Colors.grey),
                                          ),
                                        ))),
                        );
                      },
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          double screenWidth = MediaQuery.of(context).size.width;
                          double fontSizeTitle = (screenWidth * 0.042).clamp(14, 18);
                          double fontSizeBody = (screenWidth * 0.038).clamp(12, 16);
                          double lineHeight = screenWidth > 500 ? 1.7 : 1.5;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nasıl Yapılır:',
                                style: TextStyle(
                                  fontSize: fontSizeTitle,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                exercise.instructions,
                                style: TextStyle(
                                  fontSize: fontSizeBody,
                                  color: Colors.black87,
                                  height: lineHeight,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Faydalar
                const Text(
                  'Faydaları:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: exercise.benefits.map((benefit) => 
                    _buildInfoChip(benefit, Colors.purple)
                  ).toList(),
                ),
                
                const SizedBox(height: 16),
                
                // Uyumlu bölgeler
                const Text(
                  'Çalıştırdığı Bölgeler:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: exercise.bodyRegions.map((region) => 
                    _buildInfoChip(region, Colors.red)
                  ).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

      // Seçimleri temizle
      setState(() {
        _selectedExerciseIds.clear();
        _isLoading = false;
      });

      if (mounted) {
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
}

class InstructionVideoWidget extends StatefulWidget {
  final String assetPath;
  const InstructionVideoWidget({required this.assetPath, Key? key}) : super(key: key);
  @override
  State<InstructionVideoWidget> createState() => _InstructionVideoWidgetState();
}

class _InstructionVideoWidgetState extends State<InstructionVideoWidget> {
  late VideoPlayerController _controller;
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.assetPath)..setLooping(true)..initialize().then((_) {
      setState(() {});
      _controller.play(); // Otomatik başlat
    });
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const SizedBox(width: 90, height: 90, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    return SizedBox(
      width: 90,
      height: 90,
      child: VideoPlayer(_controller),
    );
  }
}
