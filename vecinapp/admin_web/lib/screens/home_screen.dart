import 'package:flutter/material.dart';
import 'package:admin_web/theme/app_theme.dart';
import 'package:admin_web/screens/dashboard_screen.dart';
import 'package:admin_web/screens/communities/communities_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:admin_web/main.dart'; // Para LoginPage

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Lista de Vistas
  final List<Widget> _views = [
    const DashboardView(),      // Vista interna del Dashboard
    const CommunitiesScreen(),  // Vista de Comunidades
    const Center(child: Text("Gestión de Usuarios (Próximamente)")),
    const Center(child: Text("Gestión de Visitas (Próximamente)")),
  ];
  
  final List<String> _titles = [
    "Dashboard General",
    "Gestión de Comunidades",
    "Gestión de Usuarios",
    "Gestión de Visitas"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Row(
        children: [
          // --- Sidebar ---
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            backgroundColor: Colors.white,
            elevation: 1,
            extended: true, // Sidebar expandido para ver textos
            minExtendedWidth: 200,
            indicatorColor: AppTheme.primaryColor.withOpacity(0.1),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.security, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "VecinApp",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
                  )
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryColor),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.location_city_outlined),
                selectedIcon: Icon(Icons.location_city, color: AppTheme.primaryColor),
                label: Text('Comunidades'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people, color: AppTheme.primaryColor),
                label: Text('Usuarios'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.qr_code_scanner_outlined),
                selectedIcon: Icon(Icons.qr_code, color: AppTheme.primaryColor),
                label: Text('Visitas'),
              ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: TextButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.red, size: 20),
                    label: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
          
          // --- Contenido Principal ---
          Expanded(
            child: Column(
              children: [
                // Topbar
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _titles[_selectedIndex],
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 16,
                              backgroundColor: AppTheme.primaryColor,
                              child: Text("SA", style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Super Admin", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text("admin@vecinapp.cl", style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                
                // Área de Vistas
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: _views[_selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Vista Dashboard interna (sin Scaffold)
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4, // Más ancho en desktop
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(context, 'Comunidades', '12', Icons.location_city, Colors.blue),
        _buildStatCard(context, 'Usuarios', '1,250', Icons.people, Colors.orange),
        _buildStatCard(context, 'Visitas Hoy', '45', Icons.qr_code, Colors.green),
        _buildStatCard(context, 'Alertas', '3', Icons.warning, Colors.red),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0, // Flat style
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
