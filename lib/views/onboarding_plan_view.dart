import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_preferences.dart';
import '../services/user_preferences_service.dart';

class OnboardingPlanView extends StatefulWidget {
  const OnboardingPlanView({Key? key}) : super(key: key);

  @override
  State<OnboardingPlanView> createState() => _OnboardingPlanViewState();
}

class _OnboardingPlanViewState extends State<OnboardingPlanView> {
  final _formKey = GlobalKey<FormState>();
  final _preferencesService = UserPreferencesService();

  bool _isSaving = false;

  // Deneyim seviyesi (UI metni -> Firestore değeri eşlemesi)
  final Map<String, String> _experienceLevelOptions = const {
    'Yeni başlıyorum': 'beginner',
    'Bir süredir yapıyorum': 'intermediate',
    'Uzun süredir düzenli yapıyorum': 'advanced',
  };

  late String _selectedExperienceLabel;

  double _weeklyWorkoutTarget = 3; // 1-7 arası
  int _sessionDurationMin = 30; // dakikalar

  @override
  void initState() {
    super.initState();
    _selectedExperienceLabel = _experienceLevelOptions.keys.first;
    _loadExistingPlan();
  }

  Future<void> _loadExistingPlan() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final existing = await _preferencesService.getPreferences(user.uid);
      if (existing == null) return;

      // Firestore'daki deneyim seviyesini ekrandaki label ile eşle
      final valueToLabel = <String, String>{
        for (final entry in _experienceLevelOptions.entries) entry.value: entry.key,
      };
      final label =
          valueToLabel[existing.experienceLevel] ?? _experienceLevelOptions.keys.first;

      setState(() {
        _selectedExperienceLabel = label;
        // Haftalık hedef 1-7 arasında olmalı, aksi halde varsayılan 3
        final clampedTarget = existing.weeklyWorkoutTarget.clamp(1, 7);
        _weeklyWorkoutTarget = clampedTarget is int
            ? clampedTarget.toDouble()
            : (clampedTarget as num).toDouble();
        // Geçerli bir süre geldiyse onu kullan
        if (existing.sessionDurationMin > 0) {
          _sessionDurationMin = existing.sessionDurationMin;
        }
      });
    } catch (_) {
      // Prefill isteğe bağlı; hata olursa sessiz devam et
    }
  }

  Future<void> _savePlan() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen tekrar giriş yapın.')),
        );
        return;
      }

      // Kullanıcının mevcut tercihlerini users koleksiyonundan al
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? <String, dynamic>{};

      final String goal = (userData['goal'] as String?) ?? '';
      final String preferredEnvironment =
          (userData['environment'] as String?) ?? '';

      final List<String> availableEquipment;
      final equipmentRaw = userData['equipment'];
      if (equipmentRaw is List) {
        availableEquipment = List<String>.from(equipmentRaw);
      } else {
        availableEquipment = <String>[];
      }

      final List<String> preferredBodyRegions;
      final bodyRegionsRaw = userData['bodyRegions'];
      if (bodyRegionsRaw is List) {
        preferredBodyRegions = List<String>.from(bodyRegionsRaw);
      } else {
        preferredBodyRegions = <String>[];
      }

      final List<String> limitations;
      final limitationsRaw = userData['limitations'];
      if (limitationsRaw is List) {
        limitations = List<String>.from(limitationsRaw);
      } else {
        limitations = <String>[];
      }

      final experienceLevel =
          _experienceLevelOptions[_selectedExperienceLabel] ?? 'beginner';

      final prefs = UserPreferences(
        userId: user.uid,
        goal: goal,
        experienceLevel: experienceLevel,
        weeklyWorkoutTarget: _weeklyWorkoutTarget.toInt(),
        sessionDurationMin: _sessionDurationMin,
        preferredEnvironment: preferredEnvironment,
        availableEquipment: availableEquipment,
        preferredBodyRegions: preferredBodyRegions,
        limitations: limitations,
      );

      await _preferencesService.savePreferences(prefs);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hedef ve planın kaydedildi')),
      );

      Navigator.pushReplacementNamed(
        context,
        '/exercise-recommendations',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plan kaydedilirken hata oluştu: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('fitness_bg.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    // Logo
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.flag,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Başlık
                    const Text(
                      'Hedef ve Plan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.lightBlue,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            offset: Offset(2, 2),
                            blurRadius: 4,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Deneyim Seviyesi
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text(
                        'Spor Deneyiminiz',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: _experienceLevelOptions.keys.map((label) {
                          return RadioListTile<String>(
                            title: Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            value: label,
                            groupValue: _selectedExperienceLabel,
                            activeColor: Colors.lightBlue,
                            onChanged: (String? value) {
                              if (value == null) return;
                              setState(() {
                                _selectedExperienceLabel = value;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Haftalık Hedef
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text(
                        'Haftalık Hedef',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Haftada ${_weeklyWorkoutTarget.toInt()} gün antrenman yapmak istiyorum',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Slider(
                      value: _weeklyWorkoutTarget,
                      min: 1,
                      max: 7,
                      divisions: 6,
                      label: _weeklyWorkoutTarget.toInt().toString(),
                      activeColor: Colors.lightBlue,
                      inactiveColor: Colors.white24,
                      onChanged: (value) {
                        setState(() {
                          _weeklyWorkoutTarget = value;
                        });
                      },
                    ),

                    const SizedBox(height: 40),

                    // Seans Süresi
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text(
                        'Seans Süresi',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonFormField<int>(
                        value: _sessionDurationMin,
                        dropdownColor: Colors.black87,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          labelText: 'Bir antrenmana ayırabileceğiniz süre',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        style: const TextStyle(color: Colors.white),
                        items: const [15, 30, 45, 60].map((minutes) {
                          return DropdownMenuItem<int>(
                            value: minutes,
                            child: Text('$minutes dakika'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _sessionDurationMin = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Kaydet butonu
                    ElevatedButton(
                      onPressed: _isSaving ? null : _savePlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.lightBlue.shade900,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        minimumSize: const Size(double.infinity, 55),
                        elevation: 5,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.lightBlue,
                                ),
                              ),
                            )
                          : const Text(
                              'Kaydet ve Devam Et',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


