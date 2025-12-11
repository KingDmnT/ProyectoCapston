import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:vecinapp/core/theme/app_theme.dart';
import '../services/local_auth.dart';
import '../models/app_user.dart';

class PaginaPrincipal extends StatefulWidget {
  const PaginaPrincipal({super.key});

  @override
  State<PaginaPrincipal> createState() => _PaginaPrincipalState();
}

class _PaginaPrincipalState extends State<PaginaPrincipal> {
  int _selectedIndex = 0;

  List<Widget> _buildScreens() {
    return [
      const _DashboardTab(),      // 0: Inicio
      const Center(child: Text("Pantalla de Reservas")), // 1: Placeholder
      const Center(child: Text("Pantalla de Menú")),   // 2: Placeholder
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      
      // 1. HEMOS ELIMINADO EL APPBAR COMPLETO AQUÍ
      // (Esto quita tanto el título como el botón de salir)

      // 2. Agregamos SafeArea para que el contenido no quede debajo de la hora/batería
      body: SafeArea(
        top: false, // false porque tu encabezado azul ya maneja el espacio superior visualmente
        bottom: true,
        child: _buildScreens()[_selectedIndex],
      ),

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
                GButton(icon: Icons.table_rows, text: 'Menú'),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// PESTAÑA PRINCIPAL (DASHBOARD)
// ------------------------------------------------------------------
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final arg = (ModalRoute.of(context)?.settings.arguments ?? '') as String?;
    // (Tu lógica de usuario se mantiene igual...)
    AppUser? u;
    String nombre = 'Carlos Pérez';
    // ... simplificado para el ejemplo
    if (arg != null && arg.contains('@')) {
       u = LocalAuth.byEmail(arg);
       if(u!=null) nombre = u.name;
    }

    return SingleChildScrollView( // Importante para que baje si hay pantallas pequeñas
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Encabezado Azul Curvo (Opcional, para darle estilo)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U', 
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Hola, $nombre",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                    const Text('Condominio Conecta Huechuraba', // Texto de tu imagen
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pushNamed(context, '/notificaciones'),
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),


          
          // 3. CARRUSEL DE NOTICIAS
          const Carouselslider(),

          const SizedBox(height: 25),

          // 2. TARJETA DE GASTO COMÚN 
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16), //Ancho de tarjeta 
            child: _GastoComunCard(),
          ),

          const SizedBox(height: 20),

          // 4. NUEVA FILA DE ACCESOS RÁPIDOS 
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text("Accesos Rápidos", style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 15),
          
          // AQUÍ ESTÁ LA MAGIA: Fila desplazable
          SizedBox(
            height: 100, // Altura fija para la fila de botones
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _QuickActionButton(icon: Icons.build_circle_outlined, label: "Incidentes", onTap: () => Navigator.pushNamed(context, '/incidentes')), // Sin ruta aún
                _QuickActionButton(icon: Icons.edit_outlined, label: "Visitas", onTap: () => Navigator.pushNamed(context, '/visitas')),
                _QuickActionButton(icon: Icons.calendar_today_outlined, label: "Reservar", onTap: () => Navigator.pushNamed(context, '/reservas')),
                _QuickActionButton(icon: Icons.videocam_outlined, label: "Cámaras", onTap: () => Navigator.pushNamed(context, '/camaras')),
                _QuickActionButton(icon: Icons.receipt_long_outlined, label: "Cartola", onTap: () {}), // Sin ruta aún
                _QuickActionButton(icon: Icons.credit_card, label: "Mis datos", onTap: () => Navigator.pushNamed(context, '/misdatos2')),
              ],
            ),
          ),
          
          const SizedBox(height: 30), // Espacio final
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// WIDGETS NUEVOS Y REDISEÑADOS
// ------------------------------------------------------------------

// 1. BOTÓN CIRCULAR (Estilo Mis Tarjetas, Visitas, etc.)
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 55,
              width: 55,
              decoration: BoxDecoration(
                color: AppColors.primary, 
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0,2))]
              ),
              child: Icon(icon, color: Colors.white, size: 24), // Icono blanco
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            )
          ],
        ),
      ),
    );
  }
}

// 2. TARJETA DE GASTO COMÚN (Similar a la parte superior de tu imagen)
class _GastoComunCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary, // Fondo oscuro estilo "Dark Mode" de la tarjeta
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Tu total a pagar es de", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("\$ 45.593", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success, // Verde del botón "Pagar"
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                ),
                child: const Text("Pagar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 15),
          Divider(color: Colors.grey[700]),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Gasto común octubre 2025", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              Icon(Icons.download_rounded, color: Colors.white70)
            ],
          ),
          const SizedBox(height: 5),
          const Text("Vencimiento: 28-11-2025", style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}

// 3. LÓGICA DEL CARRUSEL (EXACTAMENTE EL DISEÑO QUE PEDISTE)

class BannerCardModel {
  final String text;
  final String? imagePath;
  final List<Color> cardBackground;
  final IconData icon;

  BannerCardModel({
    required this.text,
    this.imagePath,
    required this.cardBackground,
    required this.icon,
  });
}

List<BannerCardModel> bannerCards = [
  BannerCardModel(
      text: "Asamblea General\nEste Viernes 18:00",
      cardBackground: [AppColors.primary, const Color(0xFF6A75E6)],
      icon: Icons.groups),
  BannerCardModel(
      text: "Mantención Piscina\nCerrada por limpieza",
      cardBackground: [const Color(0xFFFF9966), const Color(0xFFFF5E62)],
      icon: Icons.pool),
  BannerCardModel(
      text: "Gastos Comunes\nVencimiento día 05",
      cardBackground: [const Color(0xFF11998e), const Color(0xFF38ef7d)],
      icon: Icons.attach_money),
];

class Carouselslider extends StatelessWidget {
  const Carouselslider({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140, // Altura ajustada
      width: MediaQuery.of(context).size.width,
      child: CarouselSlider.builder(
        itemCount: bannerCards.length,
        itemBuilder: (context, index, realIndex) {
          final card = bannerCards[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                stops: const [0.3, 0.9],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: card.cardBackground,
              ),
              boxShadow: [
                 BoxShadow(
                  color: card.cardBackground[0].withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text('Clic en: ${card.text}')));
              },
              child: Stack(
                children: [
                  // Icono de fondo decorativo
                  Positioned(
                    left: -20,
                    bottom: -20,
                    child: Icon(
                      card.icon,
                      size: 100,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Icono principal izquierdo
                         Icon(card.icon, color: Colors.white, size: 40),
                        
                        // Texto derecho
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                card.text,
                                textAlign: TextAlign.right,
                                style: GoogleFonts.lato(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text("Ver más", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 16)
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        options: CarouselOptions(
          autoPlay: true,
          enlargeCenterPage: true,
          viewportFraction: 0.75,
          aspectRatio: 2.0,
          initialPage: 0,
        ),
      ),
    );
  }
}
