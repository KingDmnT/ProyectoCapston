import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class CamarasMenuPage extends StatefulWidget {
  const CamarasMenuPage({super.key});

  @override
  State<CamarasMenuPage> createState() => _CamarasMenuPageState();
}

class _CamarasMenuPageState extends State<CamarasMenuPage> {
  int _selectedIndex = 0; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // Fondo gris consistente
      body: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          children: [
            // 1. ENCABEZADO AZUL
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 25),
              decoration: const BoxDecoration(
                color: Color(0xFF2F3DBE),
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
                    "Cámaras de Seguridad",
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // 2. LISTA DE CÁMARAS (VISTA PREVIA)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Text(
                    "Visualización en vivo",
                    style: GoogleFonts.lato(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 14
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Aquí simulamos los feeds de video
                  _CameraFeedCard(
                    cameraName: "Acceso Principal - Vehicular",
                    status: "En Vivo",
                    isOnline: true,
                    onTap: () {
                      // Aquí abrirías el reproductor a pantalla completa
                    },
                  ),
                  _CameraFeedCard(
                    cameraName: "Acceso Peatonal / Lobby",
                    status: "En Vivo",
                    isOnline: true,
                    onTap: () {},
                  ),
                  _CameraFeedCard(
                    cameraName: "Estacionamiento Visitas",
                    status: "Cargando...",
                    isOnline: false, // Ejemplo de cámara offline o cargando
                    onTap: () {},
                  ),
                  _CameraFeedCard(
                    cameraName: "Quincho y Piscina",
                    status: "En Vivo",
                    isOnline: true,
                    onTap: () {},
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
              tabBackgroundColor: const Color(0xFF2F3DBE),
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
                   Navigator.pop(context);
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

// Widget auxiliar: Tarjeta de Video (Simulada)
class _CameraFeedCard extends StatelessWidget {
  final String cameraName;
  final String status;
  final bool isOnline;
  final VoidCallback onTap;

  const _CameraFeedCard({
    required this.cameraName,
    required this.status,
    required this.isOnline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. AREA DE VIDEO (Simulada con un contenedor oscuro)
              Stack(
                children: [
                  Container(
                    height: 180, // Altura 16:9 aprox
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222), // Gris casi negro
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      // Aquí podrías poner una imagen real de fondo con:
                      // image: DecorationImage(image: NetworkImage('url_snapshot'), fit: BoxFit.cover)
                    ),
                    child: Center(
                      child: Icon(
                        Icons.videocam_off_outlined, 
                        color: Colors.white.withOpacity(0.2), 
                        size: 50
                      ),
                    ),
                  ),
                  
                  // Botón de Play superpuesto
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.5))
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
                      ),
                    ),
                  ),

                  // Badge "EN VIVO"
                  if (isOnline)
                    Positioned(
                      top: 15,
                      left: 15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(4)
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: Colors.white),
                            SizedBox(width: 5),
                            Text("EN VIVO", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // 2. DETALLES DEBAJO DEL VIDEO
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cameraName,
                          style: const TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333)
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              isOnline ? Icons.wifi : Icons.wifi_off, 
                              size: 14, 
                              color: isOnline ? Colors.green : Colors.grey
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isOnline ? "Conectado" : "Desconectado",
                              style: TextStyle(
                                fontSize: 12, 
                                color: isOnline ? Colors.green[700] : Colors.grey
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Icon(Icons.fullscreen, color: Colors.grey[600]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
