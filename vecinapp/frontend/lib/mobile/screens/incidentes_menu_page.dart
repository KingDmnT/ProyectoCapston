import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:vecinapp/core/theme/app_theme.dart';
import 'package:vecinapp/mobile/screens/reportar_incidente_page.dart';

class IncidentesMenuPage extends StatefulWidget {
  const IncidentesMenuPage({super.key});

  @override
  State<IncidentesMenuPage> createState() => _IncidentesMenuPageState();
}

class _IncidentesMenuPageState extends State<IncidentesMenuPage> {
  int _selectedIndex = 0; 

  // Función actualizada: Recibe la categoría y la pasa a la siguiente pantalla
  void _irAReporte(String categoria) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportarIncidentePage(categoria: categoria),
      ),
    );
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
            // ENCABEZADO AZUL
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 25),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
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
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Text(
                    "Reportar Incidente",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // LISTA DE CATEGORÍAS
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Text(
                    "Seleccione categoría",
                    style: GoogleFonts.lato(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 15),

                  _IncidenteOptionCard(
                    label: "Ruidos Molestos",
                    subtitle: "Música alta, fiestas fuera de horario",
                    icon: Icons.volume_off_outlined,
                    color: const Color(0xFFE57373), 
                    // Pasamos el texto exacto
                    onTap: () => _irAReporte("Ruidos Molestos"), 
                  ),
                  _IncidenteOptionCard(
                    label: "Falla Infraestructura",
                    subtitle: "Portón, luces, ascensores",
                    icon: Icons.elevator_outlined,
                    color: const Color(0xFFF0AD4E), 
                    onTap: () => _irAReporte("Falla Infraestructura"),
                  ),
                  _IncidenteOptionCard(
                    label: "Seguridad",
                    subtitle: "Actividad sospechosa, portón abierto",
                    icon: Icons.security_outlined,
                    color: const Color(0xFF5BC0DE), 
                    onTap: () => _irAReporte("Seguridad"),
                  ),
                  _IncidenteOptionCard(
                    label: "Limpieza",
                    subtitle: "Espacios comunes sucios, basura",
                    icon: Icons.cleaning_services_outlined,
                    color: Colors.teal, 
                    onTap: () => _irAReporte("Limpieza"),
                  ),
                  _IncidenteOptionCard(
                    label: "Otros",
                    subtitle: "Reportar otro tipo de problema",
                    icon: Icons.report_problem_outlined,
                    color: AppColors.primary, 
                    onTap: () => _irAReporte("Otros"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // BARRA INFERIOR
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
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                if (index == 0) {
                   Navigator.popUntil(context, ModalRoute.withName('/home')); 
                } else {
                   setState(() => _selectedIndex = index);
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _IncidenteOptionCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IncidenteOptionCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
