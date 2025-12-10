import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vecinapp/core/theme/app_theme.dart';
import 'package:vecinapp/core/models/maintenance.dart';
import 'package:vecinapp/core/models/user.dart';
import 'package:vecinapp/core/services/auth_service.dart';
import 'package:vecinapp/core/services/user_service.dart';
import 'package:vecinapp/admin/screens/maintenance/maintenance_form_dialog.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Pantalla de gestión de mantenimientos para administradores
class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();
  List<Maintenance> _allMaintenances = [];
  bool _isLoading = false;
  String? _filterType;
  String? _filterStatus;
  AppUser? _currentUser;
  String? _currentCommunityId;
  
  // Search and Pagination
  String _searchQuery = '';
  int _rowsPerPage = 10;
  int _currentPage = 0;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      if (user != null) {
        final userData = await _userService.getUserById(user.uid);
        setState(() {
          _currentUser = userData;
          if (userData.memberships.isNotEmpty) {
            _currentCommunityId = userData.memberships.first.communityId;
          }
        });
        _loadMaintenances();
      }
    } catch (e) {
      print('Error cargando usuario actual: $e');
    }
  }

  Future<void> _loadMaintenances() async {
    if (_currentCommunityId == null) return;
    
    setState(() => _isLoading = true);
    try {
      // Construir query base
      Query query = _firestore
          .collection('communities')
          .doc(_currentCommunityId)
          .collection('maintenances');
      
      // Aplicar filtros
      if (_filterType != null) {
        query = query.where('type', isEqualTo: _filterType);
      }
      if (_filterStatus != null) {
        query = query.where('status', isEqualTo: _filterStatus);
      }
      
      // Obtener datos
      final snapshot = await query.get();
      final maintenances = snapshot.docs.map((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Agregar el ID del documento
          return Maintenance.fromJson(data);
        } catch (e) {
          print('Error parseando mantenimiento ${doc.id}: $e');
          return null;
        }
      }).where((m) => m != null).cast<Maintenance>().toList();
      
      setState(() {
        _allMaintenances = maintenances;
        _currentPage = 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar mantenimientos: $e')),
        );
      }
    }
  }
  
  List<Maintenance> get _filteredMaintenances {
    var filtered = _allMaintenances.where((maintenance) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return maintenance.title.toLowerCase().contains(query) ||
             maintenance.providerName.toLowerCase().contains(query) ||
             maintenance.description.toLowerCase().contains(query);
    }).toList();
    
    return filtered;
  }
  
  List<Maintenance> get _paginatedMaintenances {
    final filtered = _filteredMaintenances;
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, filtered.length);
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end);
  }
  
  int get _totalPages => (_filteredMaintenances.length / _rowsPerPage).ceil();

  void _showMaintenanceDialog({Maintenance? maintenance}) {
    if (_currentCommunityId == null) return;
    
    showDialog(
      context: context,
      builder: (context) => MaintenanceFormDialog(
        communityId: _currentCommunityId!,
        maintenance: maintenance,
      ),
    ).then((result) {
      if (result == true) {
        _loadMaintenances();
      }
    });
  }

  Future<void> _approveMaintenance(Maintenance maintenance) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprobar Mantenimiento'),
        content: Text('¿Estás seguro de aprobar "${maintenance.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.success),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore
            .collection('communities')
            .doc(_currentCommunityId)
            .collection('maintenances')
            .doc(maintenance.id)
            .update({
          'status': 'aprobado',
          'approved_by': _currentUser?.id,
          'approval_date': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mantenimiento aprobado')),
          );
          _loadMaintenances();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al aprobar: $e')),
          );
        }
      }
    }
  }

  Future<void> _rejectMaintenance(Maintenance maintenance) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Mantenimiento'),
        content: Text('¿Estás seguro de rechazar "${maintenance.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore
            .collection('communities')
            .doc(_currentCommunityId)
            .collection('maintenances')
            .doc(maintenance.id)
            .update({
          'status': 'rechazado',
          'updated_at': FieldValue.serverTimestamp(),
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mantenimiento rechazado')),
          );
          _loadMaintenances();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al rechazar: $e')),
          );
        }
      }
    }
  }

  Color _getStatusColor(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.pendiente:
        return AppColors.warning;
      case MaintenanceStatus.enProgreso:
        return Colors.blue;
      case MaintenanceStatus.completado:
        return Colors.purple;
      case MaintenanceStatus.aprobado:
        return AppColors.success;
      case MaintenanceStatus.rechazado:
        return AppColors.error;
    }
  }

  Color _getTypeColor(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.preventivo:
        return Colors.green;
      case MaintenanceType.correctivo:
        return Colors.orange;
      case MaintenanceType.extraordinario:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestión de Mantenimientos'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMaintenances,
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
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _filterType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Todos')),
                      DropdownMenuItem(value: 'preventivo', child: Text('Preventivo')),
                      DropdownMenuItem(value: 'correctivo', child: Text('Correctivo')),
                      DropdownMenuItem(value: 'extraordinario', child: Text('Extraordinario')),
                    ],
                    onChanged: (value) {
                      setState(() => _filterType = value);
                      _loadMaintenances();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Buscar',
                      hintText: 'Título, proveedor...',
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
                  child: DropdownButtonFormField<String?>(
                    value: _filterStatus,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Todos')),
                      DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                      DropdownMenuItem(value: 'en_progreso', child: Text('En Progreso')),
                      DropdownMenuItem(value: 'completado', child: Text('Completado')),
                      DropdownMenuItem(value: 'aprobado', child: Text('Aprobado')),
                      DropdownMenuItem(value: 'rechazado', child: Text('Rechazado')),
                    ],
                    onChanged: (value) {
                      setState(() => _filterStatus = value);
                      _loadMaintenances();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showMaintenanceDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Mantenimiento'),
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
                        : _paginatedMaintenances.isEmpty
                            ? const Center(child: Text('No hay mantenimientos para mostrar'))
                            : Column(
                                children: [
                                  // Header
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                                    ),
                                    child: Row(
                                      children: const [
                                        Expanded(
                                          flex: 3,
                                          child: Text('Título', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          flex: 2,
                                          child: Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          flex: 2,
                                          child: Text('Proveedor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          flex: 2,
                                          child: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          flex: 2,
                                          child: Text('Costo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          flex: 2,
                                          child: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          flex: 2,
                                          child: Text('Progreso', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          flex: 1,
                                          child: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Rows
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: _paginatedMaintenances.length,
                                      itemBuilder: (context, index) {
                                        final maintenance = _paginatedMaintenances[index];
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                                          ),
                                          child: Row(
                                            children: [
                                              // Título (flex: 3)
                                              Expanded(
                                                flex: 3,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      maintenance.title,
                                                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    if (maintenance.isOverdue)
                                                      Row(
                                                        children: const [
                                                          Icon(Icons.warning, size: 12, color: Colors.red),
                                                          SizedBox(width: 4),
                                                          Text('Vencido', style: TextStyle(fontSize: 10, color: Colors.red)),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Tipo (flex: 2)
                                              Expanded(
                                                flex: 2,
                                                child: Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: _getTypeColor(maintenance.type).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: _getTypeColor(maintenance.type)),
                                                    ),
                                                    child: Text(
                                                      maintenance.type.displayName,
                                                      style: TextStyle(
                                                        color: _getTypeColor(maintenance.type),
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Proveedor (flex: 2)
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  maintenance.providerName,
                                                  style: const TextStyle(fontSize: 11),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Fecha (flex: 2)
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  DateFormat('dd/MM/yyyy').format(maintenance.scheduledDate),
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Costo (flex: 2)
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  '\$${maintenance.cost.toStringAsFixed(0)}',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Estado (flex: 2)
                                              Expanded(
                                                flex: 2,
                                                child: Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(maintenance.status).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: _getStatusColor(maintenance.status)),
                                                    ),
                                                    child: Text(
                                                      maintenance.status.displayName,
                                                      style: TextStyle(
                                                        color: _getStatusColor(maintenance.status),
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Progreso (flex: 2)
                                              Expanded(
                                                flex: 2,
                                                child: maintenance.checklistItems.isEmpty
                                                    ? const Text('-', style: TextStyle(fontSize: 11))
                                                    : Row(
                                                        children: [
                                                          Expanded(
                                                            child: LinearProgressIndicator(
                                                              value: maintenance.checklistProgress / 100,
                                                              backgroundColor: Colors.grey[300],
                                                              color: AppColors.primary,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            '${maintenance.checklistProgress}%',
                                                            style: const TextStyle(fontSize: 10),
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Acciones (flex: 1)
                                              Expanded(
                                                flex: 1,
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                                                      onPressed: () => _showMaintenanceDialog(maintenance: maintenance),
                                                      tooltip: 'Editar',
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                    ),
                                                    if (maintenance.isCompleted && !maintenance.isApproved && !maintenance.isRejected) ...[
                                                      const SizedBox(width: 4),
                                                      IconButton(
                                                        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                                                        onPressed: () => _approveMaintenance(maintenance),
                                                        tooltip: 'Aprobar',
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      IconButton(
                                                        icon: const Icon(Icons.cancel, color: AppColors.error, size: 18),
                                                        onPressed: () => _rejectMaintenance(maintenance),
                                                        tooltip: 'Rechazar',
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
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
                          items: [5, 10, 20, 50].map((value) {
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
                          'Mostrando ${_paginatedMaintenances.isEmpty ? 0 : _currentPage * _rowsPerPage + 1}-${(_currentPage * _rowsPerPage + _paginatedMaintenances.length).clamp(0, _filteredMaintenances.length)} de ${_filteredMaintenances.length}',
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
