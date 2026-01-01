// Migration Script: users koleksiyonundaki isAdmin değerlerini user_roles koleksiyonuna taşı
// Bu script'i çalıştırmak için:
// 1. Flutter uygulamasını çalıştır
// 2. Admin panelinde bir buton ekle veya direkt bu script'i çağır

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_role_service.dart';

class AdminRoleMigration {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserRoleService _userRoleService = UserRoleService();

  // Migration işlemini başlat
  Future<Map<String, dynamic>> migrateAdminRoles() async {
    try {
      print('Migration başlatılıyor...');
      
      // users koleksiyonundaki tüm dokümanları al
      final usersSnapshot = await _firestore.collection('users').get();
      
      int migratedCount = 0;
      int skippedCount = 0;
      int errorCount = 0;
      final errors = <String>[];

      for (var doc in usersSnapshot.docs) {
        try {
          final data = doc.data();
          final userId = doc.id;
          final isAdmin = data['isAdmin'] == true;

          if (isAdmin) {
            // Bu kullanıcı admin, user_roles'a taşı
            final existingRole = await _userRoleService.getUserRole(userId);
            
            if (existingRole == null) {
              // Yeni admin rolü oluştur
              await _userRoleService.makeAdmin(userId, assignedBy: 'migration_script');
              migratedCount++;
              print('✓ Admin rolü eklendi: $userId');
            } else if (!existingRole.isAdmin) {
              // Mevcut rollere admin ekle
              await _userRoleService.makeAdmin(userId, assignedBy: 'migration_script');
              migratedCount++;
              print('✓ Admin rolü eklendi: $userId');
            } else {
              // Zaten admin rolü var
              skippedCount++;
              print('- Zaten admin: $userId');
            }
          } else {
            // Admin değil, atla
            skippedCount++;
          }
        } catch (e) {
          errorCount++;
          final errorMsg = 'Hata (${doc.id}): ${e.toString()}';
          errors.add(errorMsg);
          print('✗ $errorMsg');
        }
      }

      print('\nMigration tamamlandı!');
      print('Taşınan: $migratedCount');
      print('Atlanan: $skippedCount');
      print('Hata: $errorCount');

      return {
        'success': true,
        'migratedCount': migratedCount,
        'skippedCount': skippedCount,
        'errorCount': errorCount,
        'errors': errors,
      };
    } catch (e) {
      print('Migration hatası: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Temizlik: users koleksiyonundaki isAdmin alanlarını kaldır (opsiyonel)
  Future<void> cleanupOldAdminFields() async {
    try {
      print('Temizlik başlatılıyor...');
      
      final usersSnapshot = await _firestore.collection('users').get();
      int cleanedCount = 0;

      for (var doc in usersSnapshot.docs) {
        try {
          final data = doc.data();
          if (data.containsKey('isAdmin')) {
            // isAdmin alanını kaldır
            await doc.reference.update({
              'isAdmin': FieldValue.delete(),
            });
            cleanedCount++;
            print('✓ isAdmin alanı kaldırıldı: ${doc.id}');
          }
        } catch (e) {
          print('✗ Hata (${doc.id}): ${e.toString()}');
        }
      }

      print('\nTemizlik tamamlandı! Kaldırılan: $cleanedCount');
    } catch (e) {
      print('Temizlik hatası: $e');
    }
  }
}

