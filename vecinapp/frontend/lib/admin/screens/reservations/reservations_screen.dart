import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vecinapp/core/theme/app_theme.dart';
import 'package:vecinapp/core/models/reservation.dart';
import 'package:vecinapp/core/services/reservation_service.dart';
import 'package:vecinapp/core/services/auth_service.dart';
import 'package:intl/intl.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  final _reservationService = ReservationService();
  List<Reservation> _allReservations = [];
  bool _isLoading = true;
  String? _communityId;
  String? _filterStatus;
  
  // Search and Pagination
  String _searchQuery = '';
  int _rowsPerPage = 10;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = await authService.getCurrentUserData();
      
      _communityId = userData?.communityId ?? 
                     (userData?.memberships.isNotEmpty == true 
                       ? userData!.memberships[0].communityId 
                       : '');

      final reservations = await _reservationService.getReservations(
        communityId: _communityId!,
      );

      setState(() {
        _allReservations = reservations;
        _isLoading = false;
        _currentPage = 0;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  List<Reservation> get _filteredReservations {
    var filtered = _allReservations.where((reservation) {
      // Filtro por estado
      if (_filterStatus != null && reservation.status.name != _filterStatus) {
        return false;
      }
      
      // Filtro por búsqueda
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return reservation.spaceType.displayName.toLowerCase().contains(query) ||
             reservation.purpose.toLowerCase().contains(query);
    }).toList();
    
    return filtered;
  }
  
  List<Reservation> get _paginatedReservations {
    final filtered = _filteredReservations;
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, filtered.length);
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end);
  }
  
  int get _totalPages => (_filteredReservations.length / _rowsPerPage).ceil();

  Future<void> _updateReservation(Reservation reservation, ReservationStatus newStatus, String? notes) async {
    try {
      await _reservationService.updateReservation(
        communityId: _communityId!,
        reservationId: reservation.id,
        status: newStatus,
        adminNotes: notes,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva actualizada. Residente notificado.')),
      );
      
      _loadReservations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showUpdateDialog(Reservation reservation) {
    final notesController = TextEditingController(text: reservation.adminNotes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Gestionar Reserva: ${reservation.spaceType.displayName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fecha: ${DateFormat('dd/MM/yyyy').format(reservation.date)}'),
              Text('Horario: ${reservation.startTime} - ${reservation.endTime}'),
              Text('Propósito: ${reservation.purpose}'),
              Text('Asistentes: ${reservation.attendees}'),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          if (reservation.status == ReservationStatus.pendiente) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateReservation(reservation, ReservationStatus.rechazada, notesController.text);
              },
              child: const Text('Rechazar', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateReservation(reservation, ReservationStatus.aprobada, notesController.text);
              },
              child: const Text('Aprobar'),
            ),
          ],
        ],
      ),
    );
  }
  
  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pendiente:
        return Colors.orange;
      case ReservationStatus.aprobada:
        return Colors.green;
      case ReservationStatus.rechazada:
        return Colors.red;
      case ReservationStatus.cancelada:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestión de Reservas'),
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
                      DropdownMenuItem(value: 'aprobada', child: Text('Aprobadas')),
                      DropdownMenuItem(value: 'rechazada', child: Text('Rechazadas')),
                      DropdownMenuItem(value: 'cancelada', child: Text('Canceladas')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterStatus = value;
                        _currentPage = 0;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Buscar',
                      hintText: 'Espacio, propósito...',
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
                        : _paginatedReservations.isEmpty
                            ? const Center(child: Text('No hay reservas para mostrar'))
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
                                          flex: 2,
                                          child: Text('Espacio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          flex: 2,
                                          child: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          flex: 2,
                                          child: Text('Horario', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          flex: 2,
                                          child: Text('Propósito', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          flex: 2,
                                          child: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                                      itemCount: _paginatedReservations.length,
                                      itemBuilder: (context, index) {
                                        final reservation = _paginatedReservations[index];
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                                          ),
                                          child: Row(
                                            children: [
                                              // Espacio
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  reservation.spaceType.displayName,
                                                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Fecha
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  DateFormat('dd/MM/yyyy').format(reservation.date),
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Horario
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  '${reservation.startTime} - ${reservation.endTime}',
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Propósito
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  reservation.purpose,
                                                  style: const TextStyle(fontSize: 11),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
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
                                                      color: _getStatusColor(reservation.status).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: _getStatusColor(reservation.status)),
                                                    ),
                                                    child: Text(
                                                      reservation.status.displayName,
                                                      style: TextStyle(
                                                        color: _getStatusColor(reservation.status),
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
                                              // Acciones
                                              Expanded(
                                                flex: 1,
                                                child: IconButton(
                                                  icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                                                  onPressed: () => _showUpdateDialog(reservation),
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
                          'Mostrando ${_paginatedReservations.isEmpty ? 0 : _currentPage * _rowsPerPage + 1}-${(_currentPage * _rowsPerPage + _paginatedReservations.length).clamp(0, _filteredReservations.length)} de ${_filteredReservations.length}',
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
