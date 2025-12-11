import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vecinapp/core/theme/app_theme.dart';
import 'package:vecinapp/core/models/incident.dart';
import 'package:vecinapp/core/services/incident_service.dart';
import 'package:vecinapp/core/services/auth_service.dart';
import 'package:intl/intl.dart';

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key});

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  final _incidentService = IncidentService();
  List<Incident> _allIncidents = [];
  bool _isLoading = true;
  String? _error;
  String? _filterStatus;
  String? _communityId;
  
  // Search and Pagination
  String _searchQuery = '';
  int _rowsPerPage = 10;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = await authService.getCurrentUserData();
      
      _communityId = userData?.communityId ?? 
                     (userData?.memberships.isNotEmpty == true 
                       ? userData!.memberships[0].communityId 
                       : '');

      final incidents = await _incidentService.getIncidents(
        communityId: _communityId!,
        status: _filterStatus,
      );

      setState(() {
        _allIncidents = incidents;
        _isLoading = false;
        _currentPage = 0;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  List<Incident> get _filteredIncidents {
    var filtered = _allIncidents.where((incident) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return incident.title.toLowerCase().contains(query) ||
             incident.description.toLowerCase().contains(query) ||
             incident.category.displayName.toLowerCase().contains(query);
    }).toList();
    
    return filtered;
  }
  
  List<Incident> get _paginatedIncidents {
    final filtered = _filteredIncidents;
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, filtered.length);
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end);
  }
  
  int get _totalPages => (_filteredIncidents.length / _rowsPerPage).ceil();

  Future<void> _updateIncidentStatus(Incident incident, IncidentStatus newStatus, String? notes) async {
    try {
      await _incidentService.updateIncident(
        communityId: _communityId!,
        incidentId: incident.id,
        status: newStatus,
        adminNotes: notes,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incidente actualizado. Residente notificado.')),
      );
      
      _loadIncidents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showUpdateDialog(Incident incident) {
    IncidentStatus selectedStatus = incident.status;
    final notesController = TextEditingController(text: incident.adminNotes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Actualizar: ${incident.title}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Descripción:', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
              Text(incident.description),
              const SizedBox(height: 16),
              Text('Cambiar Estado:', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
              StatefulBuilder(
                builder: (context, setState) => DropdownButton<IncidentStatus>(
                  value: selectedStatus,
                  isExpanded: true,
                  items: IncidentStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedStatus = value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas para el residente',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateIncidentStatus(incident, selectedStatus, notesController.text);
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }
  
  Color _getStatusColor(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.pendiente:
        return Colors.orange;
      case IncidentStatus.enProceso:
        return Colors.blue;
      case IncidentStatus.resuelto:
        return Colors.green;
    }
  }
  
  Color _getPriorityColor(IncidentPriority priority) {
    switch (priority) {
      case IncidentPriority.baja:
        return Colors.green;
      case IncidentPriority.media:
        return Colors.orange;
      case IncidentPriority.alta:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestión de Incidentes'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filtros y Búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
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
                      DropdownMenuItem(value: 'pendiente', child: Text('Pendientes')),
                      DropdownMenuItem(value: 'en_proceso', child: Text('En Proceso')),
                      DropdownMenuItem(value: 'resuelto', child: Text('Resueltos')),
                    ],
                    onChanged: (value) {
                      setState(() => _filterStatus = value);
                      _loadIncidents();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Buscar',
                      hintText: 'Título, descripción, categoría...',
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
                        : _error != null
                            ? Center(child: Text('Error: $_error'))
                            : _paginatedIncidents.isEmpty
                                ? const Center(child: Text('No hay incidentes para mostrar'))
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
                                              flex: 1,
                                              child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              flex: 3,
                                              child: Text('Título', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              flex: 2,
                                              child: Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              flex: 2,
                                              child: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              flex: 2,
                                              child: Text('Prioridad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              flex: 2,
                                              child: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                                          itemCount: _paginatedIncidents.length,
                                          itemBuilder: (context, index) {
                                            final incident = _paginatedIncidents[index];
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              decoration: BoxDecoration(
                                                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                                              ),
                                              child: Row(
                                                children: [
                                                  // ID
                                                  Expanded(
                                                    flex: 1,
                                                    child: Text(
                                                      incident.id.substring(0, 8),
                                                      style: const TextStyle(fontSize: 11),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Título
                                                  Expanded(
                                                    flex: 3,
                                                    child: Text(
                                                      incident.title,
                                                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Categoría
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      incident.category.displayName,
                                                      style: const TextStyle(fontSize: 11),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Estado
                                                  Expanded(
                                                    flex: 2,
                                                    child: Align(
                                                      alignment: Alignment.centerLeft,
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: _getStatusColor(incident.status).withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(8),
                                                          border: Border.all(color: _getStatusColor(incident.status)),
                                                        ),
                                                        child: Text(
                                                          incident.status.displayName,
                                                          style: TextStyle(
                                                            color: _getStatusColor(incident.status),
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
                                                  // Prioridad
                                                  Expanded(
                                                    flex: 2,
                                                    child: Align(
                                                      alignment: Alignment.centerLeft,
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: _getPriorityColor(incident.priority).withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(8),
                                                          border: Border.all(color: _getPriorityColor(incident.priority)),
                                                        ),
                                                        child: Text(
                                                          incident.priority.displayName,
                                                          style: TextStyle(
                                                            color: _getPriorityColor(incident.priority),
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
                                                  // Fecha
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      DateFormat('dd/MM/yy').format(incident.createdAt ?? DateTime.now()),
                                                      style: const TextStyle(fontSize: 11),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Acciones
                                                  Expanded(
                                                    flex: 1,
                                                    child: IconButton(
                                                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                                                      onPressed: () => _showUpdateDialog(incident),
                                                      tooltip: 'Editar',
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
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
                          'Mostrando ${_paginatedIncidents.isEmpty ? 0 : _currentPage * _rowsPerPage + 1}-${(_currentPage * _rowsPerPage + _paginatedIncidents.length).clamp(0, _filteredIncidents.length)} de ${_filteredIncidents.length}',
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
