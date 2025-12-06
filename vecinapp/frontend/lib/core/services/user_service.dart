import 'package:vecinapp/core/services/api_service.dart';
import 'package:vecinapp/core/models/user.dart';

/// Servicio para gestión de usuarios desde el admin
class UserService {
  final ApiService _apiService = ApiService();

  /// Obtener todos los usuarios con filtros opcionales
  Future<List<AppUser>> getUsers({
    String? communityId,
    String? role,
    bool? isActive,
  }) async {
    final queryParams = <String, String>{};
    if (communityId != null) queryParams['community_id'] = communityId;
    if (role != null) queryParams['role'] = role;
    if (isActive != null) queryParams['is_active'] = isActive.toString();

    final response = await _apiService.get(
      '/users',
      queryParameters: queryParams,
    );

    if (response['success']) {
      final List<dynamic> data = response['data'] ?? [];
      return data.map((json) => AppUser.fromJson(json)).toList();
    }
    throw Exception(response['message'] ?? 'Error al obtener usuarios');
  }

  /// Obtener un usuario por ID
  Future<AppUser> getUserById(String userId) async {
    final response = await _apiService.get('/users/$userId');

    if (response['success']) {
      return AppUser.fromJson(response['data']);
    }
    throw Exception(response['message'] ?? 'Error al obtener usuario');
  }

  /// Crear un nuevo usuario
  Future<AppUser> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String rut,
    String? phone,
    String? role,
  }) async {
    final response = await _apiService.post('/users', data: {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
      'rut': rut,
      if (phone != null) 'phone': phone,
      // Otros campos opcionales según necesidad
    });

    if (response['success']) {
      return AppUser.fromJson(response['data']);
    }
    throw Exception(response['message'] ?? 'Error al crear usuario');
  }

  /// Actualizar un usuario existente
  Future<AppUser> updateUser(
    String userId, {
    String? firstName,
    String? lastName,
    String? phone,
    String? rut,
  }) async {
    final data = <String, dynamic>{};
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (phone != null) data['phone'] = phone;
    if (rut != null) data['rut'] = rut;

    final response = await _apiService.put('/users/$userId', data: data);

    if (response['success']) {
      return AppUser.fromJson(response['data']);
    }
    throw Exception(response['message'] ?? 'Error al actualizar usuario');
  }

  /// Eliminar (desactivar) un usuario
  Future<void> deleteUser(String userId) async {
    final response = await _apiService.delete('/users/$userId');

    if (!response['success']) {
      throw Exception(response['message'] ?? 'Error al eliminar usuario');
    }
  }

  /// Asignar usuario a una unidad
  Future<AppUser> assignUserToUnit({
    required String userId,
    required String communityId,
    required String unitId,
    List<String> roles = const ['Residente'],
  }) async {
    final response = await _apiService.post(
      '/users/$userId/assign-unit',
      data: {
        'community_id': communityId,
        'unit_id': unitId,
        'roles': roles,
      },
    );

    if (response['success']) {
      return AppUser.fromJson(response['data']);
    }
    throw Exception(response['message'] ?? 'Error al asignar unidad');
  }

  /// Desasignar usuario de una comunidad
  Future<AppUser> unassignUserFromCommunity({
    required String userId,
    required String communityId,
  }) async {
    final response = await _apiService.delete(
      '/users/$userId/unassign-unit/$communityId',
    );

    if (response['success']) {
      return AppUser.fromJson(response['data']);
    }
    throw Exception(response['message'] ?? 'Error al desasignar usuario');
  }
}
