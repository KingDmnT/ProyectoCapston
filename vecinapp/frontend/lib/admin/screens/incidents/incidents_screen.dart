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
  List<Incident> _incidents = [];
  bool _isLoading = true;
  String? _error;
  String? _filterStatus;
  String? _communityId;

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
        _incidents = incidents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Incidentes'),
        backgroundColor: AppColors.primary,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _filterStatus = value == 'all' ? null : value);
              _loadIncidents();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Todos')),
              const PopupMenuItem(value: 'pendiente', child: Text('Pendientes')),
              const PopupMenuItem(value: 'en_proceso', child: Text('En Proceso')),
              const PopupMenuItem(value: 'resuelto', child: Text('Resueltos')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _incidents.isEmpty
                  ? const Center(child: Text('No hay incidentes'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Título')),
                            DataColumn(label: Text('Categoría')),
                            DataColumn(label: Text('Estado')),
                            DataColumn(label: Text('Prioridad')),
                            DataColumn(label: Text('Fecha')),
                            DataColumn(label: Text('Acciones')),
                          ],
                          rows: _incidents.map((incident) {
                            return DataRow(
                              cells: [
                                DataCell(Text(incident.id.substring(0, 8))),
                                DataCell(
                                  SizedBox(
                                    width: 200,
                                    child: Text(
                                      incident.title,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(Text(incident.category.displayName)),
                                DataCell(_StatusChip(status: incident.status)),
                                DataCell(Text(incident.priority.displayName)),
                                DataCell(Text(
                                  DateFormat('dd/MM/yy').format(incident.createdAt ?? DateTime.now()),
                                )),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: AppColors.primary),
                                    onPressed: () => _showUpdateDialog(incident),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IncidentStatus status;

  const _StatusChip({required this.status});

  Color _getColor() {
    switch (status) {
      case IncidentStatus.pendiente:
        return Colors.orange;
      case IncidentStatus.enProceso:
        return Colors.blue;
      case IncidentStatus.resuelto:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getColor()),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: _getColor(),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
