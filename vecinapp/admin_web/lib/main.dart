import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:admin_web/theme/app_theme.dart';
import 'package:admin_web/screens/home_screen.dart';

import 'package:admin_web/screens/login_page.dart';

// --- Configuración ---
// Carga de credenciales desde archivo .env (Assets)
final firebaseOptions = FirebaseOptions(
  apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
  appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
  messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
  projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
  authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'],
  storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'],
);

final String backendUrl = dotenv.env['BACKEND_URL'] ?? "http://127.0.0.1:8000";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Cargar variables de entorno
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Error cargando .env: $e");
  }
  
  // 2. Inicializar Firebase
  try {
    await Firebase.initializeApp(
      options: firebaseOptions,
    );
  } catch (e) {
    print("Error inicializando Firebase: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VecinApp Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // Usamos nuestro tema personalizado
      home: const LoginPage(),
    );
  }
}
