enum UserRole { admin, neighbor }

class AppUser {
  final String name;
  final String email;
  final String password; // solo para demo local
  final UserRole role;
  final String? photoPath;

  AppUser({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.photoPath,
  });
}
