import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/quickalert.dart';
import 'package:vecinapp/core/theme/app_theme.dart';
import 'package:vecinapp/core/models/user.dart';
import 'package:vecinapp/core/models/community.dart';
import 'package:vecinapp/core/models/unit.dart';
import 'package:vecinapp/core/services/user_service.dart';
import 'package:vecinapp/core/services/community_service.dart';
import 'package:vecinapp/core/services/unit_service.dart';
import 'package:vecinapp/core/services/auth_service.dart';

/// Diálogo para crear o editar un usuario con layout de 2 columnas
class UserFormDialog extends StatefulWidget {
  final AppUser? user; // Si es null, crea un nuevo usuario

  const UserFormDialog({super.key, this.user});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();
  final CommunityService _communityService = CommunityService();
  final UnitService _unitService = UnitService();

  // Controladores de texto
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _rutCtrl;
  late final TextEditingController _phoneCtrl;

  // Data
  List<Community> _communities = [];
  List<Unit> _units = [];
  Community? _selectedCommunity;
  List<Unit> _selectedUnits = []; // Cambio: lista de unidades seleccionadas
  UserRole _selectedRole = UserRole.resident;
  bool _isLoading = false;
  bool _isLoadingCommunities = false;
  bool _isLoadingUnits = false;
  
  AppUser? _currentUser;  // Usuario actual (admin) para filtrar comunidades

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    // Inicializar controladores con los valores del usuario si existe
    _firstNameCtrl = TextEditingController(
      text: widget.user?.firstName ?? widget.user?.name.split(' ').first ?? ''
    );
    _lastNameCtrl = TextEditingController(
      text: widget.user?.lastName ?? widget.user?.name.split(' ').skip(1).join(' ') ?? ''
    );
    _emailCtrl = TextEditingController(text: widget.user?.email ?? '');
    _passwordCtrl = TextEditingController();
    _rutCtrl = TextEditingController(text: widget.user?.rut ?? '');
    _phoneCtrl = TextEditingController(text: widget.user?.phone ?? '');
    
    // Inicializar rol
    if (widget.user != null) {
      _selectedRole = widget.user!.role;
    }
    
