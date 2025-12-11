import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vecinapp/core/theme/app_theme.dart';
import 'package:vecinapp/core/models/incident.dart';
import 'package:vecinapp/core/services/incident_service.dart';
import 'package:vecinapp/core/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:vecinapp/mobile/screens/incident_detail_page.dart';

class MisIncidentesPage extends StatefulWidget {
  const MisIncidentesPage({super.key});

  @override
  State<MisIncidentesPage> createState() => _MisIncidentesPageState();
}

class _MisIncidentesPageState extends State<MisIncidentesPage> {
  final _incidentService = IncidentService();
  List<Incident> _incidents = [];
  bool _isLoading = true;
  String? _error;
  String _filterType = 'mine'; // 'mine' or 'all'

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      final userData = await authService.getCurrentUserData();
      
      if (user == null || userData == null) {
        throw Exception("Usuario no autenticado");
      }

      final communityId = userData.communityId ?? 
                         (userData.memberships.isNotEmpty 
                           ? userData.memberships[0].communityId 
                           : '');

      // Si el filtro es 'mine', enviamos el ID. Si es 'all', enviamos null.
      final createdBy = _filterType == 'mine' ? user.uid : null;

      final incidents = await _incidentService.getIncidents(
        communityId: communityId,
        createdBy: createdBy,
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

  IconData _getCategoryIcon(IncidentCategory category) {
    switch (category) {
      case IncidentCategory.instalaciones:
        return Icons.build;
      case IncidentCategory.seguridad:
        return Icons.security;
      case IncidentCategory.limpieza:
        return Icons.cleaning_services;
      case IncidentCategory.ruido:
        return Icons.volume_off;
      case IncidentCategory.otro:
        return Icons.report_problem;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Incidentes'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filtro Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                const Text('Ver:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filterType,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'mine', child: Text('Mis Incidentes')),
                          DropdownMenuItem(value: 'all', child: Text('Toda la Comunidad')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _filterType = value);
                            _loadIncidents();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      ElevatedButton(
                        onPressed: _loadIncidents,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _incidents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No has reportado incidentes',
                            style: GoogleFonts.lato(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadIncidents,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _incidents.length,
                        itemBuilder: (context, index) {
                          final incident = _incidents[index];
                          return _IncidentCard(
                            incident: incident,
                            statusColor: _getStatusColor(incident.status),
                            categoryIcon: _getCategoryIcon(incident.category),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      );
  }
}

class _IncidentCard extends StatelessWidget {
  final Incident incident;
  final Color statusColor;
  final IconData categoryIcon;

  const _IncidentCard({
    required this.incident,
    required this.statusColor,
    required this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            // Navegar a detalle
            final authService = Provider.of<AuthService>(context, listen: false);
            final userData = await authService.getCurrentUserData();
            
            final communityId = userData?.communityId ?? 
                               (userData?.memberships.isNotEmpty == true 
                                 ? userData!.memberships[0].communityId 
                                 : '');
            
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IncidentDetailPage(
                    incidentId: incident.id,
                    communityId: communityId,
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(categoryIcon, color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            incident.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            incident.category.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        incident.status.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  incident.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(incident.createdAt ?? DateTime.now()),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const Spacer(),
                    if (incident.comments.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.message, size: 14, color: Colors.blue[700]),
                            const SizedBox(width: 4),
                            Text(
                              '${incident.comments.length} ${incident.comments.length == 1 ? 'comentario' : 'comentarios'}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
