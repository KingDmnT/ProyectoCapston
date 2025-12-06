import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vecinapp/app.dart';

// Configuración de Firebase desde .env
FirebaseOptions get firebaseOptions => FirebaseOptions(
  apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
  appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
  messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
  projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
  authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'],
  storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Cargar variables de entorno
  try {
    await dotenv.load(fileName: ".env");
    print('✅ Variables de entorno cargadas');
  } catch (e) {
    print('❌ Error cargando .env: $e');
  }
  
  // 2. Inicializar Firebase
  try {
    await Firebase.initializeApp(options: firebaseOptions);
    print('✅ Firebase inicializado correctamente');
  } catch (e) {
    print('❌ Error inicializando Firebase: $e');
  }

  runApp(const VecinApp());
}
