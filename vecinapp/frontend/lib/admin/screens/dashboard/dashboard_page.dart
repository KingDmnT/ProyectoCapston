import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vecinapp/core/theme/app_theme.dart';
import 'package:vecinapp/core/services/auth_service.dart';
import 'package:vecinapp/admin/screens/communities/communities_screen.dart';
import 'package:vecinapp/admin/screens/users/users_screen.dart';
import 'package:vecinapp/admin/screens/maintenance/maintenance_screen.dart';

// Dashboard principal del administrador (backoffice web)
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();

  final List<Widget> _views = [
    const _DashboardView(),
    const CommunitiesScreen(),
    const UsersScreen(),
    const MaintenanceScreen(),
    const Center(child: Text("Gestión de Visitas (Próximamente)")),
  ];
  
  final List<String> _titles = [
    "Dashboard General",
    "Gestión de Comunidades",
    "Gestión de Usuarios",
    "Gestión de Mantenimientos",
    "Gestión de Visitas"
  ];

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final String userEmail = user?.email ?? '';
    final String initials = userEmail.isNotEmpty 
        ? userEmail.substring(0, 2).toUpperCase()
        : 'AD';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar de navegación
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            backgroundColor: Colors.white,
            elevation: 1,
            extended: true,
            minExtendedWidth: 200,
            indicatorColor: AppColors.primary.withOpacity(0.1),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.security, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "VecinApp",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 18
                    ),
                  )
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.location_city_outlined),
                selectedIcon: Icon(Icons.location_city, color: AppColors.primary),
                label: Text('Comunidades'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people, color: AppColors.primary),
                label: Text('Usuarios'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.build_outlined),
                selectedIcon: Icon(Icons.build, color: AppColors.primary),
                label: Text('Mantenimiento'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.qr_code_scanner_outlined),
                selectedIcon: Icon(Icons.qr_code, color: AppColors.primary),
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
                    label: const Text(
                      "Cerrar Sesión",
                      style: TextStyle(color: Colors.red)
                    ),
                    onPressed: () async {
                      await _authService.signOut();
                      if (mounted) {
                        Navigator.pushReplacementNamed(context, '/');
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
          
          // Contenido principal
          Expanded(
            child: Column(
              children: [
                // Topbar
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _titles[_selectedIndex],
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Administrador",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13
                                  ),
                                ),
                                Text(
                                  userEmail,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 11
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                
                // Área de contenido
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

// Vista de dashboard con estadísticas
class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard('Comunidades', '12', Icons.location_city, Colors.blue),
        _buildStatCard('Usuarios', '1,250', Icons.people, Colors.orange),
        _buildStatCard('Visitas Hoy', '45', Icons.qr_code, Colors.green),
        _buildStatCard('Alertas', '3', Icons.warning, Colors.red),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
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
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
