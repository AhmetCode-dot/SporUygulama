import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/workout_session.dart';
import '../../models/exercise_detail.dart';
import 'admin_workout_detail_view.dart';

class AdminUserDetailView extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminUserDetailView({Key? key, required this.user}) : super(key: key);

  @override
  _AdminUserDetailViewState createState() => _AdminUserDetailViewState();
}

class _AdminUserDetailViewState extends State<AdminUserDetailView> {
  final AdminService _adminService = AdminService();
  List<WorkoutSession> _workouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    setState(() => _isLoading = true);
    try {
      final workouts = await _adminService.getUserWorkouts(widget.user['userId']);
      if (mounted) {
        setState(() {
          _workouts = workouts;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Load workouts error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleAdminStatus() async {
    final currentStatus = widget.user['isAdmin'] ?? false;
    final newStatus = !currentStatus;

    try {
      await _adminService.setAdminStatus(widget.user['userId'], newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'Admin yapıldı' : 'Admin yetkisi kaldırıldı'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Sil'),
        content: const Text('Bu kullanıcıyı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
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
        await _adminService.deleteUser(widget.user['userId']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kullanıcı silindi')),
          );
          Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Detayı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteUser,
            tooltip: 'Kullanıcıyı Sil',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kullanıcı bilgileri kartı
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            (widget.user['email'] ?? 'U')[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.user['email'] ?? 'Email yok',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.user['isAdmin'] == true)
                                const Chip(
                                  label: Text('Admin'),
                                  backgroundColor: Colors.orange,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    _buildInfoRow('Yaş', '${widget.user['age'] ?? 'N/A'}'),
                    _buildInfoRow('Cinsiyet', widget.user['gender'] ?? 'N/A'),
                    _buildInfoRow('Boy', '${widget.user['height'] ?? 0.0} m'),
                    _buildInfoRow('Kilo', '${widget.user['weight'] ?? 0.0} kg'),
                    _buildInfoRow('BMI', (widget.user['bmi'] ?? 0.0).toStringAsFixed(1)),
                    _buildInfoRow('Toplam Antrenman', '${widget.user['totalWorkouts'] ?? 0}'),
                    _buildInfoRow('Toplam Süre', '${widget.user['totalDuration'] ?? 0} dakika'),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _toggleAdminStatus,
                        icon: Icon(widget.user['isAdmin'] == true ? Icons.remove_moderator : Icons.admin_panel_settings),
                        label: Text(widget.user['isAdmin'] == true ? 'Admin Yetkisini Kaldır' : 'Admin Yap'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.user['isAdmin'] == true ? Colors.orange : Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Antrenman geçmişi
            const Text(
              'Antrenman Geçmişi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _workouts.isEmpty
                    ? const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Henüz antrenman yapılmamış'),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _workouts.length,
                        itemBuilder: (context, index) {
                          final workout = _workouts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: const Icon(Icons.check, color: Colors.blue),
                              ),
                              title: Text(
                                _formatDate(workout.date),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('${workout.exerciseNames.length} egzersiz'),
                                  Text(
                                    _formatDuration(workout.totalDuration),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminWorkoutDetailView(workout: workout),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
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
}

