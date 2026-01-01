import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../scripts/migrate_admin_roles.dart';
import 'admin_user_detail_view.dart';

class AdminUsersView extends StatefulWidget {
  const AdminUsersView({Key? key}) : super(key: key);

  @override
  _AdminUsersViewState createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _adminService.getAllUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Load users error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Tekrar Dene',
              textColor: Colors.white,
              onPressed: _loadUsers,
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      final email = (user['email'] ?? '').toString().toLowerCase();
      return email.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _runMigration() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Migration Onayı'),
        content: const Text(
          'Bu işlem, mevcut admin kullanıcıları yeni user_roles koleksiyonuna taşıyacak.\n\n'
          'Devam etmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Evet, Devam Et'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final migration = AdminRoleMigration();
      final result = await migration.migrateAdminRoles();

      if (mounted) {
        Navigator.pop(context); // Loading dialog'u kapat

        if (result['success'] == true) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Migration Başarılı'),
              content: Text(
                'Taşınan: ${result['migratedCount']}\n'
                'Atlanan: ${result['skippedCount']}\n'
                'Hata: ${result['errorCount']}',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _loadUsers(); // Kullanıcı listesini yenile
                  },
                  child: const Text('Tamam'),
                ),
              ],
            ),
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Migration hatası: ${result['error']}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Loading dialog'u kapat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Migration hatası: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Migration butonu ve arama çubuğu
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Migration butonu
              Card(
                color: Colors.orange.shade50,
                child: ListTile(
                  leading: Icon(Icons.sync, color: Colors.orange.shade700),
                  title: const Text(
                    'Admin Rolleri Migration',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Mevcut admin kullanıcıları yeni sisteme taşı',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: ElevatedButton.icon(
                    onPressed: _runMigration,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Çalıştır'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Arama çubuğu
              TextField(
                decoration: InputDecoration(
                  hintText: 'Kullanıcı ara (email)...',
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
            ],
          ),
        ),
        // Kullanıcı listesi
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Henüz kullanıcı yok'
                                : 'Arama sonucu bulunamadı',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUsers,
                      child: ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: Text(
                                  (user['email'] ?? 'U')[0].toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.blue.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                user['email'] ?? 'Email yok',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Yaş: ${user['age'] ?? 'N/A'} | Cinsiyet: ${user['gender'] ?? 'N/A'}'),
                                  Text('BMI: ${(user['bmi'] ?? 0.0).toStringAsFixed(1)}'),
                                  Text('Antrenman: ${user['totalWorkouts'] ?? 0}'),
                                ],
                              ),
                              trailing: user['isAdmin'] == true
                                  ? const Chip(
                                      label: Text('Admin'),
                                      backgroundColor: Colors.orange,
                                    )
                                  : const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminUserDetailView(user: user),
                                  ),
                                ).then((_) => _loadUsers());
                              },
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

