import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:vecinapp/core/theme/app_theme.dart';

class ReservarEspacioPage extends StatefulWidget {
  final String nombreEspacio; // Ej: "Quincho"
  final String nombreUsuario; // Ej: "Carlos Pérez"

  const ReservarEspacioPage({
    super.key,
    required this.nombreEspacio,
    required this.nombreUsuario,
  });

  @override
  State<ReservarEspacioPage> createState() => _ReservarEspacioPageState();
}

class _ReservarEspacioPageState extends State<ReservarEspacioPage> {
  // Variables para la fecha y hora
  DateTime _fechaSeleccionada = DateTime.now();
  TimeOfDay _horaInicio = const TimeOfDay(hour: 12, minute: 00);
  TimeOfDay _horaFin = const TimeOfDay(hour: 16, minute: 00);
  
  final _comentariosCtrl = TextEditingController();

  // Selector de Fecha
  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)), // Máximo 30 días adelante
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() => _fechaSeleccionada = picked);
    }
  }

  // Selector de Hora
  Future<void> _seleccionarHora(BuildContext context, bool esInicio) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: esInicio ? _horaInicio : _horaFin,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (esInicio) {
          _horaInicio = picked;
        } else {
          _horaFin = picked;
        }
      });
    }
  }

  void _confirmarReserva() {
    // Aquí iría la lógica para guardar en Firebase
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("¡Reserva de ${widget.nombreEspacio} confirmada!"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
    Navigator.pop(context); // Vuelve al menú
  }

  @override
  Widget build(BuildContext context) {
    // Formato de fecha simple para mostrar
    final fechaStr = "${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          children: [
            // 1. ENCABEZADO AZUL
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 25),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Nueva Reserva",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          widget.nombreEspacio, // Muestra "Quincho", "Sede", etc.
                          style: const TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. FORMULARIO
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Detalles de la Reserva", style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                          const SizedBox(height: 20),

                          // Usuario (Solo lectura)
                          _InfoField(label: "Reservado por", value: widget.nombreUsuario, icon: Icons.person),
                          const SizedBox(height: 15),

                          // Selección de Fecha
                          InkWell(
                            onTap: () => _seleccionarFecha(context),
                            borderRadius: BorderRadius.circular(12),
                            child: _InfoField(
                              label: "Fecha", 
                              value: fechaStr, 
                              icon: Icons.calendar_today,
                              isEditable: true,
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Selección de Horas
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _seleccionarHora(context, true),
                                  borderRadius: BorderRadius.circular(12),
                                  child: _InfoField(
                                    label: "Desde",
                                    value: _horaInicio.format(context),
                                    icon: Icons.access_time,
                                    isEditable: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _seleccionarHora(context, false),
                                  borderRadius: BorderRadius.circular(12),
                                  child: _InfoField(
                                    label: "Hasta",
                                    value: _horaFin.format(context),
                                    icon: Icons.access_time_filled,
                                    isEditable: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),

                          // Comentarios Opcionales
                          TextField(
                            controller: _comentariosCtrl,
                            decoration: InputDecoration(
                              labelText: "Comentarios o Invitados (Opcional)",
                              prefixIcon: Icon(Icons.notes, color: AppColors.primary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                            maxLines: 2,
                          ),

                          const SizedBox(height: 30),

                          // Botón Confirmar
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _confirmarReserva,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                              ),
                              child: const Text("Confirmar Reserva", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
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
      ),
      
      // Barra Inferior (Visual)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.1))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8,
              activeColor: Colors.white,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: AppColors.primary,
              color: Colors.grey[600],
              textStyle: GoogleFonts.lato(color: Colors.white),
              tabs: const [
                GButton(icon: Icons.home_filled, text: 'Inicio'),
                GButton(icon: Icons.calendar_month_outlined, text: 'Reservas'),
                GButton(icon: Icons.person_outline, text: 'Perfil'),
              ],
              selectedIndex: 1, // Marcamos Reservas como activo
              onTabChange: (index) {
                if (index == 0) Navigator.popUntil(context, ModalRoute.withName('/home'));
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Widget auxiliar para mostrar campos de solo lectura o seleccionables
class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isEditable;

  const _InfoField({
    required this.label,
    required this.value,
    required this.icon,
    this.isEditable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      decoration: BoxDecoration(
        color: isEditable ? Colors.blue.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEditable ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
          if (isEditable) const Icon(Icons.edit, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
