import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_role.dart';

class UserRoleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcının rollerini getir
  Future<UserRole?> getUserRole(String userId) async {
    try {
      print('🔍 Getting user role for userId: $userId');
      final doc = await _firestore
          .collection('user_roles')
          .doc(userId)
          .get();

      print('📄 Document exists: ${doc.exists}');
      
      if (!doc.exists || doc.data() == null) {
        print('❌ Document does not exist or data is null');
        return null;
      }

      final data = doc.data()!;
      print('📋 Document data: $data');
      print('📋 roles field: ${data['roles']}');
      print('📋 roles type: ${data['roles'].runtimeType}');
      
      final userRole = UserRole.fromMap(data);
      print('✅ UserRole created: isAdmin=${userRole.isAdmin}, roles=${userRole.roles}');
      
      return userRole;
    } catch (e, stackTrace) {
      print('❌ Error getting user role: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  // Kullanıcının admin olup olmadığını kontrol et
  Future<bool> isAdmin(String userId) async {
    try {
      final userRole = await getUserRole(userId);
      return userRole?.isAdmin ?? false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Mevcut kullanıcının admin olup olmadığını kontrol et
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }
      return await isAdmin(user.uid);
    } catch (e) {
      print('Error checking current user admin status: $e');
      return false;
    }
  }

  // Kullanıcıya rol ata
  Future<void> assignRole({
    required String userId,
    required List<String> roles,
    String? assignedBy,
  }) async {
    try {
      final now = DateTime.now();
      
      // Mevcut rolü kontrol et
      final existingRole = await getUserRole(userId);

      if (existingRole != null) {
        // Güncelle
        await _firestore.collection('user_roles').doc(userId).update({
          'roles': roles,
          'lastModified': now.toIso8601String(),
          'assignedBy': assignedBy ?? _auth.currentUser?.uid,
        });
      } else {
        // Yeni oluştur
        await _firestore.collection('user_roles').doc(userId).set({
          'userId': userId,
          'roles': roles,
          'createdAt': now.toIso8601String(),
          'assignedBy': assignedBy ?? _auth.currentUser?.uid,
        });
      }
    } catch (e) {
      throw Exception('Rol atanamadı: ${e.toString()}');
    }
  }

  // Kullanıcıya admin rolü ver
  Future<void> makeAdmin(String userId, {String? assignedBy}) async {
    try {
      final existingRole = await getUserRole(userId);
      
      if (existingRole != null) {
        // Mevcut rollere admin ekle (duplicate olmasın)
        final roles = existingRole.roles;
        if (!roles.contains('admin')) {
          roles.add('admin');
        }
        await assignRole(
          userId: userId,
          roles: roles,
          assignedBy: assignedBy,
        );
      } else {
        // Yeni admin rolü oluştur
        await assignRole(
          userId: userId,
          roles: ['admin'],
          assignedBy: assignedBy,
        );
      }
    } catch (e) {
      throw Exception('Admin rolü verilemedi: ${e.toString()}');
    }
  }

  // Kullanıcıdan admin rolünü kaldır
  Future<void> removeAdmin(String userId) async {
    try {
      final existingRole = await getUserRole(userId);
      
      if (existingRole != null) {
        final roles = existingRole.roles;
        roles.remove('admin');
        
        if (roles.isEmpty) {
          // Eğer başka rol yoksa dokümanı sil
          await _firestore.collection('user_roles').doc(userId).delete();
        } else {
          // Diğer rolleri koru
          await assignRole(
            userId: userId,
            roles: roles,
          );
        }
      }
    } catch (e) {
      throw Exception('Admin rolü kaldırılamadı: ${e.toString()}');
    }
  }

  // Kullanıcıya rol ekle
  Future<void> addRole(String userId, String role) async {
    try {
      final existingRole = await getUserRole(userId);
      
      if (existingRole != null) {
        final roles = existingRole.roles;
        if (!roles.contains(role)) {
          roles.add(role);
        }
        await assignRole(
          userId: userId,
          roles: roles,
        );
      } else {
        await assignRole(
          userId: userId,
          roles: [role],
        );
      }
    } catch (e) {
      throw Exception('Rol eklenemedi: ${e.toString()}');
    }
  }

  // Kullanıcıdan rol kaldır
  Future<void> removeRole(String userId, String role) async {
    try {
      final existingRole = await getUserRole(userId);
      
      if (existingRole != null) {
        final roles = existingRole.roles;
        roles.remove(role);
        
        if (roles.isEmpty) {
          await _firestore.collection('user_roles').doc(userId).delete();
        } else {
          await assignRole(
            userId: userId,
            roles: roles,
          );
        }
      }
    } catch (e) {
      throw Exception('Rol kaldırılamadı: ${e.toString()}');
    }
  }

  // Tüm admin kullanıcıları getir
  Future<List<String>> getAllAdminUserIds() async {
    try {
      final snapshot = await _firestore
          .collection('user_roles')
          .where('roles', arrayContains: 'admin')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting admin users: $e');
      return [];
    }
  }

  // Tüm rolleri getir
  Future<List<UserRole>> getAllUserRoles() async {
    try {
      final snapshot = await _firestore.collection('user_roles').get();
      return snapshot.docs
          .map((doc) => UserRole.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting all user roles: $e');
      return [];
    }
  }
}

