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
  List<Reservation> _reservations = [];
  bool _isLoading = true;
  String? _communityId;

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
        _reservations = reservations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Reservas'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reservations.isEmpty
              ? const Center(child: Text('No hay reservas'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Espacio')),
                        DataColumn(label: Text('Fecha')),
                        DataColumn(label: Text('Horario')),
                        DataColumn(label: Text('Estado')),
                        DataColumn(label: Text('Acciones')),
                      ],
                      rows: _reservations.map((reservation) {
                        return DataRow(
                          cells: [
                            DataCell(Text(reservation.spaceType.displayName)),
                            DataCell(Text(DateFormat('dd/MM/yy').format(reservation.date))),
                            DataCell(Text('${reservation.startTime} - ${reservation.endTime}')),
                            DataCell(_StatusChip(status: reservation.status)),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.edit, color: AppColors.primary),
                                onPressed: () => _showUpdateDialog(reservation),
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
  final ReservationStatus status;

  const _StatusChip({required this.status});

  Color _getColor() {
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
