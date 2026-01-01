import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/badge.dart' as models;
import '../models/user_achievement.dart';
import '../models/user_level.dart';
import '../services/gamification_service.dart';

class AchievementsView extends StatefulWidget {
  const AchievementsView({Key? key}) : super(key: key);

  @override
  State<AchievementsView> createState() => _AchievementsViewState();
}

class _AchievementsViewState extends State<AchievementsView> {
  final GamificationService _gamificationService = GamificationService();
  bool _isLoading = true;
  
  List<models.AchievementBadge> _allBadges = [];
  List<UserAchievement> _earnedAchievements = [];
  UserLevel? _userLevel;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final badges = GamificationService.getDefaultBadges();
      final achievements = await _gamificationService.getUserAchievements(user.uid);
      final level = await _gamificationService.getUserLevel(user.uid);

      setState(() {
        _allBadges = badges;
        _earnedAchievements = achievements;
        _userLevel = level;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rozetler yüklenirken hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isBadgeEarned(String badgeId) {
    return _earnedAchievements.any((a) => a.badgeId == badgeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rozetler ve Başarılar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAchievements,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAchievements,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Seviye kartı
                    if (_userLevel != null) _buildLevelCard(_userLevel!),
                    const SizedBox(height: 16),
                    
                    // Kategori başlıkları
                    ...models.BadgeCategory.values.map((category) {
                      final categoryBadges = _allBadges
                          .where((b) => b.category == category)
                          .toList();
                      
                      if (categoryBadges.isEmpty) return const SizedBox.shrink();
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getCategoryName(category),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: categoryBadges.length,
                            itemBuilder: (context, index) {
                              final badge = categoryBadges[index];
                              final isEarned = _isBadgeEarned(badge.id);
                              return _buildBadgeCard(badge, isEarned);
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLevelCard(UserLevel level) {
    return Card(
      elevation: 4,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.amber, size: 32),
                const SizedBox(width: 8),
                Text(
                  'Seviye ${level.level}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${level.totalXP} XP',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: level.progressPercentage,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              '${level.currentLevelXP} / ${level.xpForNextLevel} XP (Bir sonraki seviye)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeCard(models.AchievementBadge badge, bool isEarned) {
    return Card(
      elevation: isEarned ? 4 : 1,
      color: isEarned ? Colors.amber.shade50 : Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              badge.icon,
              style: TextStyle(
                fontSize: 48,
                color: isEarned ? null : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isEarned ? Colors.black87 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isEarned ? Colors.grey.shade700 : Colors.grey.shade500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isEarned) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Kazanıldı',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getCategoryName(models.BadgeCategory category) {
    switch (category) {
      case models.BadgeCategory.milestone:
        return 'Kilometre Taşları';
      case models.BadgeCategory.consistency:
        return 'Tutarlılık';
      case models.BadgeCategory.achievement:
        return 'Başarılar';
      case models.BadgeCategory.special:
        return 'Özel';
    }
  }
}

