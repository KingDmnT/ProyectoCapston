import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:vecinapp/core/theme/app_theme.dart';
// Importamos la pantalla del formulario
import 'reservar_espacio_page.dart'; 

class ReservasMenuPage extends StatefulWidget {
  const ReservasMenuPage({super.key});

  @override
  State<ReservasMenuPage> createState() => _ReservasMenuPageState();
}

class _ReservasMenuPageState extends State<ReservasMenuPage> {
  int _selectedIndex = 1; // Reservas es el índice 1
  
  // Nombre del usuario por defecto para este caso
  final String _nombreUsuario = "Carlos Pérez";

  // Función para ir a la pantalla de reserva
  void _irAReserva(String espacio) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservarEspacioPage(
          nombreEspacio: espacio,
          nombreUsuario: _nombreUsuario, // Pasamos "Carlos Pérez"
        ),
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
            // 1. ENCABEZADO AZUL
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
                    "Reservar Espacio",
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. LISTA DE ESPACIOS COMUNES
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Text(
                    "Espacios Disponibles",
                    style: GoogleFonts.lato(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 14
                    ),
                  ),
                  const SizedBox(height: 15),

                  _ReservaOptionCard(
                    label: "Sede Social / Salón",
                    subtitle: "Para eventos, cumpleaños y reuniones",
                    icon: Icons.store_mall_directory_outlined,
                    color: const Color(0xFF6A75E6),
                    // CONECTADO:
                    onTap: () => _irAReserva("Sede Social"),
                  ),
                  _ReservaOptionCard(
                    label: "Quincho",
                    subtitle: "Zona de asados y parrilla",
                    icon: Icons.outdoor_grill_outlined,
                    color: const Color(0xFFFF9966),
                    // CONECTADO:
                    onTap: () => _irAReserva("Quincho"),
                  ),
                  _ReservaOptionCard(
                    label: "Multicancha",
                    subtitle: "Fútbol, Básquetbol y deportes",
                    icon: Icons.sports_soccer,
                    color: const Color(0xFF43CE88),
                    // CONECTADO:
                    onTap: () => _irAReserva("Multicancha"),
                  ),
                  _ReservaOptionCard(
                    label: "Piscina",
                    subtitle: "Zona de piscina y reposeras",
                    icon: Icons.pool,
                    color: Colors.lightBlue,
                    // CONECTADO:
                    onTap: () => _irAReserva("Piscina"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 3. BARRA DE NAVEGACIÓN
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.1))
          ],
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

// Widget auxiliar para las tarjetas
class _ReservaOptionCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ReservaOptionCard({
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
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13, 
                        color: Colors.grey[500]
                      ),
                    ),
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
