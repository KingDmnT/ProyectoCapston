import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vecinapp/core/theme/app_theme.dart';
import 'package:vecinapp/core/services/auth_service.dart';
import 'package:vecinapp/shared/widgets/auth_wrapper.dart';
import 'package:vecinapp/shared/screens/welcome_screen.dart';
import 'package:vecinapp/shared/screens/login_screen.dart';

// Importar pantallas mobile
import 'package:vecinapp/mobile/screens/home/home_page.dart';
import 'package:vecinapp/mobile/screens/visitas_menu_page.dart';
import 'package:vecinapp/mobile/screens/reservas_menu_page.dart';
import 'package:vecinapp/mobile/screens/incidentes_menu_page.dart';
import 'package:vecinapp/mobile/screens/camaras_menu_page.dart';
import 'package:vecinapp/mobile/screens/mis_datos_page.dart';

// Importar pantallas admin
import 'package:vecinapp/admin/screens/dashboard/dashboard_page.dart';
import 'package:vecinapp/admin/screens/users/users_screen.dart';

// Configuración principal de la aplicación
class VecinApp extends StatelessWidget {
  const VecinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider para el servicio de autenticación
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
      ],
      child: MaterialApp(
        title: 'VecinApp',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(), // Usar AuthWrapper para persistir sesión
        routes: {
          // Rutas compartidas
          '/welcome': (_) => const WelcomeScreen(),
          '/login': (_) => const LoginScreen(),
          
          // Rutas mobile (residentes)
          '/mobile/home': (_) => const MobileHomePage(),
          '/mobile/visitas': (_) => const VisitasMenuPage(),
          // Nota: generar y escanear se navegan desde visitas_menu con push y argumentos
          '/mobile/reservas': (_) => const ReservasMenuPage(),
          // Nota: reservar_espacio se navega desde reservas_menu con push y argumentos
          '/mobile/incidentes': (_) => const IncidentesMenuPage(),
          // Nota: reportar se navega desde incidentes_menu con push
          '/mobile/camaras': (_) => const CamarasMenuPage(),
          '/mobile/perfil': (_) => const MisDatosPage(),
          
          // Rutas admin (administradores)
          '/admin/dashboard': (_) => const AdminDashboardPage(),
          '/admin/users': (_) => const UsersScreen(),
        },
      ),
    );
  }
}
