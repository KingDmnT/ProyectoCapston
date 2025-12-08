import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:vecinapp/core/theme/app_theme.dart';
// Importamos la página que genera el QR
import 'package:vecinapp/mobile/screens/generar_qr_visita.dart';
// Importamos la página que escanea el QR
import 'package:vecinapp/mobile/screens/escanear_qr_page.dart';

class VisitasMenuPage extends StatefulWidget {
  const VisitasMenuPage({super.key});

  @override
  State<VisitasMenuPage> createState() => _VisitasMenuPageState();
}

class _VisitasMenuPageState extends State<VisitasMenuPage> {
  int _selectedIndex = 0; 
  String _nombreUsuario = "Residente"; // Valor por defecto

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recuperamos el nombre del usuario si fue pasado
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is String && args.isNotEmpty) {
      _nombreUsuario = args;
    }
  }

  // Función para navegar al formulario de Generar QR
  void _irAFormulario(String tipo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GenerarQrVisitaPage(
          tipoVisita: tipo,
          nombreResidente: _nombreUsuario,
        ),
      ),
    );
  }

  // Función para navegar al Escáner
  void _irAEscaner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EscanearQrPage()),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Gestionar Visitas",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          "Usuario: $_nombreUsuario",
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. LISTA DE OPCIONES
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // --- SECCIÓN DE CONTROL (NUEVO) ---
                  Text(
                    "Control de Acceso",
                    style: GoogleFonts.lato(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  
                  // Botón ESCANEAR QR (Destacado)
                  _VisitOptionCard(
                    label: "Escanear Pase QR",
                    subtitle: "Validar ingreso de visitas",
                    icon: Icons.qr_code_scanner, 
                    color: Colors.purple, // Color diferente para destacar
                    onTap: _irAEscaner, // <--- Llama al escáner
                  ),
                  
                  const SizedBox(height: 25),

                  // --- SECCIÓN DE GENERAR PASES ---
                  Text(
                    "Generar Pase de Visita",
                    style: GoogleFonts.lato(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),

                  // OPCIÓN 1: Visita Propietario
                  _VisitOptionCard(
                    label: "Visita Propietario",
                    subtitle: "Amigos, familiares o conocidos",
                    icon: Icons.person_pin_circle_outlined,
                    color: const Color(0xFF43CE88),
                    onTap: () => _irAFormulario("Visita Propietario"),
                  ),

                  // OPCIÓN 2: Delivery
                  _VisitOptionCard(
                    label: "Proveedor / Delivery",
                    subtitle: "Entregas, Uber, Correos",
                    icon: Icons.local_shipping_outlined,
                    color: const Color(0xFFF0AD4E),
                    onTap: () => _irAFormulario("Proveedor / Delivery"),
                  ),

                  // OPCIÓN 3: Mantención
                  _VisitOptionCard(
                    label: "Mantención",
                    subtitle: "Gasfiter, Eléctrico, Internet",
                    icon: Icons.build_circle_outlined,
                    color: const Color(0xFF5BC0DE),
                    onTap: () => _irAFormulario("Mantención"),
                  ),

                  // OPCIÓN 4: Bloqueo
                  _VisitOptionCard(
                    label: "No Autorizada / Bloqueo",
                    subtitle: "Registrar restricción de acceso",
                    icon: Icons.block_flipped,
                    color: const Color(0xFFD9534F),
                    onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Función de bloqueo en desarrollo"))
                        );
                    },
                  ),

                  // OPCIÓN 5: Otros
                  _VisitOptionCard(
                    label: "Otros",
                    subtitle: "Casos especiales",
                    icon: Icons.more_horiz_outlined,
                    color: AppColors.primary,
                    onTap: () => _irAFormulario("Otros"),
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
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(.1),
            )
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
class _VisitOptionCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _VisitOptionCard({
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
                        color: Color(0xFF333333)
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
