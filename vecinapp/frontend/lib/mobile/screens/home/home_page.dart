import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:vecinapp/core/services/auth_service.dart';
import 'package:vecinapp/core/theme/app_theme.dart';
import 'package:vecinapp/core/models/user.dart';
import 'package:vecinapp/core/models/announcement.dart';
import 'package:vecinapp/core/models/notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vecinapp/core/services/common_expense_service.dart';
import 'package:vecinapp/core/services/announcement_service.dart';
import 'package:vecinapp/core/services/notification_service.dart';
import 'package:vecinapp/mobile/screens/my_expenses_page.dart';
import 'package:vecinapp/mobile/screens/mis_incidentes_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:timeago/timeago.dart' as timeago;

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
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  final _authService = AuthService();
  final _notificationService = NotificationService();
  String _nombre = '';
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUnreadCount();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      final db = FirebaseFirestore.instance;
      try {
        final doc = await db.collection('users').doc(user.uid).get();
        if (mounted) {
          setState(() {
            _nombre = doc.data()?['firstName'] ?? (user.displayName ?? 'Usuario');
          });
        }
      } catch (e) {
        if (mounted) setState(() => _nombre = user.displayName ?? 'Usuario');
      }
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;
      final db = FirebaseFirestore.instance;
      final userDoc = await db.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return;
      final userData = userDoc.data();
      final communityId = userData?['community_id'] as String? ?? userData?['communityId'] as String?;
      if (communityId != null && communityId.isNotEmpty) {
        final count = await _notificationService.getUnreadCount(communityId: communityId);
        if (mounted) setState(() => _unreadCount = count);
      }
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  void _showNotifications(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _NotificationsModal(),
    );
    _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
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
                    _nombre.isNotEmpty ? _nombre[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hola, $_nombre",
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
                ),
                // Campana de notificaciones
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                      onPressed: () => _showNotifications(context),
                    ),
                    // Badge con número de notificaciones
                    if (_unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '$_unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
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
                  label: "Reportar",
                  onTap: () {
                    Navigator.pushNamed(context, '/mobile/incidentes');
                  },
                ),
                _QuickActionButton(
                  icon: Icons.list_alt,
                  label: "Mis Incidentes",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MisIncidentesPage()),
                    );
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
                ),/*
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
                ),*/
                _QuickActionButton(
                  icon: Icons.credit_card,
                  label: "Mis datos",
                  onTap: () {
                    Navigator.pushNamed(context, '/mobile/perfil');
                  },
                ),
                _QuickActionButton(
                  icon: Icons.account_balance_wallet_outlined,
                  label: "Gastos Comunes",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyExpensesPage(),
                      ),
                    );
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




// Modal de notificaciones con datos reales
class _NotificationsModal extends StatefulWidget {
  const _NotificationsModal();

  @override
  State<_NotificationsModal> createState() => _NotificationsModalState();
}

