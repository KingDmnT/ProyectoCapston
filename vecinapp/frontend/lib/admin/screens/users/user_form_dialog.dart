import 'package:flutter/material.dart';
import 'package:vecinapp/core/theme/app_theme.dart';
import 'package:vecinapp/core/models/user.dart';
import 'package:vecinapp/core/models/community.dart';
import 'package:vecinapp/core/models/unit.dart';
import 'package:vecinapp/core/services/user_service.dart';
import 'package:vecinapp/core/services/community_service.dart';
import 'package:vecinapp/core/services/unit_service.dart';

/// Diálogo para crear o editar un usuario
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
  Unit? _selectedUnit;
  bool _isLoading = false;

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.user?.name.split(' ').first ?? '');
    _lastNameCtrl = TextEditingController(text: widget.user?.name.split(' ').skip(1).join(' ') ?? '');
    _emailCtrl = TextEditingController(text: widget.user?.email ?? '');
    _passwordCtrl = TextEditingController();
    _rutCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    
    _loadCommunities();
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
    try {
      final communities = await _communityService.getCommunities();
      setState(() => _communities = communities);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar comunidades: $e')),
        );
      }
    }
  }

  Future<void> _loadUnits(String communityId) async {
    try {
      final units = await _unitService.getUnits(communityId: communityId);
      setState(() {
        _units = units;
        _selectedUnit = null; // Reset selección
      });
    } catch (e) {
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
        );

        // Si seleccionó comunidad/unidad, asignar
        if (_selectedCommunity != null && _selectedUnit != null) {
          await _userService.assignUserToUnit(
            userId: widget.user!.id,
            communityId: _selectedCommunity!.id,
            unitId: _selectedUnit!.id,
          );
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
        );

        // Si seleccionó comunidad/unidad, asignar
        if (_selectedCommunity != null && _selectedUnit != null) {
          await _userService.assignUserToUnit(
            userId: newUser.id,
            communityId: _selectedCommunity!.id,
            unitId: _selectedUnit!.id,
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true); // true indica que hubo cambios
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing 
                ? 'Usuario actualizado correctamente' 
                : 'Usuario creado correctamente'),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
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
              
              // Formulario scrollable
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre
                      TextFormField(
                        controller: _firstNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Apellido
                      TextFormField(
                        controller: _lastNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Apellido *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El apellido es obligatorio';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Email
                      TextFormField(
                        controller: _emailCtrl,
                        enabled: !_isEditing, // No editable en modo edición
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(),
                        ),
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
                        // Password (solo al crear)
                        TextFormField(
                          controller: _passwordCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña *',
                            border: OutlineInputBorder(),
                          ),
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
                      
                      // RUT
                      TextFormField(
                        controller: _rutCtrl,
                        decoration: const InputDecoration(
                          labelText: 'RUT',
                          border: OutlineInputBorder(),
                          hintText: '12345678-9',
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Teléfono
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          border: OutlineInputBorder(),
                          hintText: '+56912345678',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Sección de asignación
                      const Text(
                        'Asignación de Unidad',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Selector de Comunidad
                      DropdownButtonFormField<Community>(
                        value: _selectedCommunity,
                        decoration: const InputDecoration(
                          labelText: 'Comunidad',
                          border: OutlineInputBorder(),
                        ),
                        items: _communities.map((comm) {
                          return DropdownMenuItem(
                            value: comm,
                            child: Text(comm.name),
                          );
                        }).toList(),
                        onChanged: (community) {
                          setState(() {
                            _selectedCommunity = community;
                            _selectedUnit = null;
                            _units = [];
                          });
                          if (community != null) {
                            _loadUnits(community.id);
                          }
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Selector de Unidad
                      DropdownButtonFormField<Unit>(
                        value: _selectedUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unidad',
                          border: OutlineInputBorder(),
                        ),
                        items: _units.map((unit) {
                          return DropdownMenuItem(
                            value: unit,
                            child: Text('Unidad ${unit.unitNumber}'),
                          );
                        }).toList(),
                        onChanged: (unit) {
                          setState(() => _selectedUnit = unit);
                        },
                      ),
                    ],
                  ),
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
