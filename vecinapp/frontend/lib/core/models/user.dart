// Modelo de usuario con roles para Firestore
enum UserRole { 
  administrator,  // Acceso a backoffice
  resident        // Acceso a mobile app
}

class AppUser {
  final String id;            // UID de Firebase Auth
  final String name;
  final String email;
  final UserRole role;
  final String? photoUrl;
  final String? communityId;  // ID de la comunidad a la que pertenece
  
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
    this.communityId,
  });
  
  // Métodos helper para verificar roles
  bool get isAdministrator => role == UserRole.administrator;
  bool get isResident => role == UserRole.resident;
  
  // Convertir desde Firestore
  factory AppUser.fromFirestore(Map<String, dynamic> data, String uid) {
    return AppUser(
      id: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] == 'administrator' 
          ? UserRole.administrator 
          : UserRole.resident,
      photoUrl: data['photoUrl'],
      communityId: data['communityId'],
    );
  }
  
  // Convertir a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role == UserRole.administrator ? 'administrator' : 'resident',
      'photoUrl': photoUrl,
      'communityId': communityId,
    };
  }
}