    // Cargar usuario actual antes de cargar comunidades
    _initializeForm();
  }
  
  Future<void> _initializeForm() async {
    // Cargar usuario actual para saber qué comunidades puede ver
    await _loadCurrentUser();
    // Cargar comunidades filtradas por acceso del admin
    await _loadCommunities();
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
      print('❌ Error cargando usuario actual: $e');
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _rutCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCommunities() async {
    setState(() => _isLoadingCommunities = true);
    try {
      final allCommunities = await _communityService.getCommunities();
      
      // Filtrar comunidades por acceso del admin
      List<Community> accessibleCommunities;
      if (_currentUser != null && _currentUser!.memberships.isNotEmpty) {
        // Obtener IDs de comunidades a las que el admin tiene acceso
        final adminCommunityIds = _currentUser!.memberships
            .map((m) => m.communityId)
            .toSet();
        
        // Filtrar solo comunidades accesibles
        accessibleCommunities = allCommunities
            .where((c) => adminCommunityIds.contains(c.id))
            .toList();
      } else {
        // Si no hay usuario actual, mostrar todas (fallback)
        accessibleCommunities = allCommunities;
      }
      
      print('🏘️ Comunidades cargadas: ${accessibleCommunities.length}');
      for (var comm in accessibleCommunities) {
        print('   - ${comm.name} (ID: ${comm.id})');
      }
      
      setState(() {
        _communities = accessibleCommunities;
        _isLoadingCommunities = false;
        
        // Si es admin de una sola comunidad, pre-seleccionarla
        if (_currentUser != null && 
            _currentUser!.memberships.isNotEmpty && 
            _currentUser!.memberships.length == 1 && 
            _communities.isNotEmpty) {
          _selectedCommunity = _communities.first;
          _loadUnits(_selectedCommunity!.id);
        }
      });
      
      // Si es edición y tiene memberships, preseleccionar comunidad y unidades
      if (widget.user != null && widget.user!.memberships.isNotEmpty) {
        print('📋 DEBUG: Usuario tiene memberships: ${widget.user!.memberships.length}');
        for (var (index, m) in widget.user!.memberships.indexed) {
          print('📋 Membership $index:');
          print('   - communityId: ${m.communityId}');
          print('   - communityName: ${m.communityName}');
          print('   - unitId: ${m.unitId}');  // ← ESTE ES EL PROBLEMA
          print('   - unitNumber: ${m.unitNumber}');
          print('   - roles: ${m.roles}');
        }
        
        final membership = widget.user!.memberships.first;
        final unitIds = widget.user!.memberships
            .where((m) => m.unitId != null)
            .map((m) => m.unitId!)
            .toList();
        
        print('📋 UnitIds extraídos: $unitIds');
        await _preselectUnits(membership.communityId, unitIds);
      }
    } catch (e) {
      print('❌ Error cargando comunidades: $e');
      setState(() => _isLoadingCommunities = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar comunidades: $e')),
        );
      }
    }
  }

  Future<void> _preselectUnits(String communityId, List<String> unitIds) async {
    try {
      print('🔍 ========== PRESELECCIÓN DE UNIDADES ==========');
      print('🔍 Comunidad ID: $communityId');
      print('🔍 IDs de unidades a seleccionar: $unitIds');
      print('🔍 Cantidad de comunidades cargadas: ${_communities.length}');
      
      // Buscar la comunidad en la lista cargada
      final community = _communities.firstWhere(
        (c) => c.id == communityId,
        orElse: () => _communities.first,
      );
      
      setState(() => _selectedCommunity = community);
      print('✅ Comunidad seleccionada: ${community.name}');
      
      // Cargar unidades de esa comunidad
      if (unitIds.isNotEmpty) {
        print('🔄 Cargando unidades de la comunidad...');
        await _loadUnits(communityId);
        
        print('🔍 Total unidades cargadas: ${_units.length}');
        print('🔍 IDs de unidades cargadas: ${_units.map((u) => u.id).toList()}');
        
        // Seleccionar todas las unidades del usuario
        final selectedUnits = _units.where((u) => unitIds.contains(u.id)).toList();
        
        print('✅ Unidades encontradas para preseleccionar: ${selectedUnits.length}');
        for (var unit in selectedUnits) {
          print('   - ${unit.name} (ID: ${unit.id})');
        }
        
        print('🔄 Ejecutando setState para actualizar _selectedUnits...');
        setState(() {
          _selectedUnits = selectedUnits;
          print('✅ _selectedUnits actualizado. Tamaño: ${_selectedUnits.length}');
        });
        print('✅ ========== PRESELECCIÓN COMPLETADA ==========');
      } else {
        print('⚠️ No hay IDs de unidades para preseleccionar');
      }
    } catch (e) {
      print('❌ Error preseleccionando comunidad/unidad: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _loadUnits(String communityId) async {
    setState(() => _isLoadingUnits = true);
    try {
      final allUnits = await _unitService.getUnits(communityId);
      
      // Obtener IDs de unidades ya asignadas al usuario (si está editando)
      Set<String> assignedUnitIds = {};
      if (widget.user != null) {
        assignedUnitIds = widget.user!.memberships
            .where((m) => m.unitId != null)
            .map((m) => m.unitId!)
            .toSet();
      }
      
      // Incluir unidades disponibles + unidades ya asignadas al usuario
      final selectableUnits = allUnits.where((u) {
        // Incluir si está disponible O si ya está asignada a este usuario
        return u.status == 'Disponible' || assignedUnitIds.contains(u.id);
      }).toList();
      
      print('🏢 Unidades seleccionables: ${selectableUnits.length} de ${allUnits.length}');
      print('   - Disponibles: ${allUnits.where((u) => u.status == 'Disponible').length}');
      print('   - Asignadas al usuario: ${assignedUnitIds.length}');
      
      setState(() {
        _units = selectableUnits;
        _isLoadingUnits = false;
      });
    } catch (e) {
      print('❌ Error cargando unidades: $e');
      setState(() => _isLoadingUnits = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar unidades: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        // Actualizar usuario existente
        await _userService.updateUser(
          widget.user!.id,
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          rut: _rutCtrl.text.trim().isEmpty ? null : _rutCtrl.text.trim(),
          role: _selectedRole.value, // Actualizar rol
        );

        print('💾 Guardando cambios de unidades...');
        print('   _selectedCommunity: ${_selectedCommunity?.name}');
        print('   _selectedUnits count: ${_selectedUnits.length}');

        if (_selectedCommunity != null) {
          // Obtener unidades que el usuario TENÍA asignadas en esta comunidad
          final oldUnitIds = widget.user!.memberships
              .where((m) => m.communityId == _selectedCommunity!.id && m.unitId != null)
              .map((m) => m.unitId!)
              .toSet();
          
          print('📦 Old unit IDs: $oldUnitIds');
          
          // Obtener unidades NUEVAS seleccionadas
          final newUnitIds = _selectedUnits.map((u) => u.id).toSet();
          
          print('📦 New unit IDs: $newUnitIds');
          
          // Unidades a REMOVER (estaban antes pero ya no están seleccionadas)
          final unitsToRemove = oldUnitIds.difference(newUnitIds);
          
          // Unidades a AGREGAR (están seleccionadas pero no estaban antes)
          final unitsToAdd = newUnitIds.difference(oldUnitIds);
          
          print('🔄 Unidades a remover: $unitsToRemove');
          print('➕ Unidades a agregar: $unitsToAdd');
          
          // Desasignar unidades removidas
          for (final unitId in unitsToRemove) {
            print('🗑️ Intentando remover unidad: $unitId');
            try {
              await _userService.unassignUserFromUnit(
                userId: widget.user!.id,
                communityId: _selectedCommunity!.id,
                unitId: unitId,
              );
              print('✅ Unidad $unitId removida exitosamente');
            } catch (e) {
              print('⚠️ Error desasignando unidad $unitId: $e');
            }
          }
          
          // Asignar unidades nuevas
          for (final unit in _selectedUnits.where((u) => unitsToAdd.contains(u.id))) {
            print('➕ Intentando agregar unidad: ${unit.id}');
            await _userService.assignUserToUnit(
              userId: widget.user!.id,
              communityId: _selectedCommunity!.id,
              unitId: unit.id,
            );
            print('✅ Unidad ${unit.id} agregada exitosamente');
          }
        } else {
          print('⚠️ No hay comunidad seleccionada, saltando manejo de unidades');
        }
      } else {
        // Crear nuevo usuario
        final newUser = await _userService.createUser(
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          rut: _rutCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          role: _selectedRole.value,
        );

        // Asignar unidades seleccionadas
        if (_selectedCommunity != null && _selectedUnits.isNotEmpty) {
          for (final unit in _selectedUnits) {
            await _userService.assignUserToUnit(
              userId: newUser.id,
              communityId: _selectedCommunity!.id,
              unitId: unit.id,
            );
          }
        }
      }

      if (mounted) {
        Navigator.pop(context, true); // true indica que hubo cambios
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          text: _isEditing 
              ? 'Usuario actualizado correctamente' 
              : 'Usuario creado correctamente',
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    bool enabled = true,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        border: const OutlineInputBorder(),
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 900, // Más ancho para 2 columnas
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Row(
                children: [
                  Icon(
                    _isEditing ? Icons.edit : Icons.person_add,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isEditing ? 'Editar Usuario' : 'Nuevo Usuario',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              
              const Divider(height: 32),
              
              // Formulario en 2 columnas
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // COLUMNA IZQUIERDA - Datos Personales
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Datos Personales',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              controller: _firstNameCtrl,
                              label: 'Nombre',
                              required: true,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'El nombre es obligatorio';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              controller: _lastNameCtrl,
                              label: 'Apellido',
                              required: true,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'El apellido es obligatorio';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              controller: _emailCtrl,
                              label: 'Email',
                              required: true,
                              enabled: !_isEditing,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'El email es obligatorio';
                                }
                                if (!value.contains('@')) {
                                  return 'Email inválido';
                                }
                                return null;
                              },
                            ),
                            
                            if (!_isEditing) ...[
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _passwordCtrl,
                                label: 'Contraseña',
                                required: true,
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'La contraseña es obligatoria';
                                  }
                                  if (value.length < 6) {
                                    return 'Mínimo 6 caracteres';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            
                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              controller: _rutCtrl,
                              label: 'RUT',
                              hint: '12345678-9',
                            ),
                            
                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              controller: _phoneCtrl,
                              label: 'Teléfono',
                              keyboardType: TextInputType.phone,
                              hint: '+56912345678',
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 24),
                    
                    // COLUMNA DERECHA - Asignaciones
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rol y Asignación',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Selector de Rol
                            DropdownButtonFormField<UserRole>(
                              value: _selectedRole,
                              decoration: const InputDecoration(
                                labelText: 'Rol *',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: UserRole.resident,
                                  child: Text('Residente'),
                                ),
                                DropdownMenuItem(
                                  value: UserRole.administrator,
                                  child: Text('Administrador'),
                                ),
                              ],
                              onChanged: (role) {
                                if (role != null) {
                                  setState(() => _selectedRole = role);
                                }
                              },
                            ),
                            
                            const SizedBox(height: 24),
                            
                            const Text(
                              'Asignación de Unidad',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Selector de Comunidad
                            DropdownButtonFormField<Community>(
                              value: _selectedCommunity,
                              decoration: const InputDecoration(
                                labelText: 'Comunidad',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              ),
                              hint: _isLoadingCommunities
                                  ? const Text('Cargando comunidades...')
                                  : const Text('Seleccione una comunidad'),
                              items: _communities.map((comm) {
                                return DropdownMenuItem(
                                  value: comm,
                                  child: Text(comm.name),
                                );
                              }).toList(),
                              onChanged: _isLoadingCommunities ? null : (community) {
                                setState(() {
                                  _selectedCommunity = community;
                                  _selectedUnits.clear();
                                  _units = [];
                                });
                                if (community != null) {
                                  _loadUnits(community.id);
                                }
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Unidades Asignadas (chips removibles)
                            if (_selectedUnits.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Unidades Asignadas:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _selectedUnits.map((unit) {
                                      return Chip(
                                        label: Text('Unidad ${unit.name}'),
                                        backgroundColor: AppColors.primary.withOpacity(0.1),
                                        deleteIcon: const Icon(Icons.close, size: 18),
                                        onDeleted: () {
                                          setState(() {
                                            _selectedUnits.remove(unit);
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            
                            // Selector de Unidades (FilterChips)
                            if (_selectedCommunity != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Seleccione Unidades:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _isLoadingUnits
                                      ? const Center(child: CircularProgressIndicator())
                                      : _units.isEmpty
                                          ? Text(
                                              'No hay unidades disponibles',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            )
                                          : Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: _units.map((unit) {
                                                // FIX: Compare by ID instead of object reference
                                                final isSelected = _selectedUnits.any((u) => u.id == unit.id);
                                                return FilterChip(
                                                  label: Text('${unit.name}'),
                                                  selected: isSelected,
                                                  onSelected: (selected) {
                                                    setState(() {
                                                      if (selected) {
                                                        // Add if not already in list
                                                        if (!_selectedUnits.any((u) => u.id == unit.id)) {
                                                          _selectedUnits.add(unit);
                                                        }
                                                      } else {
                                                        // Remove by ID
                                                        _selectedUnits.removeWhere((u) => u.id == unit.id);
                                                      }
                                                    });
                                                  },
                                                  selectedColor: AppColors.primary.withOpacity(0.3),
                                                  checkmarkColor: AppColors.primary,
                                                );
                                              }).toList(),
                                            ),
                                ],
                              )
                            else
                              Text(
                                'Seleccione una comunidad para ver las unidades disponibles',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isEditing ? 'Actualizar' : 'Crear'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
