import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vecinapp/core/theme/app_theme.dart';
import 'package:vecinapp/core/models/user.dart';
import 'package:vecinapp/core/services/user_service.dart';
import 'package:vecinapp/core/services/auth_service.dart';
import 'package:vecinapp/admin/screens/users/user_form_dialog.dart';

/// Pantalla de gestión de usuarios para administradores
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final UserService _userService = UserService();
  List<AppUser> _allUsers = [];
  bool _isLoading = false;
  String? _filterRole;
  bool? _filterActive;
  AppUser? _currentUser;
  
  // Search and Pagination
  String _searchQuery = '';
  int _rowsPerPage = 10;
  int _currentPage = 0;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadUsers();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      if (user != null) {
        final userData = await _userService.getUserById(user.uid);
        setState(() => _currentUser = userData);
      }
    } catch (e) {
      print('Error cargando usuario actual: $e');
    }
  }

  bool get _isSuperAdmin {
    if (_currentUser == null || _currentUser!.memberships.isEmpty) return false;
    return _currentUser!.memberships.length > 1;
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userService.getUsers(
        role: _filterRole,
        isActive: _filterActive,
      );
      setState(() {
        _allUsers = users;
        _currentPage = 0;
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
  
  List<AppUser> get _filteredUsers {
    var filtered = _allUsers.where((user) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return (user.firstName?.toLowerCase().contains(query) ?? false) ||
             (user.lastName?.toLowerCase().contains(query) ?? false) ||
             user.email.toLowerCase().contains(query) ||
             (user.rut?.toLowerCase().contains(query) ?? false);
    }).toList();
    
    return filtered;
  }
  
  List<AppUser> get _paginatedUsers {
    final filtered = _filteredUsers;
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, filtered.length);
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end);
  }
  
  int get _totalPages => (_filteredUsers.length / _rowsPerPage).ceil();

  void _showUserDialog({AppUser? user}) {
    showDialog(
      context: context,
      builder: (context) => UserFormDialog(user: user),
    ).then((result) {
      if (result == true) {
        _loadUsers();
      }
    });
  }

  String _getUserFullName(AppUser user) {
    if (user.firstName != null && user.lastName != null) {
      return '${user.firstName} ${user.lastName}';
    }
    return user.name.isNotEmpty ? user.name : 'Sin nombre';
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.administrator:
        return 'Administrador';
      case UserRole.resident:
        return 'Residente';
      default:
        return role.value;
    }
  }

  Future<void> _toggleUserStatus(AppUser user) async {
    final action = user.isActive ? 'desactivar' : 'activar';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar ${action}ción'),
        content: Text('¿Estás seguro de $action a ${_getUserFullName(user)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: user.isActive ? AppColors.error : AppColors.success,
            ),
            child: Text(user.isActive ? 'Desactivar' : 'Activar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _userService.deleteUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Usuario ${action}do correctamente')),
          );
          _loadUsers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al $action usuario: $e')),
          );
        }
      }
    }
  }

  Future<void> _resetPassword(AppUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reiniciar Contraseña'),
        content: Text(
          '¿Enviar email de recuperación de contraseña a ${user.email}?\\n\\n'
          'El usuario recibirá un correo con instrucciones para crear una nueva contraseña.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Email de recuperación enviado a ${user.email}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al enviar email: $e')),
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
          // Filtros y Búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                if (_isSuperAdmin)
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _filterRole,
                      decoration: const InputDecoration(
                        labelText: 'Filtrar por rol',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Todos')),
                        DropdownMenuItem(value: 'administrator', child: Text('Administrador')),
                        DropdownMenuItem(value: 'resident', child: Text('Residente')),
                      ],
                      onChanged: (value) {
                        setState(() => _filterRole = value);
                        _loadUsers();
                      },
                    ),
                  ),
                if (_isSuperAdmin) const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Buscar usuarios',
                      hintText: 'Nombre, email o RUT...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onChanged: (value) => setState(() {
                      _searchQuery = value;
                      _currentPage = 0;
                    }),
                  ),
                ),
                const SizedBox(width: 16),
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
          
          // Tabla
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _paginatedUsers.isEmpty
                            ? const Center(child: Text('No hay usuarios para mostrar'))
                            : SingleChildScrollView(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: constraints.maxWidth,
                                        ),
                                        child: DataTable(
                                          headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                                          dataRowHeight: 60,
                                          columnSpacing: 24,
                                          columns: const [
                                            DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('Rol', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('Comunidad', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('Unidades', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                                          ],
                                          rows: _paginatedUsers.map((user) {
                                            final assignedUnits = user.memberships
                                                .where((m) => m.unitNumber != null)
                                                .map((m) => m.unitNumber!)
                                                .toList();
                                            
                                            final membership = user.memberships.isNotEmpty 
                                                ? user.memberships.first 
                                                : null;
                                            
                                            return DataRow(cells: [
                                              DataCell(Text(_getUserFullName(user), style: const TextStyle(fontWeight: FontWeight.w500))),
                                              DataCell(Text(user.email)),
                                              DataCell(Text(_getRoleDisplayName(user.role))),
                                              DataCell(Text(membership?.communityName ?? '-')),
                                              DataCell(
                                                assignedUnits.isEmpty
                                                    ? const Text('-')
                                                    : Wrap(
                                                        spacing: 4,
                                                        runSpacing: 4,
                                                        children: assignedUnits.map((unitNumber) {
                                                          return Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: AppColors.primary.withOpacity(0.1),
                                                              borderRadius: BorderRadius.circular(8),
                                                              border: Border.all(
                                                                color: AppColors.primary.withOpacity(0.3),
                                                                width: 0.5,
                                                              ),
                                                            ),
                                                            child: Text(
                                                              unitNumber,
                                                              style: const TextStyle(
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.w600,
                                                                color: AppColors.primary,
                                                              ),
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ),
                                              ),
                                              DataCell(
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: user.isActive ? Colors.green[50] : Colors.red[50],
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: user.isActive ? Colors.green[200]! : Colors.red[200]!,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    user.isActive ? 'Activo' : 'Inactivo',
                                                    style: TextStyle(
                                                      color: user.isActive ? Colors.green[800] : Colors.red[800],
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                                                      onPressed: () => _showUserDialog(user: user),
                                                      tooltip: 'Editar',
                                                    ),
                                                    IconButton(
                                                      icon: Icon(
                                                        user.isActive ? Icons.block : Icons.check_circle,
                                                        color: user.isActive ? Colors.red : Colors.green,
                                                      ),
                                                      onPressed: () => _toggleUserStatus(user),
                                                      tooltip: user.isActive ? 'Desactivar' : 'Activar',
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.lock_reset, color: AppColors.warning),
                                                      onPressed: () => _resetPassword(user),
                                                      tooltip: 'Reiniciar Contraseña',
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ]);
                                          }).toList(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                  ),
                  
                  // Pagination
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Row(
                      children: [
                        const Text('Filas por página:', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _rowsPerPage,
                          underline: Container(),
                          items: [5, 10, 20, 50, 100].map((value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text('$value'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _rowsPerPage = value;
                                _currentPage = 0;
                              });
                            }
                          },
                        ),
                        
                        const Spacer(),
                        
                        Text(
                          'Mostrando ${_paginatedUsers.isEmpty ? 0 : _currentPage * _rowsPerPage + 1}-${(_currentPage * _rowsPerPage + _paginatedUsers.length).clamp(0, _filteredUsers.length)} de ${_filteredUsers.length}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _currentPage > 0
                              ? () => setState(() => _currentPage--)
                              : null,
                        ),
                        Text('${_currentPage + 1} / ${_totalPages == 0 ? 1 : _totalPages}'),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _currentPage < _totalPages - 1
                              ? () => setState(() => _currentPage++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
