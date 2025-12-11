import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:vecinapp/core/theme/app_theme.dart';
import 'package:vecinapp/core/models/incident.dart';
import 'package:vecinapp/core/services/incident_service.dart';
import 'package:vecinapp/core/services/auth_service.dart';

class ReportarIncidentePage extends StatefulWidget {
  final String categoria; // [NUEVO] Recibimos la categoría seleccionada

  const ReportarIncidentePage({super.key, required this.categoria});

  @override
  State<ReportarIncidentePage> createState() => _ReportarIncidentePageState();
}

class _ReportarIncidentePageState extends State<ReportarIncidentePage> {
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _incidentService = IncidentService();
  bool _isLoading = false;
  
  // Mapear categoría de texto a enum
  IncidentCategory _mapCategory(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'instalaciones':
        return IncidentCategory.instalaciones;
      case 'seguridad':
        return IncidentCategory.seguridad;
      case 'limpieza':
        return IncidentCategory.limpieza;
      case 'ruido':
        return IncidentCategory.ruido;
      default:
        return IncidentCategory.otro;
    }
  }

  Future<void> _enviarReporte() async {
    if (_tituloCtrl.text.trim().isEmpty || _descripcionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor complete todos los campos"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user == null) {
        throw Exception("Usuario no autenticado");
      }

      // Obtener el communityId del usuario
      final userData = await authService.getCurrentUserData();
      // Intentar obtener de communityId directo, o del primer membership
      final communityId = userData?.communityId ?? 
                         (userData?.memberships.isNotEmpty == true 
                           ? userData!.memberships[0].communityId 
                           : '');
      
      if (communityId.isEmpty) {
        throw Exception("No se pudo obtener la comunidad del usuario");
      }

      final newIncident = Incident(
        id: '', // Se generará en el backend
        title: _tituloCtrl.text.trim(),
        description: _descripcionCtrl.text.trim(),
        category: _mapCategory(widget.categoria),
        priority: IncidentPriority.media,
        status: IncidentStatus.pendiente,
        communityId: communityId,
        createdBy: user.uid,
        createdAt: DateTime.now(),
      );

      // Crear incidente (notifica automáticamente a los admins)
      await _incidentService.createIncident(newIncident);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Incidente reportado. Los administradores han sido notificados."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al enviar reporte: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  Expanded( // Expanded para evitar overflow si el texto es largo
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Reportar Incidente",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        // Mostramos la categoría recibida como subtítulo
                        Text(
                          widget.categoria, 
                          style: const TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. FORMULARIO SIMPLIFICADO
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
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título dinámico según la categoría
                          Text(
                            "Detalles de: ${widget.categoria}", 
                            style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])
                          ),
                          const SizedBox(height: 20),

                          // Título del Incidente
                          TextField(
                            controller: _tituloCtrl,
                            decoration: _inputDecoration("Título Breve (Ej: Portón atascado)", Icons.title),
                          ),
                          const SizedBox(height: 15),

                          // Descripción Detallada
                          TextField(
                            controller: _descripcionCtrl,
                            maxLines: 4,
                            decoration: _inputDecoration("Descripción Detallada", Icons.description).copyWith(
                              alignLabelWithHint: true,
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Botón Foto
                          OutlinedButton.icon(
                            onPressed: () {
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Función de cámara en desarrollo")));
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text("Adjuntar Foto"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Botón Enviar
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _enviarReporte,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text("Enviar Reporte", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Barra Navegación (Visual)
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
              selectedIndex: 0, 
              onTabChange: (index) {
                if (index == 0) Navigator.popUntil(context, ModalRoute.withName('/home'));
              },
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}
