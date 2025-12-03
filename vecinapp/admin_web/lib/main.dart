import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:admin_web/theme/app_theme.dart';
import 'package:admin_web/screens/home_screen.dart';

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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Login con Firebase Auth
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // 2. Obtener Token
      final token = await userCredential.user?.getIdToken();
      
      if (token != null) {
        print("Token obtenido: ${token.substring(0, 20)}...");
        
        // 3. Validar con Backend (Opcional, para verificar conexión)
        await _verifyWithBackend(token);
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error inesperado: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyWithBackend(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        print("Backend verificado: ${response.body}");
      } else {
        print("Error backend: ${response.statusCode} - ${response.body}");
        throw Exception("Backend rechazó el token");
      }
    } catch (e) {
      print("Error conectando al backend: $e");
      // No bloqueamos el login si falla el backend por ahora, pero lo logueamos
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo / Icono
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.security, size: 64, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(height: 32),
                
                Text(
                  'VecinApp Admin',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Panel de Administración',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                ),
                
                const SizedBox(height: 32),
                
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[800]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  
                FilledButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('INGRESAR'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
