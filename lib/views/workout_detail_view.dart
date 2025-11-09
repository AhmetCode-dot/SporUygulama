import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_session.dart';
import '../models/exercise_detail.dart';
import '../services/workout_service.dart';

class WorkoutDetailView extends StatefulWidget {
  final WorkoutSession workout;

  const WorkoutDetailView({Key? key, required this.workout}) : super(key: key);

  @override
  State<WorkoutDetailView> createState() => _WorkoutDetailViewState();
}

class _WorkoutDetailViewState extends State<WorkoutDetailView> {
  final WorkoutService _workoutService = WorkoutService();
  late WorkoutSession _workout;
  bool _isEditing = false;
  bool _isSaving = false;
  
  final TextEditingController _notesController = TextEditingController();
  int? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _workout = widget.workout;
    _notesController.text = _workout.notes ?? '';
    _selectedDifficulty = _workout.difficulty;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
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

  Future<void> _saveWorkout() async {
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final updatedWorkout = WorkoutSession(
        id: _workout.id,
        userId: _workout.userId,
        date: _workout.date,
        exerciseIds: _workout.exerciseIds,
        exerciseNames: _workout.exerciseNames,
        totalDuration: _workout.totalDuration,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        difficulty: _selectedDifficulty,
        exerciseDetails: _workout.exerciseDetails,
      );

      await _workoutService.saveWorkoutSession(updatedWorkout);

      setState(() {
        _workout = updatedWorkout;
        _isEditing = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Antrenman güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Güncelleme hatası: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDate(_workout.date)),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() => _isEditing = true);
              },
            )
          else
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveWorkout,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Özet kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoItem(
                          Icons.timer,
                          'Süre',
                          _formatDuration(_workout.totalDuration),
                        ),
                        _buildInfoItem(
                          Icons.fitness_center,
                          'Egzersiz',
                          '${_workout.exerciseNames.length}',
                        ),
                        if (_workout.difficulty != null)
                          _buildInfoItem(
                            Icons.star,
                            'Zorluk',
                            '${_workout.difficulty}/5',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Egzersizler
            const Text(
              'Egzersizler',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._workout.exerciseNames.asMap().entries.map((entry) {
              final index = entry.key;
              final exerciseName = entry.value;
              final exerciseId = _workout.exerciseIds[index];
              final detail = _workout.exerciseDetails[exerciseId];

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    exerciseName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: detail != null
                      ? Text(detail.getDisplayText())
                      : const Text('Detay yok'),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Zorluk seviyesi
            const Text(
              'Zorluk Seviyesi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isEditing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(5, (index) {
                          final level = index + 1;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDifficulty = level;
                              });
                            },
                            child: Icon(
                              _selectedDifficulty != null && level <= _selectedDifficulty!
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.orange,
                              size: 40,
                            ),
                          );
                        }),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final level = index + 1;
                          final hasStar = _workout.difficulty != null &&
                              level <= _workout.difficulty!;
                          return Icon(
                            hasStar ? Icons.star : Icons.star_border,
                            color: Colors.orange,
                            size: 32,
                          );
                        }),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Notlar
            const Text(
              'Notlar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isEditing
                    ? TextField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          hintText: 'Notlarınızı buraya yazın...',
                          border: InputBorder.none,
                        ),
                        maxLines: 5,
                      )
                    : Text(
                        _workout.notes ?? 'Not yok',
                        style: TextStyle(
                          color: _workout.notes == null
                              ? Colors.grey
                              : Colors.black87,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

