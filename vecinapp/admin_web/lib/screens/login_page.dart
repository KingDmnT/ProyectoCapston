import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:admin_web/theme/app_theme.dart';
import 'package:admin_web/screens/home_screen.dart';
import 'package:quickalert/quickalert.dart';

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
  final String backendUrl = dotenv.env['BACKEND_URL'] ?? "http://127.0.0.1:8000";

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
        // 3. Validar con Backend (Opcional)
        await _verifyWithBackend(token);
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _mapFirebaseError(e.code);
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

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuario no encontrado';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-email':
        return 'Correo inválido';
      case 'user-disabled':
        return 'Usuario deshabilitado';
      default:
        return 'Error de autenticación: $code';
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
      
      if (response.statusCode != 200) {
        print("Error backend: ${response.statusCode} - ${response.body}");
        // No lanzamos excepción para no bloquear el login si el backend está caído pero Auth funciona
      }
    } catch (e) {
      print("Error conectando al backend: $e");
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar Contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa tu correo electrónico para recibir un enlace de recuperación.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Correo Electrónico'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (emailController.text.isEmpty) return;
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text.trim());
                if (mounted) {
                  QuickAlert.show(
                    context: context,
                    type: QuickAlertType.success,
                    title: 'Correo enviado',
                    text: 'Revisa tu bandeja de entrada para restablecer tu contraseña.',
                  );
                }
              } catch (e) {
                if (mounted) {
                  QuickAlert.show(
                    context: context,
                    type: QuickAlertType.error,
                    title: 'Error',
                    text: 'No se pudo enviar el correo: $e',
                  );
                }
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
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
                    child: Image.asset('assets/images/Logo.png', width: 100),
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
                  onSubmitted: (_) => _login(),
                ),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ),

                const SizedBox(height: 24),
                
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
