import '../models/app_user.dart';

class LocalAuth {
  // Demo user (usuario/clave)
  static const String demoUser = 'Usuario01';
  static const String demoPass = 'Contrasena01';

  // “Base de datos” en memoria (solo demo)
  static final List<AppUser> _users = [];

  /// Registra un usuario nuevo; retorna true si ok, false si email ya existe.
  static bool register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? photoPath,
  }) {
    final exists = _users.any(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
    );
    if (exists) return false;

    _users.add(
      AppUser(
        name: name.trim(),
        email: email.trim(),
        password: password,
        role: role,
        photoPath: photoPath,
      ),
    );
    return true;
  }

  /// Login por email+password (usuarios registrados) o por usuario demo
  static bool signIn({
    String? email,
    String? username,
    required String password,
  }) {
    // 1) correo registrado
    if (email != null) {
      final u = _users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
        orElse: () => AppUser(
          name: '',
          email: '',
          password: '',
          role: UserRole.neighbor,
        ),
      );
      if (u.email.isNotEmpty && u.password == password) return true;
    }

    // 2) usuario demo (Usuario01/Contrasena01)
    if (username != null &&
        username.trim().toLowerCase() == demoUser.toLowerCase() &&
        password == demoPass) {
      return true;
    }

    return false;
  }

  /// Obtiene el usuario por email (para mostrar rol/nombre en MisDatos)
  static AppUser? byEmail(String email) {
    try {
      return _users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  // [NEW] Actualiza la foto de perfil del usuario
  static bool updatePhoto({
    required String email,
    required String photoPath,
  }) {
    final idx = _users.indexWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
    );
    if (idx == -1) return false;

    final u = _users[idx];
    _users[idx] = AppUser(
      name: u.name,
      email: u.email,
      password: u.password,
      role: u.role,
      photoPath: photoPath, // [NEW]
    );
    return true;
  }

  // [NEW] Actualiza el nombre del usuario
  static bool updateName({
    required String email,
    required String newName,
  }) {
    final idx = _users.indexWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
    );
    if (idx == -1) return false;

    final u = _users[idx];
    _users[idx] = AppUser(
      name: newName.trim(),
      email: u.email,
      password: u.password,
      role: u.role,
      photoPath: u.photoPath,
    );
    return true;
  }

  // [NEW] Actualiza el rol (Administrador / Vecino)
  static bool updateRole({
    required String email,
    required UserRole newRole,
  }) {
    final idx = _users.indexWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
    );
    if (idx == -1) return false;

    final u = _users[idx];
    _users[idx] = AppUser(
      name: u.name,
      email: u.email,
      password: u.password,
      role: newRole,
      photoPath: u.photoPath,
    );
    return true;
  }
}
