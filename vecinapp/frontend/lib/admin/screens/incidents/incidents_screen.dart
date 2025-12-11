import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vecinapp/core/theme/app_theme.dart';
import 'package:vecinapp/core/models/incident.dart';
import 'package:vecinapp/core/models/incident_comment.dart';
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

  void _showIncidentDetailDialog(Incident incident) {
    showDialog(
      context: context,
      builder: (context) => _IncidentDetailDialog(
        incidentSummary: incident,
        communityId: _communityId!,
        incidentService: _incidentService,
        onUpdate: _loadIncidents,
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
      case IncidentPriority.critica:
        return Colors.red.shade900;
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
                                            Expanded(flex: 1, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                            SizedBox(width: 8),
                                            Expanded(flex: 2, child: Text('Título', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                            SizedBox(width: 8),
                                            Expanded(flex: 2, child: Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                            SizedBox(width: 8),
                                            Expanded(flex: 2, child: Text('Reportado Por', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                            SizedBox(width: 8),
                                            Expanded(flex: 2, child: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                            SizedBox(width: 8),
                                            Expanded(flex: 1, child: Text('Est/Prio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                            SizedBox(width: 8),
                                            Expanded(flex: 1, child: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
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
                                                color: incident.isSecurity ? Colors.red.withOpacity(0.05) : null,
                                                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                                              ),
                                              child: Row(
                                                children: [
                                                  // ID
                                                  Expanded(flex: 1, child: Text(incident.id.substring(0, 8), style: const TextStyle(fontSize: 11))),
                                                  const SizedBox(width: 8),
                                                  // Título
                                                  Expanded(
                                                    flex: 2,
                                                    child: Row(
                                                      children: [
                                                        if (incident.isSecurity)
                                                          const Padding(
                                                            padding: EdgeInsets.only(right: 4.0),
                                                            child: Icon(Icons.shield, size: 14, color: Colors.red),
                                                          ),
                                                        Expanded(
                                                          child: Text(
                                                            incident.title,
                                                            style: TextStyle(fontSize: 11, fontWeight: incident.isSecurity ? FontWeight.bold : FontWeight.normal),
                                                            maxLines: 2,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Categoría
                                                  Expanded(flex: 2, child: Text(incident.category.displayName, style: const TextStyle(fontSize: 11))),
                                                  const SizedBox(width: 8),
                                                  // Reportado Por
                                                  Expanded(
                                                    flex: 2,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Text(
                                                          incident.reportedByName ?? 'Desconocido',
                                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        if (incident.reportedByUnit != null)
                                                          Text(incident.reportedByUnit!, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Fecha
                                                  Expanded(
                                                    flex: 2,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Text(
                                                          incident.createdAt != null ? DateFormat('dd/MM/yy').format(incident.createdAt!) : '-',
                                                          style: const TextStyle(fontSize: 11),
                                                        ),
                                                        if (incident.createdAt != null)
                                                          Text(DateFormat('HH:mm').format(incident.createdAt!), style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Estado/Prioridad
                                                  Expanded(
                                                    flex: 1,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                          margin: const EdgeInsets.only(bottom: 2),
                                                          decoration: BoxDecoration(
                                                            color: _getStatusColor(incident.status).withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            incident.status.displayName,
                                                            style: TextStyle(color: _getStatusColor(incident.status), fontSize: 9, fontWeight: FontWeight.bold),
                                                          ),
                                                        ),
                                                        if (incident.priority != IncidentPriority.media)
                                                          Text(incident.priority.displayName, style: TextStyle(fontSize: 9, color: _getPriorityColor(incident.priority), fontWeight: FontWeight.w500)),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Acciones
                                                  Expanded(
                                                    flex: 1,
                                                    child: IconButton(
                                                      icon: const Icon(Icons.visibility_outlined, color: AppColors.primary, size: 18),
                                                      onPressed: () => _showIncidentDetailDialog(incident),
                                                      tooltip: 'Ver Detalles',
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
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[200]!))),
                    child: Row(
                      children: [
                        const Text('Filas por página:', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _rowsPerPage,
                          underline: Container(),
                          items: [5, 10, 20, 50].map((value) => DropdownMenuItem<int>(value: value, child: Text('$value'))).toList(),
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
                        IconButton(icon: const Icon(Icons.chevron_left), onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null),
                        Text('${_currentPage + 1} / ${_totalPages == 0 ? 1 : _totalPages}'),
                        IconButton(icon: const Icon(Icons.chevron_right), onPressed: _currentPage < _totalPages - 1 ? () => setState(() => _currentPage++) : null),
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

class _IncidentDetailDialog extends StatefulWidget {
  final Incident incidentSummary;
  final String communityId;
  final IncidentService incidentService;
  final VoidCallback onUpdate;

  const _IncidentDetailDialog({
    required this.incidentSummary,
    required this.communityId,
    required this.incidentService,
    required this.onUpdate,
  });

  @override
  State<_IncidentDetailDialog> createState() => _IncidentDetailDialogState();
}

class _IncidentDetailDialogState extends State<_IncidentDetailDialog> {
  late Incident _incident;
  bool _isLoading = true;
  final _commentController = TextEditingController();
  bool _isSendingComment = false;

  @override
  void initState() {
    super.initState();
    _incident = widget.incidentSummary;
    _loadFullIncident();
  }

  Future<void> _loadFullIncident() async {
    try {
      final fullIncident = await widget.incidentService.getIncidentById(
        communityId: widget.communityId,
        incidentId: widget.incidentSummary.id,
      );
      if (mounted) {
        setState(() {
          _incident = fullIncident;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    setState(() => _isSendingComment = true);
    try {
      await widget.incidentService.addComment(
        communityId: widget.communityId,
        incidentId: _incident.id,
        commentText: _commentController.text,
      );
      _commentController.clear();
      await _loadFullIncident(); 
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSendingComment = false);
    }
  }

  Future<void> _updateStatus(IncidentStatus newStatus) async {
    try {
        await widget.incidentService.updateIncident(
            communityId: widget.communityId,
            incidentId: _incident.id,
            status: newStatus
        );
        widget.onUpdate();
        _loadFullIncident();
    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Detalle de Incidente: ${_incident.title}'),
      content: SizedBox(
        width: 600,
        height: 600,
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                   Card(
                     color: Colors.grey[50],
                     elevation: 0,
                     child: Padding(
                       padding: const EdgeInsets.all(12.0),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Row(
                             children: [
                               Chip(label: Text(_incident.category.displayName)),
                               const SizedBox(width: 8),
                               Chip(label: Text(_incident.status.displayName)),
                               const SizedBox(width: 8),
                               Chip(label: Text('Prio: ${_incident.priority.displayName}')),
                               if (_incident.isSecurity) ...[
                                   const SizedBox(width: 8),
                                   const Chip(avatar: Icon(Icons.shield, color: Colors.white, size: 16), label: Text('SEGURIDAD', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
                               ]
                             ],
                           ),
                           const SizedBox(height: 8),
                           const Text('Descripción:', style: TextStyle(fontWeight: FontWeight.bold)),
                           Text(_incident.description),
                           const SizedBox(height: 8),
                           const Divider(),
                           Row(
                             children: [
                               const Icon(Icons.person, size: 16),
                               const SizedBox(width: 4),
                               Text('Reportado por: ${_incident.reportedByName ?? "Desconocido"} (${_incident.reportedByUnit ?? "N/A"})'),
                             ],
                           ),
                           if (_incident.createdAt != null)
                             Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(_incident.createdAt!)}'),
                           if (_incident.resolvedAt != null)
                             Text('Resuelto por: ${_incident.resolvedByName} el ${DateFormat('dd/MM/yyyy HH:mm').format(_incident.resolvedAt!)}', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                         ],
                       ),
                     ),
                   ),
                   const SizedBox(height: 16),
                   const Divider(),
                   const Text('Comentarios y Trazabilidad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                   const SizedBox(height: 8),
                   Expanded(
                     child: _incident.comments.isEmpty 
                        ? const Center(child: Text('No hay comentarios'))
                        : ListView.builder(
                           itemCount: _incident.comments.length,
                           itemBuilder: (context, index) {
                             final comment = _incident.comments[index];
                             return ListTile(
                               leading: CircleAvatar(child: Text(comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : 'U')),
                               title: Text(comment.userName),
                               subtitle: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(comment.commentText),
                                   Text(DateFormat('dd/MM/yyyy HH:mm').format(comment.createdAt), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                 ],
                               ),
                             );
                           },
                         ),
                   ),
                   const Divider(),
                   Row(
                     children: [
                       Expanded(
                         child: TextField(
                           controller: _commentController,
                           decoration: const InputDecoration(
                             hintText: 'Escribir comentario...',
                             border: OutlineInputBorder(),
                           ),
                           minLines: 1,
                           maxLines: 3,
                         ),
                       ),
                       const SizedBox(width: 8),
                       IconButton(
                         icon: _isSendingComment ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
                         onPressed: _isSendingComment ? null : _submitComment,
                       ),
                     ],
                   )
                ],
              ),
      ),
      actions: [
        if (_incident.status != IncidentStatus.resuelto)
            ElevatedButton(
                onPressed: () => _updateStatus(IncidentStatus.resuelto),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: const Text('Marcar como Resuelto'),
            ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
