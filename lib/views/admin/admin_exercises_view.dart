import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/exercise_recommendation_service.dart';
import '../../models/exercise.dart';
import 'admin_exercise_form_view.dart';

class AdminExercisesView extends StatefulWidget {
  const AdminExercisesView({Key? key}) : super(key: key);

  @override
  _AdminExercisesViewState createState() => _AdminExercisesViewState();
}

class _AdminExercisesViewState extends State<AdminExercisesView> {
  final AdminService _adminService = AdminService();
  final ExerciseRecommendationService _exerciseService = ExerciseRecommendationService();
  List<Exercise> _exercises = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isLoadingDefaults = false;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    try {
      final exercises = await _adminService.getAllExercises();
      if (mounted) {
        setState(() {
          _exercises = exercises;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Load exercises error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Tekrar Dene',
              textColor: Colors.white,
              onPressed: _loadExercises,
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadDefaultExercises() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Varsayılan Egzersizleri Yükle'),
        content: const Text(
          'Tüm varsayılan egzersizler Firestore\'a yüklenecek. '
          'Mevcut egzersizler üzerine yazılacak. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yükle'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoadingDefaults = true);
      try {
        await _exerciseService.saveExercisesToFirestore();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Varsayılan egzersizler başarıyla yüklendi'),
              backgroundColor: Colors.green,
            ),
          );
          _loadExercises(); // Listeyi yenile
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoadingDefaults = false);
        }
      }
    }
  }

  Future<void> _deleteExercise(Exercise exercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Egzersizi Sil'),
        content: Text('${exercise.name} egzersizini silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteExercise(exercise.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Egzersiz silindi')),
          );
          _loadExercises();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: ${e.toString()}')),
          );
        }
      }
    }
  }

  List<Exercise> get _filteredExercises {
    if (_searchQuery.isEmpty) return _exercises;
    return _exercises.where((exercise) {
      final name = exercise.name.toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Arama ve butonlar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Egzersiz ara...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminExerciseFormView(),
                        ),
                      );
                      if (result == true) {
                        _loadExercises();
                      }
                    },
                    child: const Icon(Icons.add),
                    tooltip: 'Yeni Egzersiz Ekle',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoadingDefaults ? null : _loadDefaultExercises,
                  icon: _isLoadingDefaults
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_download),
                  label: const Text('Varsayılan Egzersizleri Yükle'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Egzersiz listesi
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredExercises.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fitness_center_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Henüz egzersiz yok'
                                : 'Arama sonucu bulunamadı',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _loadDefaultExercises,
                              icon: const Icon(Icons.cloud_download),
                              label: const Text('Varsayılan Egzersizleri Yükle'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadExercises,
                      child: ListView.builder(
                        itemCount: _filteredExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _filteredExercises[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: const Icon(
                                  Icons.fitness_center,
                                  color: Colors.blue,
                                ),
                              ),
                              title: Text(
                                exercise.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Süre: ${exercise.duration} dakika'),
                                  Text('Zorluk: ${exercise.getDifficultyText()}'),
                                  Text('Vücut Bölgeleri: ${exercise.bodyRegions.join(", ")}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AdminExerciseFormView(exercise: exercise),
                                        ),
                                      );
                                      if (result == true) {
                                        _loadExercises();
                                      }
                                    },
                                    tooltip: 'Düzenle',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteExercise(exercise),
                                    tooltip: 'Sil',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

