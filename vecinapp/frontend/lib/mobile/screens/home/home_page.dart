import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:vecinapp/core/theme/app_theme.dart';
import 'package:vecinapp/core/services/auth_service.dart';

// Pantalla principal móvil (para residentes)
class MobileHomePage extends StatefulWidget {
  const MobileHomePage({super.key});

  @override
  State<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends State<MobileHomePage> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();

  List<Widget> _buildScreens() {
    return [
      const _DashboardTab(),
      const Center(child: Text("Pantalla de Reservas")),
      const _MenuTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
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

// Tab principal con dashboard
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final user = authService.currentUser;
    final String nombre = user?.displayName ?? 'Usuario';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado azul
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
                  child: Text(
                    nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hola, $nombre",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white
                      ),
                    ),
                    const Text(
                      'Tu Condominio',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Carrusel de noticias
          const _NewsCarousel(),

          const SizedBox(height: 25),

          // Tarjeta de gasto común
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _GastoComunCard(),
          ),

          const SizedBox(height: 20),

          // Accesos rápidos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Accesos Rápidos",
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                fontSize: 16
              ),
            ),
          ),
          const SizedBox(height: 15),

          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _QuickActionButton(
                  icon: Icons.build_circle_outlined,
                  label: "Incidentes",
                  onTap: () {
                    Navigator.pushNamed(context, '/mobile/incidentes');
                  },
                ),
                _QuickActionButton(
                  icon: Icons.edit_outlined,
                  label: "Visitas",
                  onTap: () {
                    Navigator.pushNamed(context, '/mobile/visitas');
                  },
                ),
                _QuickActionButton(
                  icon: Icons.calendar_today_outlined,
                  label: "Reservar",
                  onTap: () {
                    Navigator.pushNamed(context, '/mobile/reservas');
                  },
                ),
                _QuickActionButton(
                  icon: Icons.videocam_outlined,
                  label: "Cámaras",
                  onTap: () {
                    Navigator.pushNamed(context, '/mobile/camaras');
                  },
                ),
                _QuickActionButton(
                  icon: Icons.receipt_long_outlined,
                  label: "Cartola",
                  onTap: () {
                    print('📍 Click en Cartola');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cartola - En desarrollo')),
                    );
                  },
                ),
                _QuickActionButton(
                  icon: Icons.credit_card,
                  label: "Mis datos",
                  onTap: () {
                    Navigator.pushNamed(context, '/mobile/perfil');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// Tab de menú con opciones del residente
class _MenuTab extends StatelessWidget {
  const _MenuTab();

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            "Menú",
            style: GoogleFonts.lato(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          ListTile(
            leading: const Icon(Icons.person, color: AppColors.primary),
            title: const Text("Mi Perfil"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, '/mobile/perfil');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings, color: AppColors.primary),
            title: const Text("Configuración"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
               print('📍 Click en Configuración');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configuración - En desarrollo')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help, color: AppColors.primary),
            title: const Text("Ayuda"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              print('📍 Click en Ayuda');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ayuda - En desarrollo')),
              );
            },
          ),
          const Divider(),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text("Cerrar Sesión"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget de acción rápida
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
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

// Tarjeta de gasto común
class _GastoComunCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tu total a pagar es de",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "\$ 45.593",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                ),
                child: const Text(
                  "Pagar",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 15),
          Divider(color: Colors.grey[700]),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Gasto común diciembre 2025",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(Icons.download_rounded, color: Colors.white70)
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            "Vencimiento: 28-12-2025",
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// Carrusel de noticias
class _NewsCarousel extends StatelessWidget {
  const _NewsCarousel();

  final List<Map<String, dynamic>> news = const [
    {
      'text': 'Asamblea General\nEste Viernes 18:00',
      'colors': [Color(0xFF2F3DBE), Color(0xFF6A75E6)],
      'icon': Icons.groups,
    },
    {
      'text': 'Mantención Piscina\nCerrada por limpieza',
      'colors': [Color(0xFFFF9966), Color(0xFFFF5E62)],
      'icon': Icons.pool,
    },
    {
      'text': 'Gastos Comunes\nVencimiento día 28',
      'colors': [Color(0xFF11998e), Color(0xFF38ef7d)],
      'icon': Icons.attach_money,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: CarouselSlider.builder(
        itemCount: news.length,
        itemBuilder: (context, index, realIndex) {
          final item = news[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: item['colors'] as List<Color>,
              ),
              boxShadow: [
                BoxShadow(
                  color: (item['colors'] as List<Color>)[0].withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(item['icon'] as IconData, color: Colors.white, size: 40),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item['text'] as String,
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
                            Text(
                              "Ver más",
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white70,
                              size: 16,
                            )
                          ],
                        )
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
        ),
      ),
    );
  }
}
