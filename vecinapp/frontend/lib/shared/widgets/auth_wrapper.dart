import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vecinapp/core/services/auth_service.dart';
import 'package:vecinapp/core/models/user.dart' as app_models;
import 'package:vecinapp/shared/screens/login_screen.dart';
import 'package:vecinapp/mobile/screens/home/home_page.dart';
import 'package:vecinapp/admin/screens/dashboard/dashboard_page.dart';

/// Wrapper que verifica el estado de autenticación y redirige apropiadamente
/// Esto permite persistir la sesión al refrescar la página
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Mostrando splash mientras se verifica la autenticación
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Si no hay usuario autenticado, mostrar login
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        // Usuario autenticado - obtener datos de Firestore y redirigir según rol
        return FutureBuilder<app_models.AppUser?>(
          future: authService.getCurrentUserData(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (!userSnapshot.hasData || userSnapshot.data == null) {
              // Error obteniendo datos - logout y mostrar login
              authService.signOut();
              return const LoginScreen();
            }

            final appUser = userSnapshot.data!;

            // Redirigir según el rol
            if (appUser.role == app_models.UserRole.administrator) {
              return const AdminDashboardPage();
            } else {
              return const MobileHomePage();
            }
          },
        );
      },
    );
  }
}
