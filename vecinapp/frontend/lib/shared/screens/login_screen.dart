import 'package:flutter/material.dart';
import 'package:vecinapp/core/theme/app_theme.dart';
import 'package:vecinapp/core/services/auth_service.dart';
import 'package:vecinapp/core/models/user.dart';

// Pantalla de inicio de sesión con redirección automática por rol
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;

  // Método de login con redirección según rol
  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError("Por favor ingresa tus datos");
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // Autenticar y obtener usuario con rol
      final user = await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user == null) {
        _showError("Error al obtener datos de usuario");
        setState(() { _isLoading = false; });
        return;
      }

      if (!mounted) return;

      // Redirección automática según el rol
      if (user.isAdministrator) {
        // Administrador → Backoffice
        Navigator.pushReplacementNamed(context, '/admin/dashboard');
      } else {
        // Residente → App móvil
        Navigator.pushReplacementNamed(context, '/mobile/home');
      }
      
    } catch (e) {
      _showError(e.toString());
      setState(() { _isLoading = false; });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Detectar si es web y usar diseño centrado
    final isWeb = MediaQuery.of(context).size.width > 768;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isWeb ? 500 : double.infinity, // Limitar ancho en web
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isWeb) ...[
                  // ENCABEZADO AZUL (solo mobile)
                  Container(
                    width: double.infinity,
                    height: 300,
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const Spacer(),
                        Image.asset('assets/images/LogoBcoSinFondo.png', height: 100, width: 100),
                        const SizedBox(height: 10),
                        const Text(
                          "Bienvenido",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white
                          ),
                        ),
                        const Text(
                          "Ingresa a tu comunidad",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
                
                if (isWeb) ...[
                  // HEADER PARA WEB
                  const SizedBox(height: 40),
                  Image.asset('assets/images/LogoSinFondo.png', height: 120, width: 120),
                  const SizedBox(height: 20),
                  const SizedBox(height: 8),
                  const Text(
                    "Ingresa a tu comunidad",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],

                // FORMULARIO (común para ambos)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isWeb ? 40 : 20),
                  child: Container(
                    padding: EdgeInsets.all(isWeb ? 40 : 25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isWeb) ...[
                          const Text(
                            "Iniciar Sesión",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        
                        // Email
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: "Correo Electrónico",
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Contraseña
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Contraseña",
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        
                        const SizedBox(height: 30),

                        // Botón de login
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  "Ingresar",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Link de contraseña olvidada
                GestureDetector(
                  onTap: () {
                    // TODO: Implementar recuperación de contraseña
                  },
                  child: const Text(
                    "¿Olvidaste tu contraseña?",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
