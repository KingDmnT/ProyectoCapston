import 'package:flutter/material.dart';
import 'package:vecinapp/core/theme/app_theme.dart';
import 'package:vecinapp/core/models/user.dart';
import 'package:vecinapp/core/services/user_service.dart';
import 'package:vecinapp/admin/screens/users/user_form_dialog.dart';

/// Pantalla de gestión de usuarios para administradores
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final UserService _userService = UserService();
  List<AppUser> _users = [];
  bool _isLoading = false;
  String? _filterRole;
  bool? _filterActive = true; // Solo activos por defecto
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userService.getUsers(
        role: _filterRole,
        isActive: _filterActive,
      );
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar usuarios: $e')),
        );
      }
    }
  }

  void _showUserDialog({AppUser? user}) {
    showDialog(
      context: context,
      builder: (context) => UserFormDialog(user: user),
    ).then((result) {
      if (result == true) {
        _loadUsers(); // Recargar lista si hubo cambios
      }
    });
  }

  Future<void> _deleteUser(AppUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar a ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _userService.deleteUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario eliminado correctamente')),
          );
          _loadUsers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                // Filtro por rol
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _filterRole,
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por rol',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      DropdownMenuItem(value: UserRole.administrator.value, child: Text('Administrator')),
                      DropdownMenuItem(value: UserRole.resident.value, child: Text('Resident')),
                    ],
                    onChanged: (value) {
                      setState(() => _filterRole = value);
                      _loadUsers();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Filtro por estado
                Expanded(
                  child: DropdownButtonFormField<bool?>(
                    value: _filterActive,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Todos')),
                      DropdownMenuItem(value: true, child: Text('Activos')),
                      DropdownMenuItem(value: false, child: Text('Inactivos')),
                    ],
                    onChanged: (value) {
                      setState(() => _filterActive = value);
                      _loadUsers();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showUserDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Usuario'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Tabla de usuarios
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(
                        child: Text('No hay usuarios para mostrar'),
                      )
                    : SingleChildScrollView(
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(
                              AppColors.primary.withOpacity(0.1),
                            ),
                            columns: const [
                              DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Rol', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Comunidad', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: _users.map((user) {
                              final membership = user.memberships.isNotEmpty 
                                  ? user.memberships.first 
                                  : null;
                              
                              return DataRow(
                                cells: [
                                  DataCell(Text(user.name)),
                                  DataCell(Text(user.email)),
                                  DataCell(Text(user.role.value)),
                                  DataCell(Text(membership?.communityName ?? '-')),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: user.isActive ? AppColors.success : AppColors.error,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        user.isActive ? 'Activo' : 'Inactivo',
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 20),
                                          onPressed: () => _showUserDialog(user: user),
                                          tooltip: 'Editar',
                                          color: AppColors.primary,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 20),
                                          onPressed: () => _deleteUser(user),
                                          tooltip: 'Eliminar',
                                          color: AppColors.error,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
