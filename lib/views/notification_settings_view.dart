import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_preferences.dart';
import '../services/notification_service.dart';

class NotificationSettingsView extends StatefulWidget {
  const NotificationSettingsView({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsView> createState() => _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;
  bool _isSaving = false;

  NotificationPreferences? _preferences;
  TimeOfDay? _selectedTime;
  Set<int> _selectedDays = {1, 2, 3, 4, 5, 6, 7}; // Varsayılan: Her gün

  final List<String> _dayNames = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final prefs = await _notificationService.getNotificationPreferences(user.uid);
      
      setState(() {
        _preferences = prefs ?? NotificationPreferences(userId: user.uid);
        if (_preferences!.reminderTime != null) {
          final timeParts = _preferences!.reminderTime!.split(':');
          _selectedTime = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );
        } else {
          _selectedTime = const TimeOfDay(hour: 18, minute: 0); // Varsayılan: 18:00
        }
        _selectedDays = _preferences!.reminderDays.toSet();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ayarlar yüklenirken hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final timeString = _selectedTime != null
          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
          : null;

      final updatedPrefs = _preferences!.copyWith(
        reminderTime: timeString,
        reminderDays: _selectedDays.toList()..sort(),
      );

      await _notificationService.saveNotificationPreferences(
        user.uid,
        updatedPrefs,
      );

      setState(() {
        _preferences = updatedPrefs;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bildirim ayarları kaydedildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ayarlar kaydedilemedi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
      await _savePreferences();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _preferences == null
              ? const Center(child: Text('Ayarlar yüklenemedi'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bildirim Türleri',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SwitchListTile(
                                title: const Text('Günlük Hatırlatıcılar'),
                                subtitle: const Text(
                                  'Her gün antrenman yapman için hatırlatma',
                                ),
                                value: _preferences!.dailyRemindersEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    _preferences = _preferences!.copyWith(
                                      dailyRemindersEnabled: value,
                                    );
                                  });
                                  _savePreferences();
                                },
                              ),
                              SwitchListTile(
                                title: const Text('Seri Uyarıları'),
                                subtitle: const Text(
                                  'Serin bozulmasın diye uyarı',
                                ),
                                value: _preferences!.streakWarningsEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    _preferences = _preferences!.copyWith(
                                      streakWarningsEnabled: value,
                                    );
                                  });
                                  _savePreferences();
                                },
                              ),
                              SwitchListTile(
                                title: const Text('Haftalık Özet'),
                                subtitle: const Text(
                                  'Haftalık ilerleme özeti bildirimi',
                                ),
                                value: _preferences!.weeklySummaryEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    _preferences = _preferences!.copyWith(
                                      weeklySummaryEnabled: value,
                                    );
                                  });
                                  _savePreferences();
                                },
                              ),
                              SwitchListTile(
                                title: const Text('Başarı Bildirimleri'),
                                subtitle: const Text(
                                  'Rozet kazandığında bildirim',
                                ),
                                value: _preferences!.achievementNotificationsEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    _preferences = _preferences!.copyWith(
                                      achievementNotificationsEnabled: value,
                                    );
                                  });
                                  _savePreferences();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Test bildirimi butonu
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'Test Bildirimi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Bildirimlerin çalışıp çalışmadığını test et',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    await _notificationService.sendTestNotification();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Test bildirimi gönderildi!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
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
                                  }
                                },
                                icon: const Icon(Icons.notifications_active),
                                label: const Text('Test Bildirimi Gönder'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_preferences!.dailyRemindersEnabled) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hatırlatıcı Zamanı',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  title: const Text('Saat'),
                                  subtitle: Text(
                                    _selectedTime != null
                                        ? _selectedTime!.format(context)
                                        : 'Seçilmedi',
                                  ),
                                  trailing: const Icon(Icons.access_time),
                                  onTap: _selectTime,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Haftanın Günleri',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: List.generate(7, (index) {
                                    final day = index + 1;
                                    final isSelected = _selectedDays.contains(day);
                                    return FilterChip(
                                      label: Text(_dayNames[index]),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            _selectedDays.add(day);
                                          } else {
                                            _selectedDays.remove(day);
                                          }
                                        });
                                        _savePreferences();
                                      },
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

