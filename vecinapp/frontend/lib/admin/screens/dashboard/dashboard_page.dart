import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vecinapp/core/services/auth_service.dart';
import 'package:vecinapp/admin/screens/communities/communities_screen.dart';
import 'package:vecinapp/admin/screens/users/users_screen.dart';
import 'package:vecinapp/admin/screens/maintenance/maintenance_screen.dart';
import 'package:vecinapp/admin/screens/common_expenses/common_expenses_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

/// Dashboard administrativo con diseño corporativo morado y datos reales
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _userName = 'Administrador';
  String _communityName = 'Cargando...';
  String? _communityId;
  
  @override
  void initState() {
    super.initState();
    _loadUserAndCommunityData();
  }
  
  Future<void> _loadUserAndCommunityData() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        // Obtener datos del usuario
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          // Probar ambos formatos de campo
          final firstName = userData?['firstName'] as String? ?? userData?['first_name'] as String? ?? '';
          final lastName = userData?['lastName'] as String? ?? userData?['last_name'] as String? ?? '';
          final communityId = userData?['community_id'] as String? ?? userData?['communityId'] as String?;
          
          setState(() {
            if (firstName.isNotEmpty && lastName.isNotEmpty) {
              _userName = '$firstName $lastName'.trim();
            } else if (firstName.isNotEmpty) {
              _userName = firstName;
            } else {
              _userName = user.email?.split('@').first ?? 'Administrador';
            }
            _communityId = communityId; // Guardar para pasar al hijo
          });
          
          // Obtener nombre de la comunidad
          if (communityId != null) {
            final communityDoc = await _firestore.collection('communities').doc(communityId).get();
            if (communityDoc.exists) {
              final communityData = communityDoc.data();
              setState(() {
                _communityName = communityData?['name'] as String? ?? 'Tu Condominio';
              });
            }
          }
        }
      } catch (e) {
        print('Error cargando datos de usuario/comunidad: $e');
      }
    }
  }

  // Colores corporativos
  static const primaryPurple = Color(0xFF7B4FFF);
  static const purpleDark = Color(0xFF6A3DE8);
  static const accentGreen = Color(0xFF00D9A3);
  static const accentYellow = Color(0xFFFFB800);
  static const warningRed = Color(0xFFFF5252);

  List<Widget> get _views => [
    _DashboardView(communityId: _communityId),
    const CommunitiesScreen(),
    const UsersScreen(),
    const MaintenanceScreen(),
    const CommonExpensesScreen(),
    const Center(child: Text("Gestión de Visitas (Próximamente)")),
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          // Sidebar morado
          _buildPurpleSidebar(),
          
          // Contenido principal
          Expanded(
            child: Column(
              children: [
                // Header morado
                _buildPurpleHeader(),
                
                // Área de contenido
                Expanded(
                  child: _views[_selectedIndex],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurpleSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primaryPurple, purpleDark],
        ),
      ),
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  child: Image.asset(
                    'assets/images/LogoBcoSinFondo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 20),
          
          // Menú items
          _buildMenuItem(0, Icons.home, 'Inicio'),
          _buildMenuItem(1, Icons.location_city, 'Comunidades'),
          _buildMenuItem(2, Icons.people, 'Usuarios'),
          _buildMenuItem(3, Icons.build, 'Mantenimiento'),
          _buildMenuItem(4, Icons.receipt_long, 'Gastos Comunes'),
          _buildMenuItem(5, Icons.qr_code_scanner, 'Visitas'),
          
          const Spacer(),
          
          // Botón cerrar sesión
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: TextButton.icon(
              icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
              label: Text(
                'Cerrar Sesión',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
              onPressed: () async {
                await _authService.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPurpleHeader() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [primaryPurple, purpleDark],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Hola, ${_userName.split(' ').first}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _communityName,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 28),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

// Vista del dashboard con datos reales de Firebase
class _DashboardView extends StatefulWidget {
  final String? communityId;
  
  const _DashboardView({this.communityId});

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  static const primaryPurple = Color(0xFF7B4FFF);
  static const accentGreen = Color(0xFF00D9A3);
  static const accentYellow = Color(0xFFFFB800);
  static const warningRed = Color(0xFFFF5252);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? get _communityId => widget.communityId;

  @override
  Widget build(BuildContext context) {
    if (_communityId == null) {
      return const Center(child: CircularProgressIndicator(color: primaryPurple));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPIs superiores
          _buildKPIRow(),
          
          const SizedBox(height: 24),
          
          // Gráfico de gastos comunes por mes
          _buildMonthlyExpensesChart(),
          
          const SizedBox(height: 24),
          
          // Fila: Morosidad y Próximos Mantenimientos
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildMorosidadCard()),
              const SizedBox(width: 20),
              Expanded(child: _buildProximosMantenimientosCard()),
            ],
          ),
        ],
      ),
    );
  }

  // KPIs: Residentes activos, Unidades vigentes, Gastos notificados
  Widget _buildKPIRow() {
    return Row(
      children: [
        Expanded(child: _buildResidentesActivosKPI()),
        const SizedBox(width: 16),
        Expanded(child: _buildUnidadesVigentesKPI()),
        const SizedBox(width: 16),
        Expanded(child: _buildGastosNotificadosKPI()),
      ],
    );
  }

  Widget _buildResidentesActivosKPI() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .where('role', isEqualTo: 'resident')
          .snapshots(),
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) {
          // Filtrar residentes que tienen memberships en esta comunidad
          count = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final memberships = data['memberships'] as List<dynamic>? ?? [];
            return memberships.any((membership) {
              final membershipMap = membership as Map<String, dynamic>;
              return membershipMap['community_id'] == _communityId;
            });
          }).length;
        }
        return _buildKPICard(
          title: 'Residentes Activos',
          value: count.toString(),
          icon: Icons.people,
          color: primaryPurple,
        );
      },
    );
  }

  Widget _buildUnidadesVigentesKPI() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('communities')
          .doc(_communityId)
          .collection('units')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return _buildKPICard(
          title: 'Unidades Vigentes',
          value: count.toString(),
          icon: Icons.apartment,
          color: accentGreen,
        );
      },
    );
  }

  Widget _buildGastosNotificadosKPI() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('communities')
          .doc(_communityId)
          .collection('common_expenses')
          .where('status', isEqualTo: 'notified')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return _buildKPICard(
          title: 'Gastos Notificados',
          value: count.toString(),
          icon: Icons.check_circle,
          color: accentGreen,
        );
      },
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Gráfico de gastos comunes por mes (últimos 12 meses)
  Widget _buildMonthlyExpensesChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gastos Comunes Generados (Últimos 12 Meses)',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('communities')
                    .doc(_communityId)
                    .collection('common_expenses')
                    .orderBy('year', descending: true)
                    .orderBy('month', descending: true)
                    .limit(12)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: primaryPurple));
                  }

                  final expenses = snapshot.data!.docs;
                  if (expenses.isEmpty) {
                    return Center(
                      child: Text(
                        'No hay gastos comunes registrados',
                        style: GoogleFonts.inter(color: Colors.grey[600]),
                      ),
                    );
                  }

                  // Preparar datos para el gráfico de barras
                  final barGroups = <BarChartGroupData>[];
                  final months = <String>[];
                  
                  for (int i = expenses.length - 1; i >= 0; i--) {
                    final data = expenses[i].data() as Map<String, dynamic>;
                    final month = data['month'] as int;
                    final total = (data['total_amount'] as num?)?.toDouble() ?? 0.0;
                    
                    barGroups.add(
                      BarChartGroupData(
                        x: expenses.length - 1 - i,
                        barRods: [
                          BarChartRodData(
                            toY: total,
                            color: primaryPurple,
                            width: 16,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    );
                    months.add('${_getMonthAbbr(month)}');
                  }

                  final maxY = barGroups.isEmpty ? 0.0 : barGroups.map((g) => g.barRods.first.toY).reduce((a, b) => a > b ? a : b);

                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY * 1.2,
                      minY: 0,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY > 0 ? maxY / 4 : 100000,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[200]!,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= months.length) return const Text('');
                              return Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  months[index],
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            interval: maxY > 0 ? maxY / 4 : 100000,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Text(
                                '\$${NumberFormat.compact().format(value)}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: barGroups,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => primaryPurple.withOpacity(0.8),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '\$${NumberFormat('#,###').format(rod.toY)}',
                              GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tarjeta de morosidad
  Widget _buildMorosidadCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('communities')
              .doc(_communityId)
              .collection('common_expenses')
              .where('status', isEqualTo: 'notified')
              .snapshots(),
          builder: (context, snapshot) {
            int unidadesEnMora = 0;
            double montoMorosidad = 0.0;

            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final unitExpenses = data['unit_expenses'] as List<dynamic>? ?? [];
                
                for (var unitExp in unitExpenses) {
                  final isPaid = unitExp['is_paid'] as bool? ?? false;
                  if (!isPaid) {
                    unidadesEnMora++;
                    montoMorosidad += (unitExp['amount'] as num?)?.toDouble() ?? 0.0;
                  }
                }
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Morosidad',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: warningRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.warning_amber, color: warningRed, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$unidadesEnMora',
                            style: GoogleFonts.inter(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: warningRed,
                            ),
                          ),
                          Text(
                            'Unidades en Mora',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Monto: \$${NumberFormat('#,###').format(montoMorosidad)}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Próximos Mantenimientos
  Widget _buildProximosMantenimientosCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build_circle, color: accentGreen, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Próximos Mantenimientos',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('communities')
                  .doc(_communityId)
                  .collection('maintenances')
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Error cargando mantenimientos: ${snapshot.error}');
                  return Text(
                    'Error al cargar mantenimientos',
                    style: GoogleFonts.inter(color: Colors.red),
                  );
                }
                
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: primaryPurple));
                }

                final maintenances = snapshot.data!.docs;
                if (maintenances.isEmpty) {
                  return Text(
                    'No hay mantenimientos pendientes',
                    style: GoogleFonts.inter(color: Colors.grey[600]),
                  );
                }

                return Column(
                  children: maintenances.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title'] as String? ?? 'Sin título';
                    final frequency = data['frequency'] as String? ?? 'No definida';
                    final cost = (data['cost'] as num?)?.toDouble() ?? 0.0;
                    final scheduledDate = (data['scheduled_date'] as Timestamp?)?.toDate();
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: accentGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${scheduledDate != null ? DateFormat('dd/MM/yyyy').format(scheduledDate) : frequency} - \$${NumberFormat('#,###').format(cost)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return months[month - 1];
  }
}
