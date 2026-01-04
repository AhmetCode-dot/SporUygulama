import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../main.dart' show themeNotifier;
import 'exercise_recommendation_view.dart';
import 'progress_view.dart';
import 'weekly_plan_view.dart';
import 'notification_settings_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainNavigationView extends StatefulWidget {
  const MainNavigationView({Key? key}) : super(key: key);

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  final List<Widget> _screens = [
    const ExerciseRecommendationView(hideAppBar: true),
    const ProgressView(hideAppBar: true),
    const WeeklyPlanView(hideAppBar: true),
    const SettingsScreen(),
  ];

  final List<String> _titles = [
    'Egzersiz Önerileri',
    'İlerleme',
    'Haftalık Plan',
    'Ayarlar',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);
    
    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _titles[_currentIndex],
            key: ValueKey<String>(_titles[_currentIndex]),
          ),
        ),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // Refresh egzersizler
              },
              tooltip: 'Yenile',
            ),
          if (_currentIndex == 1)
            IconButton(
              icon: const Icon(Icons.emoji_events),
              onPressed: () {
                Navigator.pushNamed(context, '/achievements');
              },
              tooltip: 'Başarılar',
            ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            selectedItemColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
            unselectedItemColor: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: [
              _buildNavItem(Icons.fitness_center_outlined, Icons.fitness_center, 'Öneriler', 0),
              _buildNavItem(Icons.trending_up_outlined, Icons.trending_up, 'İlerleme', 1),
              _buildNavItem(Icons.calendar_today_outlined, Icons.calendar_today, 'Plan', 2),
              _buildNavItem(Icons.settings_outlined, Icons.settings, 'Ayarlar', 3),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData inactiveIcon,
    IconData activeIcon,
    String label,
    int index,
  ) {
    final isSelected = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isSelected ? 8 : 4),
        decoration: BoxDecoration(
          color: isSelected 
              ? (AppTheme.isDarkMode(context) 
                  ? AppTheme.primaryDark.withOpacity(0.2)
                  : AppTheme.primaryLight.withOpacity(0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(isSelected ? activeIcon : inactiveIcon),
      ),
      label: label,
    );
  }
}

// Ayarlar Ekranı
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  String _userName = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email ?? '';
        _userName = user.email?.split('@').first ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profil Kartı
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.getPrimaryGradient(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryLight.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName.isNotEmpty ? _userName : 'Kullanıcı',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userEmail,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Ayarlar Listesi
          _buildSettingsSection(
            title: 'Tercihler',
            children: [
              _buildSettingsTile(
                icon: Icons.person_outline,
                title: 'Profil Bilgileri',
                subtitle: 'Boy, kilo, yaş ayarları',
                onTap: () => Navigator.pushNamed(context, '/profile'),
              ),
              _buildSettingsTile(
                icon: Icons.fitness_center,
                title: 'Ekipman / Ortam',
                subtitle: 'Kullanılabilir ekipmanlar',
                onTap: () => Navigator.pushNamed(context, '/equipment'),
              ),
              _buildSettingsTile(
                icon: Icons.flag_outlined,
                title: 'Hedef ve Bölge',
                subtitle: 'Fitness hedefleri',
                onTap: () => Navigator.pushNamed(context, '/body-region-goal'),
              ),
              _buildSettingsTile(
                icon: Icons.schedule,
                title: 'Antrenman Planı',
                subtitle: 'Haftalık hedefler',
                onTap: () => Navigator.pushNamed(context, '/onboarding-plan'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildSettingsSection(
            title: 'Bildirimler',
            children: [
              _buildSettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Bildirim Ayarları',
                subtitle: 'Hatırlatıcılar ve bildirimler',
                onTap: () => Navigator.pushNamed(context, '/notification-settings'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildSettingsSection(
            title: 'Görünüm',
            children: [
              SwitchListTile(
                secondary: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                ),
                title: const Text(
                  'Karanlık Mod',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(isDark ? 'Açık' : 'Kapalı'),
                value: isDark,
                onChanged: (value) {
                  themeNotifier.setThemeMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildSettingsSection(
            title: 'Hesap',
            children: [
              _buildSettingsTile(
                icon: Icons.emoji_events_outlined,
                title: 'Başarılar',
                subtitle: 'Kazanılan rozetler',
                onTap: () => Navigator.pushNamed(context, '/achievements'),
              ),
              _buildSettingsTile(
                icon: Icons.logout,
                title: 'Çıkış Yap',
                subtitle: 'Hesaptan çıkış',
                isDestructive: true,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Çıkış Yap'),
                      content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('İptal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Çıkış Yap'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true) {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/welcome',
                        (route) => false,
                      );
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Versiyon bilgisi
          Text(
            'SmartFit v1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppTheme.error : AppTheme.getTextColor(context);
    
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppTheme.error : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