class _NotificationsModalState extends State<_NotificationsModal> {
  final _notificationService = NotificationService();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _communityId;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    // Inicializar timeago en español
    timeago.setLocaleMessages('es', timeago.EsMessages());
  }

  Future<void> _loadNotifications() async {
    try {
      final authService = AuthService();
      final user = authService.currentUser;
      
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Obtener community_id del usuario
      final db = FirebaseFirestore.instance;
      final userDoc = await db.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      final userData = userDoc.data();
      _communityId = userData?['community_id'] as String? ?? 
                     userData?['communityId'] as String?;

      if (_communityId == null || _communityId!.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // Obtener notificaciones
      final notifications = await _notificationService.getMyNotifications(
        communityId: _communityId!,
        limit: 50,
      );

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando notificaciones: $e');
      setState(() => _isLoading = false);
    }
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.incidentCreated:
      case NotificationType.incidentUpdated:
      case NotificationType.incidentComment:
        return Icons.warning_amber;
      case NotificationType.reservationCreated:
      case NotificationType.reservationUpdated:
        return Icons.event;
      case NotificationType.announcement:
        return Icons.campaign;
      case NotificationType.commonExpensePublished:
        return Icons.attach_money;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          // Header del modal
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Notificaciones',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Lista de notificaciones
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _notifications.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No tienes notificaciones',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final notif = _notifications[index];
                          return InkWell(
                            onTap: () async {
                              if (!notif.isRead) {
                                try {
                                  await _notificationService.markAsRead(
                                    communityId: _communityId!,
                                    notificationId: notif.id,
                                  );
                                  setState(() {
                                    if (mounted) {
                                      _notifications[index] = notif.copyWith(isRead: true);
                                    }
                                  });
                                } catch (e) {
                                  print('Error marking as read: $e');
                                }
                              }
                            },
                            child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: notif.isRead ? Colors.grey[50] : AppColors.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: notif.isRead ? Colors.grey[200]! : AppColors.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _getIconForType(notif.type),
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notif.title,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: notif.isRead ? Colors.grey[600] : AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          if (!notif.isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif.message,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        timeago.format(notif.createdAt, locale: 'es'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[400],
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
                      ),
          ),
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

// Tarjeta de gasto común con datos reales
class _GastoComunCard extends StatefulWidget {
  @override
  State<_GastoComunCard> createState() => _GastoComunCardState();
}

class _GastoComunCardState extends State<_GastoComunCard> {
  Map<String, dynamic>? _latestExpense;
  bool _loading = true;
  String? _error;
  String? _communityId;

  @override
  void initState() {
    super.initState();
    _loadLatestExpense();
  }

  Future<void> _loadLatestExpense() async {
    try {
      final authService = AuthService();
      final user = authService.currentUser;
      
      if (user == null) {
        setState(() {
          _error = 'Usuario no autenticado';
          _loading = false;
        });
        return;
      }

      // Obtener community_id del usuario
      // El usuario tiene un campo communityId en Firestore
      final db = FirebaseFirestore.instance;
      final userDoc = await db.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        setState(() {
          _error = 'Usuario no encontrado';
          _loading = false;
        });
        return;
      }

      final userData = userDoc.data();
      final communityId = userData?['communityId'] as String?;
      
      if (communityId == null || communityId.isEmpty) {
        setState(() {
          _error = 'Usuario sin comunidad asignada';
          _loading = false;
        });
        return;
      }
      
      final service = CommonExpenseService();
      final expense = await service.getLatestExpense(communityId: communityId);
      
      setState(() {
        _latestExpense = expense;
        _loading = false;
      });
    } catch (e) {
      print('Error cargando gasto común: $e');
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        width: double.infinity,
        height: 150,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_error != null || _latestExpense == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Colors.grey),
            const SizedBox(height: 10),
            Text(
              _error != null 
                  ? 'Error al cargar el gasto común'
                  : 'No hay gastos comunes disponibles',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Datos del gasto común
    final amount = (_latestExpense!['total_amount'] ?? 0).toDouble();
    final period = _latestExpense!['period'] ?? '';
    final month = _latestExpense!['month'] ?? 1;
    final year = _latestExpense!['year'] ?? 2025;
    final status = _latestExpense!['status'] ?? 'draft';

    // Calcular fecha de vencimiento (asumiendo día 28 del mes siguiente)
    int dueMonth = month == 12 ? 1 : month + 1;
    int dueYear = month == 12 ? year + 1 : year;
    final dueDate = DateTime(dueYear, dueMonth, 28);
    final dueDateStr = '${dueDate.day}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.year}';

    // Determinar si está vencido
    final now = DateTime.now();
    final isOverdue = now.isAfter(dueDate) && (status == 'closed' || status == 'notified');
    final isCurrent = !isOverdue && (status == 'closed' || status == 'notified');

    // Color del card según estado
    final cardColor = isOverdue 
        ? AppColors.error 
        : (isCurrent ? AppColors.primary : Colors.grey[600]);

    // Texto de estado
    final statusText = isOverdue 
        ? 'VENCIDO' 
        : (isCurrent ? 'AL DÍA' : 'EN PREPARACIÓN');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Tu total a pagar es de",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              // Badge de estado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "\$ ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyExpensesPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                ),
                child: const Text(
                  "Ver Detalles",
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Gasto común $period",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Vencimiento: $dueDateStr",
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Botón de descarga
              IconButton(
                onPressed: () async {
                  try {
                    if (_latestExpense != null && _communityId != null) {
                      final expenseId = _latestExpense!['id'] as String;
                      final baseUrl = 'http://localhost:8000'; // TODO: Obtener de configuración
                      final pdfUrl = '$baseUrl/common-expenses/my-expenses/$expenseId/pdf?community_id=$_communityId';
                      
                      final uri = Uri.parse(pdfUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No se pudo abrir el PDF')),
                          );
                        }
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.download_rounded, color: Colors.white70, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Carrusel de anuncios (carga datos reales de la API)
class _NewsCarousel extends StatefulWidget {
  const _NewsCarousel();

  @override
  State<_NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<_NewsCarousel> {
  final _announcementService = AnnouncementService();
  List<Announcement> _announcements = [];
  bool _isLoading = true;
  String? _communityId;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      final authService = AuthService();
      final user = authService.currentUser;
      
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Obtener token de autenticación
      final token = await user.getIdToken();

      // Obtener community_id del usuario
      final db = FirebaseFirestore.instance;
      final userDoc = await db.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      final userData = userDoc.data();
      // Intentar ambos formatos: community_id y communityId
      _communityId = userData?['community_id'] as String? ?? 
                     userData?['communityId'] as String?;

      if (_communityId == null || _communityId!.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // Obtener anuncios activos para banner
      final announcements = await _announcementService.getActiveBanners(
        communityId: _communityId!,
        token: token,
      );

      setState(() {
        _announcements = announcements;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando anuncios: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Color> _getPriorityColors(AnnouncementPriority priority) {
    switch (priority) {
      case AnnouncementPriority.info:
        return [AppColors.primary, const Color(0xFF6A75E6)];
      case AnnouncementPriority.warning:
        return [const Color(0xFFFF9966), const Color(0xFFFF5E62)];
      case AnnouncementPriority.urgent:
        return [const Color(0xFFFF5252), const Color(0xFFD32F2F)];
    }
  }

  IconData _getPriorityIcon(AnnouncementPriority priority) {
    switch (priority) {
      case AnnouncementPriority.info:
        return Icons.campaign;
      case AnnouncementPriority.warning:
        return Icons.warning_amber;
      case AnnouncementPriority.urgent:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: double.infinity,
        height: 140,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_announcements.isEmpty) {
      return SizedBox(
        width: double.infinity,
        height: 140,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              'No hay anuncios activos',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 140,
      child: CarouselSlider.builder(
        itemCount: _announcements.length,
        itemBuilder: (context, index, realIndex) {
          final announcement = _announcements[index];
          final colors = _getPriorityColors(announcement.priority);
          final icon = _getPriorityIcon(announcement.priority);
          
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: colors,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: Colors.white, size: 40),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          announcement.title,
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              announcement.priority.emoji,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              announcement.priority.displayName,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
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
          autoPlayInterval: const Duration(seconds: 5),
          enlargeCenterPage: true,
          viewportFraction: 0.75,
          aspectRatio: 2.0,
        ),
      ),
    );
  }
}
