import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/program_template.dart';
import '../../models/exercise.dart';

class AdminProgramTemplateFormView extends StatefulWidget {
  final ProgramTemplate? template;

  const AdminProgramTemplateFormView({Key? key, this.template})
      : super(key: key);

  @override
  State<AdminProgramTemplateFormView> createState() =>
      _AdminProgramTemplateFormViewState();
}

class _AdminProgramTemplateFormViewState
    extends State<AdminProgramTemplateFormView> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();
  bool _isLoading = false;

  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _totalWeeksController = TextEditingController(text: '4');
  final _daysPerWeekController = TextEditingController(text: '3');
  final _sessionDurationController = TextEditingController(text: '30');

  List<ProgramDay> _days = [];
  List<Exercise> _availableExercises = [];
  bool _isLoadingExercises = false;

  // Çoklu seçim seçenekleri
  final Map<String, String> _goalOptions = const {
    'Kilo verme': 'weight_loss',
    'Kas kazanma': 'muscle_gain',
    'Genel fitness': 'general_fitness',
    'Esneklik / mobilite': 'mobility',
    'Performans': 'performance',
  };

  final Map<String, String> _experienceOptions = const {
    'Başlangıç': 'beginner',
    'Orta seviye': 'intermediate',
    'İleri seviye': 'advanced',
  };

  final List<String> _availableBodyRegions = const [
    'Karın',
    'Göğüs',
    'Bacak',
    'Omuz',
    'Sırt',
    'Kol',
    'Tüm vücut',
  ];

  final List<String> _availableEquipment = const [
    'Dumbell',
    'Barfiks Demiri',
    'Egzersiz Bandı',
    'Koşu Bandı',
    'Cable Makine',
    'Vücut Ağırlığı ile Çalışıyorum',
  ];

  final List<String> _selectedGoalCodes = [];
  final List<String> _selectedExperienceLevels = [];
  final List<String> _selectedFocusBodyRegions = [];
  final List<String> _selectedRequiredEquipment = [];

  @override
  void initState() {
    super.initState();
    _loadExercises();
    if (widget.template != null) {
      _loadTemplateData();
    } else {
      _idController.text = DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoadingExercises = true);
    try {
      final exercises = await _adminService.getAllExercises();
      if (mounted) {
        setState(() {
          _availableExercises = exercises;
          _isLoadingExercises = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingExercises = false);
      }
    }
  }

  void _loadTemplateData() {
    final template = widget.template!;
    _idController.text = template.id;
    _nameController.text = template.name;
    _descriptionController.text = template.description;
    _totalWeeksController.text = template.totalWeeks.toString();
    _daysPerWeekController.text = template.daysPerWeek.toString();
    _sessionDurationController.text =
        template.recommendedSessionDurationMin.toString();

    _selectedGoalCodes.clear();
    _selectedGoalCodes.addAll(template.goals);

    _selectedExperienceLevels.clear();
    _selectedExperienceLevels.addAll(template.experienceLevels);

    _selectedFocusBodyRegions.clear();
    _selectedFocusBodyRegions.addAll(template.focusBodyRegions);

    _selectedRequiredEquipment.clear();
    _selectedRequiredEquipment.addAll(template.requiredEquipment);

    _days.clear();
    _days.addAll(template.days);
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _totalWeeksController.dispose();
    _daysPerWeekController.dispose();
    _sessionDurationController.dispose();
    super.dispose();
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGoalCodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir hedef seçmelisiniz')),
      );
      return;
    }
    if (_selectedExperienceLevels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir seviye seçmelisiniz')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final template = ProgramTemplate(
        id: _idController.text.trim(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        goals: List<String>.from(_selectedGoalCodes),
        experienceLevels: List<String>.from(_selectedExperienceLevels),
        totalWeeks: int.parse(_totalWeeksController.text.trim()),
        daysPerWeek: int.parse(_daysPerWeekController.text.trim()),
        recommendedSessionDurationMin:
            int.parse(_sessionDurationController.text.trim()),
        focusBodyRegions: List<String>.from(_selectedFocusBodyRegions),
        requiredEquipment: List<String>.from(_selectedRequiredEquipment),
        days: List<ProgramDay>.from(_days),
      );

      if (widget.template == null) {
        await _adminService.addProgramTemplate(template);
      } else {
        await _adminService.updateProgramTemplate(template);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.template == null
              ? 'Program şablonu eklendi'
              : 'Program şablonu güncellendi'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildMultiSelectChips({
    required String label,
    required List<String> options,
    required List<String> selected,
    required void Function(List<String>) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
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
                    onChanged(
                      selected.where((s) => s != option).toList(),
                    );
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

  Widget _buildDaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Gün Detayları',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddDayDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Gün Ekle'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_days.isEmpty)
          Card(
            color: Colors.grey.shade100,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Henüz gün eklenmedi. "Gün Ekle" butonuna tıklayarak gün detaylarını ekleyebilirsiniz.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          )
        else
          ..._days.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  'Hafta ${day.weekIndex} - Gün ${day.dayIndex}: ${day.title}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  day.description ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditDayDialog(index),
                      tooltip: 'Düzenle',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteDay(index),
                      tooltip: 'Sil',
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Future<void> _showAddDayDialog() async {
    await _showDayDialog();
  }

  Future<void> _showEditDayDialog(int index) async {
    await _showDayDialog(day: _days[index], index: index);
  }

  Future<void> _showDayDialog({ProgramDay? day, int? index}) async {
    final weekController = TextEditingController(
      text: day?.weekIndex.toString() ?? '1',
    );
    final dayIndexController = TextEditingController(
      text: day?.dayIndex.toString() ?? '1',
    );
    final titleController = TextEditingController(text: day?.title ?? '');
    final descriptionController = TextEditingController(
      text: day?.description ?? '',
    );
    final selectedBodyRegions = List<String>.from(day?.bodyRegions ?? []);
    final selectedExerciseIds = List<String>.from(day?.exerciseIds ?? []);
    
    // Dialog içinde kullanılacak arama ve filtreleme için
    final exerciseSearchController = TextEditingController();
    String? selectedFilterBodyRegion;

    final result = await showDialog<ProgramDay?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          // Filtrelenmiş egzersizler
          final filteredExercises = _availableExercises.where((exercise) {
            final searchQuery = exerciseSearchController.text.toLowerCase();
            final matchesSearch = searchQuery.isEmpty ||
                exercise.name.toLowerCase().contains(searchQuery) ||
                exercise.bodyRegions.any((region) =>
                    region.toLowerCase().contains(searchQuery));
            
            final matchesFilter = selectedFilterBodyRegion == null ||
                exercise.bodyRegions.contains(selectedFilterBodyRegion);
            
            return matchesSearch && matchesFilter;
          }).toList();
          
          return AlertDialog(
            title: Text(day == null ? 'Yeni Gün Ekle' : 'Günü Düzenle'),
            content: SingleChildScrollView(
              child: Form(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: weekController,
                          decoration: const InputDecoration(
                            labelText: 'Hafta',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: dayIndexController,
                          decoration: const InputDecoration(
                            labelText: 'Gün Sırası',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Başlık',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama (Opsiyonel)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Vücut Bölgeleri',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableBodyRegions.map((region) {
                      final isSelected = selectedBodyRegions.contains(region);
                      return FilterChip(
                        label: Text(region),
                        selected: isSelected,
                        onSelected: (value) {
                          setDialogState(() {
                            if (value) {
                              if (!isSelected) {
                                selectedBodyRegions.add(region);
                              }
                            } else {
                              selectedBodyRegions.remove(region);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Egzersizler',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (selectedExerciseIds.isNotEmpty)
                        Chip(
                          label: Text('${selectedExerciseIds.length} seçili'),
                          backgroundColor: Colors.blue.shade100,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Arama kutusu
                  TextField(
                    controller: exerciseSearchController,
                    decoration: InputDecoration(
                      hintText: 'Egzersiz ara...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: exerciseSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                exerciseSearchController.clear();
                                setDialogState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    onChanged: (value) {
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  // Vücut bölgesi filtresi
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('Tümü'),
                          selected: selectedFilterBodyRegion == null,
                          onSelected: (selected) {
                            setDialogState(() {
                              selectedFilterBodyRegion = null;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ..._availableBodyRegions.map((region) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(region),
                              selected: selectedFilterBodyRegion == region,
                              onSelected: (selected) {
                                setDialogState(() {
                                  selectedFilterBodyRegion =
                                      selected ? region : null;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isLoadingExercises)
                    const Center(child: CircularProgressIndicator())
                  else if (filteredExercises.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Egzersiz bulunamadı',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Container(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: filteredExercises.map((exercise) {
                            final isSelected =
                                selectedExerciseIds.contains(exercise.id);
                            return CheckboxListTile(
                              title: Text(exercise.name),
                              subtitle: Text(
                                exercise.bodyRegions.join(', '),
                                style: const TextStyle(fontSize: 12),
                              ),
                              value: isSelected,
                              dense: true,
                              onChanged: (value) {
                                setDialogState(() {
                                  if (value == true) {
                                    if (!isSelected) {
                                      selectedExerciseIds.add(exercise.id);
                                    }
                                  } else {
                                    selectedExerciseIds.remove(exercise.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                String? validationError;
                
                if (titleController.text.trim().isEmpty) {
                  validationError = 'Başlık gerekli';
                } else if (selectedBodyRegions.isEmpty) {
                  validationError = 'En az bir vücut bölgesi seçmelisiniz';
                } else if (selectedExerciseIds.isEmpty) {
                  validationError = 'En az bir egzersiz seçmelisiniz';
                }

                if (validationError != null) {
                  setDialogState(() {
                    // errorMessage'ı state'e kaydetmek için bir değişken kullanıyoruz
                    // Ama bu yaklaşım çalışmayacak, daha iyi bir yöntem kullanalım
                  });
                  // Hata mesajını direkt gösterelim
                  showDialog(
                    context: dialogContext,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Hata'),
                      content: Text(validationError!),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Tamam'),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                final weekIndex = int.tryParse(weekController.text.trim()) ?? 1;
                final dayIndex = int.tryParse(dayIndexController.text.trim()) ?? 1;

                final newDay = ProgramDay(
                  weekIndex: weekIndex,
                  dayIndex: dayIndex,
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  bodyRegions: selectedBodyRegions,
                  exerciseIds: selectedExerciseIds,
                );

                Navigator.pop(dialogContext, newDay);
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
        },
      ),
    );

    if (result != null) {
      setState(() {
        if (index != null) {
          _days[index] = result;
        } else {
          _days.add(result);
        }
        // Hafta ve gün sırasına göre sırala
        _days.sort((a, b) {
          final weekCompare = a.weekIndex.compareTo(b.weekIndex);
          if (weekCompare != 0) return weekCompare;
          return a.dayIndex.compareTo(b.dayIndex);
        });
      });
    }
  }

  void _deleteDay(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Günü Sil'),
        content: Text(
          '"${_days[index].title}" gününü silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _days.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.template == null ? 'Yeni Program Şablonu' : 'Program Şablonu Düzenle',
        ),
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
                enabled: widget.template == null,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'ID gerekli';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Program Adı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Program adı gerekli';
                  }
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
                  if (value == null || value.isEmpty) {
                    return 'Açıklama gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildMultiSelectChips(
                label: 'Hedef(ler)',
                options: _goalOptions.keys.toList(),
                selected: _selectedGoalCodes
                    .map((code) => _goalOptions.entries
                        .firstWhere(
                          (entry) => entry.value == code,
                          orElse: () => const MapEntry('?', ''),
                        )
                        .key)
                    .where((k) => k != '?')
                    .toList(),
                onChanged: (labels) {
                  _selectedGoalCodes
                    ..clear()
                    ..addAll(labels.map((label) => _goalOptions[label]!).toList());
                },
              ),
              _buildMultiSelectChips(
                label: 'Seviye(ler)',
                options: _experienceOptions.keys.toList(),
                selected: _selectedExperienceLevels
                    .map((code) => _experienceOptions.entries
                        .firstWhere(
                          (entry) => entry.value == code,
                          orElse: () => const MapEntry('?', ''),
                        )
                        .key)
                    .where((k) => k != '?')
                    .toList(),
                onChanged: (labels) {
                  _selectedExperienceLevels
                    ..clear()
                    ..addAll(
                      labels.map((label) => _experienceOptions[label]!).toList(),
                    );
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _totalWeeksController,
                      decoration: const InputDecoration(
                        labelText: 'Toplam Hafta',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Toplam hafta gerekli';
                        }
                        final v = int.tryParse(value);
                        if (v == null || v <= 0 || v > 52) {
                          return 'Geçerli bir hafta sayısı girin';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _daysPerWeekController,
                      decoration: const InputDecoration(
                        labelText: 'Haftalık Gün',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Haftalık gün sayısı gerekli';
                        }
                        final v = int.tryParse(value);
                        if (v == null || v <= 0 || v > 7) {
                          return '1-7 arasında bir değer girin';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sessionDurationController,
                decoration: const InputDecoration(
                  labelText: 'Önerilen Seans Süresi (dk)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Seans süresi gerekli';
                  }
                  final v = int.tryParse(value);
                  if (v == null || v <= 0 || v > 180) {
                    return 'Geçerli bir süre girin (1-180 dk)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildMultiSelectChips(
                label: 'Odak Bölgeler',
                options: _availableBodyRegions,
                selected: _selectedFocusBodyRegions,
                onChanged: (values) {
                  _selectedFocusBodyRegions
                    ..clear()
                    ..addAll(values);
                },
              ),
              _buildMultiSelectChips(
                label: 'Gereken Ekipman',
                options: _availableEquipment,
                selected: _selectedRequiredEquipment,
                onChanged: (values) {
                  _selectedRequiredEquipment
                    ..clear()
                    ..addAll(values);
                },
              ),
              const SizedBox(height: 24),
              // Gün Detayları Bölümü
              _buildDaysSection(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTemplate,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Kaydet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


