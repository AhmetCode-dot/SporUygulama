import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/admin_service.dart';
import '../../services/storage_service.dart';
import '../../models/exercise.dart';

class AdminExerciseFormView extends StatefulWidget {
  final Exercise? exercise;

  const AdminExerciseFormView({Key? key, this.exercise}) : super(key: key);

  @override
  _AdminExerciseFormViewState createState() => _AdminExerciseFormViewState();
}

class _AdminExerciseFormViewState extends State<AdminExerciseFormView> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();
  final StorageService _storageService = StorageService();
  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _isUploadingVideo = false;
  double _imageUploadProgress = 0.0;
  double _videoUploadProgress = 0.0;

  // Form controllers
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _durationController = TextEditingController();
  int _difficulty = 3;

  // Multi-select lists - Kullanıcıdan alınan değerlerle eşleşmeli
  final List<String> _availableBodyRegions = [
    'Karın',
    'Göğüs',
    'Bacak',
    'Omuz',
    'Sırt',
    'Kol',
    'Tüm vücut',
  ];
  final List<String> _availableGoals = [
    'Kilo vermek',
    'Kas yapmak',
    'Esneklik kazanmak',
    'Sıkılaşmak',
    'Genel sağlık',
  ];
  final List<String> _availableEquipment = [
    'Dumbell',
    'Barfiks Demiri',
    'Egzersiz Bandı',
    'Koşu Bandı',
    'Cable Makine',
    'Vücut Ağırlığı ile Çalışıyorum',
  ];
  final List<String> _availableEnvironments = [
    'Evde çalışıyorum',
    'Spor salonunda çalışıyorum',
    'Hem evde hem salonda',
  ];

  List<String> _selectedBodyRegions = [];
  List<String> _selectedGoals = [];
  List<String> _selectedEquipment = [];
  String _selectedEnvironment = 'Evde çalışıyorum';
  final List<String> _benefits = [];
  final _benefitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.exercise != null) {
      _loadExerciseData();
    } else {
      _idController.text = DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  void _loadExerciseData() {
    final exercise = widget.exercise!;
    _idController.text = exercise.id;
    _nameController.text = exercise.name;
    _descriptionController.text = exercise.description;
    _instructionsController.text = exercise.instructions;
    _imageUrlController.text = exercise.imageUrl;
    _videoUrlController.text = exercise.instructionVideoAsset ?? '';
    _durationController.text = exercise.duration.toString();
    _difficulty = exercise.difficulty;
    _selectedBodyRegions = List.from(exercise.bodyRegions);
    _selectedGoals = List.from(exercise.goals);
    _selectedEquipment = List.from(exercise.equipment);
    _selectedEnvironment = exercise.environments.isNotEmpty ? exercise.environments.first : 'Evde çalışıyorum';
    _benefits.clear();
    _benefits.addAll(exercise.benefits);
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    _durationController.dispose();
    _benefitController.dispose();
    super.dispose();
  }

  Future<void> _uploadImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      // Web için bytes, mobil için path kontrolü
      final hasFile = kIsWeb 
          ? (result != null && result.files.single.bytes != null)
          : (result != null && result.files.single.path != null);
      
      if (hasFile) {
        setState(() {
          _isUploadingImage = true;
          _imageUploadProgress = 0.0;
        });

        final file = result.files.single;
        final exerciseId = _idController.text.trim();
        
        if (exerciseId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Önce egzersiz ID\'sini girin')),
          );
          setState(() => _isUploadingImage = false);
          return;
        }

        // Web için bytes, mobil için path
        if ((kIsWeb && file.bytes != null) || (!kIsWeb && file.path != null)) {
          final downloadUrl = await _storageService.uploadExerciseImage(
            file: kIsWeb ? file.bytes! : file.path!,
            exerciseId: exerciseId,
            onProgress: (progress) {
              setState(() => _imageUploadProgress = progress);
            },
          );
          
          setState(() {
            _imageUrlController.text = downloadUrl;
            _isUploadingImage = false;
            _imageUploadProgress = 0.0;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Görsel başarıyla yüklendi'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Dosya seçilemedi');
        }
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
        _imageUploadProgress = 0.0;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görsel yüklenirken hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      // Web için bytes, mobil için path kontrolü
      final hasFile = kIsWeb 
          ? (result != null && result.files.single.bytes != null)
          : (result != null && result.files.single.path != null);
      
      if (hasFile) {
        setState(() {
          _isUploadingVideo = true;
          _videoUploadProgress = 0.0;
        });

        final file = result.files.single;
        final exerciseId = _idController.text.trim();
        
        if (exerciseId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Önce egzersiz ID\'sini girin')),
          );
          setState(() => _isUploadingVideo = false);
          return;
        }

        // Web için bytes, mobil için path
        if ((kIsWeb && file.bytes != null) || (!kIsWeb && file.path != null)) {
          final downloadUrl = await _storageService.uploadExerciseVideo(
            file: kIsWeb ? file.bytes! : file.path!,
            exerciseId: exerciseId,
            onProgress: (progress) {
              setState(() => _videoUploadProgress = progress);
            },
          );
          
          setState(() {
            _videoUrlController.text = downloadUrl;
            _isUploadingVideo = false;
            _videoUploadProgress = 0.0;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video başarıyla yüklendi'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Dosya seçilemedi');
        }
      }
    } catch (e) {
      setState(() {
        _isUploadingVideo = false;
        _videoUploadProgress = 0.0;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video yüklenirken hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveExercise() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedBodyRegions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('En az bir vücut bölgesi seçmelisiniz')),
        );
        return;
      }
      if (_selectedGoals.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('En az bir hedef seçmelisiniz')),
        );
        return;
      }
      if (_selectedEquipment.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('En az bir ekipman seçmelisiniz')),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        final exercise = Exercise(
          id: _idController.text.trim(),
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          bodyRegions: _selectedBodyRegions,
          goals: _selectedGoals,
          equipment: _selectedEquipment,
          environments: [_selectedEnvironment],
          duration: int.parse(_durationController.text.trim()),
          difficulty: _difficulty,
          instructions: _instructionsController.text.trim(),
          imageUrl: _imageUrlController.text.trim(),
          benefits: _benefits,
          instructionVideoAsset: _videoUrlController.text.trim().isNotEmpty
              ? _videoUrlController.text.trim()
              : null,
        );

        if (widget.exercise == null) {
          await _adminService.addExercise(exercise);
        } else {
          await _adminService.updateExercise(exercise);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.exercise == null ? 'Egzersiz eklendi' : 'Egzersiz güncellendi'),
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Widget _buildMultiSelectChip(
    String label,
    List<String> options,
    List<String> selected,
    Function(List<String>) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    if (!isSelected) {
                      onChanged([...selected, option]);
                    }
                  } else {
                    onChanged(selected.where((s) => s != option).toList());
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise == null ? 'Yeni Egzersiz' : 'Egzersiz Düzenle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'ID',
                  border: OutlineInputBorder(),
                ),
                enabled: widget.exercise == null,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'ID gerekli';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Egzersiz Adı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Egzersiz adı gerekli';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Açıklama gerekli';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Talimatlar',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Talimatlar gerekli';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Görsel URL veya Yükle
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Görsel URL',
                        hintText: 'URL girin veya yükleyin',
                        border: OutlineInputBorder(),
                        helperText: 'Firebase Storage URL, HTTP URL veya asset path',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Görsel URL gerekli';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isUploadingImage ? null : _uploadImage,
                    icon: _isUploadingImage
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: _imageUploadProgress > 0 ? _imageUploadProgress : null,
                            ),
                          )
                        : const Icon(Icons.upload),
                    label: const Text('Yükle'),
                  ),
                ],
              ),
              if (_isUploadingImage && _imageUploadProgress > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(value: _imageUploadProgress),
                ),
              const SizedBox(height: 16),
              // Video URL veya Yükle
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _videoUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Video URL (Opsiyonel)',
                        hintText: 'URL girin veya yükleyin',
                        border: OutlineInputBorder(),
                        helperText: 'Firebase Storage URL, HTTP URL veya asset path',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isUploadingVideo ? null : _uploadVideo,
                    icon: _isUploadingVideo
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: _videoUploadProgress > 0 ? _videoUploadProgress : null,
                            ),
                          )
                        : const Icon(Icons.video_library),
                    label: const Text('Yükle'),
                  ),
                ],
              ),
              if (_isUploadingVideo && _videoUploadProgress > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(value: _videoUploadProgress),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Süre (dakika)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Süre gerekli';
                  if (int.tryParse(value) == null) return 'Geçerli bir sayı girin';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Zorluk seviyesi
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Zorluk Seviyesi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _difficulty.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _getDifficultyText(_difficulty),
                    onChanged: (value) {
                      setState(() => _difficulty = value.toInt());
                    },
                  ),
                  Text(_getDifficultyText(_difficulty)),
                ],
              ),
              const SizedBox(height: 16),
              // Vücut bölgeleri
              _buildMultiSelectChip(
                'Vücut Bölgeleri',
                _availableBodyRegions,
                _selectedBodyRegions,
                (value) => setState(() => _selectedBodyRegions = value),
              ),
              // Hedefler
              _buildMultiSelectChip(
                'Hedefler',
                _availableGoals,
                _selectedGoals,
                (value) => setState(() => _selectedGoals = value),
              ),
              // Ekipman
              _buildMultiSelectChip(
                'Ekipman',
                _availableEquipment,
                _selectedEquipment,
                (value) => setState(() => _selectedEquipment = value),
              ),
              // Ortam
              DropdownButtonFormField<String>(
                value: _selectedEnvironment,
                decoration: const InputDecoration(
                  labelText: 'Ortam',
                  border: OutlineInputBorder(),
                ),
                items: _availableEnvironments.map((env) {
                  return DropdownMenuItem(value: env, child: Text(env));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedEnvironment = value);
                  }
                },
              ),
              const SizedBox(height: 24),
              // Faydalar
              const Text(
                'Faydalar',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _benefitController,
                      decoration: const InputDecoration(
                        hintText: 'Fayda ekle',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      if (_benefitController.text.isNotEmpty) {
                        setState(() {
                          _benefits.add(_benefitController.text);
                          _benefitController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _benefits.map((benefit) {
                  return Chip(
                    label: Text(benefit),
                    onDeleted: () {
                      setState(() => _benefits.remove(benefit));
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              // Kaydet butonu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveExercise,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(widget.exercise == null ? 'Egzersiz Ekle' : 'Egzersiz Güncelle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDifficultyText(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'Başlangıç';
      case 2:
        return 'Kolay';
      case 3:
        return 'Orta';
      case 4:
        return 'Zor';
      case 5:
        return 'İleri';
      default:
        return 'Bilinmiyor';
    }
  }
}

