class UserRole {
  final String userId;
  final List<String> roles; // ["admin", "moderator", "premium", vb.]
  final DateTime createdAt;
  final String? assignedBy; // Hangi admin tarafından atandı
  final DateTime? lastModified;

  UserRole({
    required this.userId,
    required this.roles,
    required this.createdAt,
    this.assignedBy,
    this.lastModified,
  });

  // Admin rolü var mı kontrol et
  bool get isAdmin => roles.contains('admin');

  // Belirli bir rol var mı kontrol et
  bool hasRole(String role) => roles.contains(role);

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'roles': roles,
      'createdAt': createdAt.toIso8601String(),
      'assignedBy': assignedBy,
      'lastModified': lastModified?.toIso8601String(),
    };
  }

  factory UserRole.fromMap(Map<String, dynamic> map) {
    // roles alanını parse et - hem array hem de string olabilir
    List<String> rolesList = [];
    if (map['roles'] != null) {
      if (map['roles'] is List) {
        rolesList = List<String>.from(map['roles']);
      } else if (map['roles'] is String) {
        rolesList = [map['roles'] as String];
      }
    }
    
    // createdAt alanını parse et - hem timestamp hem de string olabilir
    DateTime createdAt;
    if (map['createdAt'] != null) {
      if (map['createdAt'] is DateTime) {
        createdAt = map['createdAt'] as DateTime;
      } else if (map['createdAt'] is String) {
        createdAt = DateTime.parse(map['createdAt']);
      } else {
        // Timestamp object (Firestore'dan geliyorsa)
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
    }
    
    // lastModified alanını parse et
    DateTime? lastModified;
    if (map['lastModified'] != null) {
      if (map['lastModified'] is DateTime) {
        lastModified = map['lastModified'] as DateTime;
      } else if (map['lastModified'] is String) {
        lastModified = DateTime.parse(map['lastModified']);
      }
    }
    
    return UserRole(
      userId: map['userId'] ?? '',
      roles: rolesList,
      createdAt: createdAt,
      assignedBy: map['assignedBy'],
      lastModified: lastModified,
    );
  }

  UserRole copyWith({
    String? userId,
    List<String>? roles,
    DateTime? createdAt,
    String? assignedBy,
    DateTime? lastModified,
  }) {
    return UserRole(
      userId: userId ?? this.userId,
      roles: roles ?? this.roles,
      createdAt: createdAt ?? this.createdAt,
      assignedBy: assignedBy ?? this.assignedBy,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}

