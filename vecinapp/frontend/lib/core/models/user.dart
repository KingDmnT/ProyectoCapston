// Modelo de usuario con roles para Firestore
enum UserRole {
  administrator, // Acceso a backoffice
  resident // Acceso a mobile app
}

// Extension para obtener el valor string del enum
extension UserRoleExtension on UserRole {
  String get value {
    return this == UserRole.administrator ? 'administrator' : 'resident';
  }

  static UserRole fromString(String roleStr) {
    return roleStr == 'administrator' ? UserRole.administrator : UserRole.resident;
  }
}

// Membresía a una comunidad
class CommunityMembership {
  final String communityId;
  final String? communityName;
  final String? unitId;
  final String? unitNumber;
  final List<String> roles;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;

  CommunityMembership({
    required this.communityId,
    this.communityName,
    this.unitId,
    this.unitNumber,
    this.roles = const [],
    this.startDate,
    this.endDate,
    this.isActive = true,
  });

  factory CommunityMembership.fromJson(Map<String, dynamic> json) {
    // Helper para convertir diferentes formatos de fecha
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      
      // Si ya es DateTime
      if (value is DateTime) return value;
      
      // Si es String ISO
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('Error parseando fecha string: $e');
          return null;
        }
      }
      
      // Si tiene método toDate (Firestore Timestamp)
      try {
        return value.toDate();
      } catch (e) {
        // Ignorar si no tiene toDate
      }
      
      // Si es Map con seconds (formato raw de Firestore)
      if (value is Map) {
        if (value.containsKey('seconds')) {
          return DateTime.fromMillisecondsSinceEpoch(
            (value['seconds'] as int) * 1000,
          );
        }
      }
      
      return null;
    }

    return CommunityMembership(
      communityId: json['community_id'] ?? '',
      communityName: json['community_name'],
      unitId: json['unit_id'],
      unitNumber: json['unit_number'],
      roles: (json['roles'] as List<dynamic>?)?.cast<String>() ?? [],
      startDate: parseDate(json['start_date']),
      endDate: parseDate(json['end_date']),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'community_id': communityId,
      'community_name': communityName,
      'unit_id': unitId,
      'unit_number': unitNumber,
      'roles': roles,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
    };
  }
}

class AppUser {
  final String id; // UID de Firebase Auth
  final String name;
  final String email;
  final UserRole role;
  final String? photoUrl;
  final String? communityId; // ID de la comunidad principal
  final List<CommunityMembership> memberships;
  final bool isActive;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
    this.communityId,
    this.memberships = const [],
    this.isActive = true,
  });

  // Métodos helper para verificar roles
  bool get isAdministrator => role == UserRole.administrator;
  bool get isResident => role == UserRole.resident;

  // Convertir desde JSON (para API backend)
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: UserRoleExtension.fromString(json['role'] ?? 'resident'),
      photoUrl: json['photoUrl'],
      communityId: json['communityId'],
      memberships: (json['memberships'] as List<dynamic>?)
              ?.map((m) => CommunityMembership.fromJson(m))
              .toList() ??
          [],
      isActive: json['is_active'] ?? json['isActive'] ?? true,
    );
  }

  // Convertir desde Firestore
  factory AppUser.fromFirestore(Map<String, dynamic> data, String uid) {
    return AppUser(
      id: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] == 'administrator' ? UserRole.administrator : UserRole.resident,
      photoUrl: data['photoUrl'],
      communityId: data['communityId'],
      memberships: (data['memberships'] as List<dynamic>?)
              ?.map((m) => CommunityMembership.fromJson(m))
              .toList() ??
          [],
      isActive: data['is_active'] ?? data['isActive'] ?? true,
    );
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.value,
      'photoUrl': photoUrl,
      'communityId': communityId,
      'memberships': memberships.map((m) => m.toJson()).toList(),
      'is_active': isActive,
    };
  }

  // Convertir a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role == UserRole.administrator ? 'administrator' : 'resident',
      'photoUrl': photoUrl,
      'communityId': communityId,
      'memberships': memberships.map((m) => m.toJson()).toList(),
      'is_active': isActive,
    };
  }
}
