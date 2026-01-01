import 'package:flutter/material.dart';
import '../../models/workout_session.dart';
import '../../models/exercise_detail.dart';

class AdminWorkoutDetailView extends StatelessWidget {
  final WorkoutSession workout;

  const AdminWorkoutDetailView({Key? key, required this.workout}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDate(workout.date)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Özet kartı
            Card(
              elevation: 4,
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
                          _formatDuration(workout.totalDuration),
                        ),
                        _buildInfoItem(
                          Icons.fitness_center,
                          'Egzersiz',
                          '${workout.exerciseNames.length}',
                        ),
                        if (workout.difficulty != null)
                          _buildInfoItem(
                            Icons.star,
                            'Zorluk',
                            '${workout.difficulty}/5',
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
            ...workout.exerciseNames.asMap().entries.map((entry) {
              final index = entry.key;
              final exerciseName = entry.value;
              final exerciseId = workout.exerciseIds[index];
              final detail = workout.exerciseDetails[exerciseId];

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
            if (workout.difficulty != null) ...[
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final level = index + 1;
                      final hasStar = workout.difficulty != null &&
                          level <= workout.difficulty!;
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
            ],

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
                child: Text(
                  workout.notes ?? 'Not yok',
                  style: TextStyle(
                    color: workout.notes == null
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

