import 'package:flutter/material.dart';
import 'package:vecinapp/core/theme/app_theme.dart';
import '../models/app_user.dart';
import '../services/local_auth.dart';
// Eliminamos dart:io para que funcione en Web
// import 'dart:io'; 
// import 'dart:io'; 
// import 'package:image_picker/image_picker.dart'; // Opcional si no usamos fotos en web

class CrearCuenta extends StatefulWidget {
  const CrearCuenta({super.key});
  @override
  State<CrearCuenta> createState() => _CrearCuentaState();
}

class _CrearCuentaState extends State<CrearCuenta> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  UserRole? _role;

  // En versión Web Demo, desactivamos la foto real para evitar errores de dart:io
  // File? _photoFile; 
  // final _picker = ImagePicker();

  // Método simulado para Web
  Future<void> _pickPhoto() async {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Subida de fotos deshabilitada en Demo Web"))
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _register() {
    if (!_formKey.currentState!.validate()) return;

    if (_passCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona Administrador o Vecino'), backgroundColor: Colors.orange),
      );
      return;
    }

    final ok = LocalAuth.register(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      password: _passCtrl.text,
      role: _role!,
      photoPath: null, // Sin foto en web
    );

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El email ya está registrado'), backgroundColor: Colors.red),
      );
      return;
    }

    final nombre = _nameCtrl.text.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bienvenido, $nombre'), backgroundColor: Colors.green),
    );

    // Deriva directamente a Home
    Navigator.pushReplacementNamed(
      context,
      '/home',
      arguments: _emailCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // Fondo gris suave
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. ENCABEZADO AZUL CURVO
            Container(
              width: double.infinity,
              height: 220, 
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Crear Cuenta",
                    style: TextStyle(
                      fontSize: 28, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white
                    ),
                  ),
                  const Text(
                    "Únete a tu comunidad hoy",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            // AVATAR SIMULADO (Icono para Web)
            Transform.translate(
              offset: const Offset(0, -40),
              child: Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        // Usamos Icono siempre para evitar crash en Web
                        child: Icon(Icons.person, size: 50, color: AppColors.primary.withOpacity(0.5)),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Material(
                        color: AppColors.success,", "StartLine">159
                        borderRadius: BorderRadius.circular(20),
                        elevation: 4,
                        child: InkWell(
                          onTap: _pickPhoto,
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. FORMULARIO EN TARJETA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(25),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: _inputDecoration("Nombre Completo", Icons.person_outline),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
                      ),
                      const SizedBox(height: 15),
                      
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration("Correo Electrónico", Icons.email_outlined),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Ingresa tu email';
                          final ok = RegExp(r'^\S+@\S+\.\S+$').hasMatch(v.trim());
                          return ok ? null : 'Email inválido';
                        },
                      ),
                      const SizedBox(height: 15),

                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        decoration: _inputDecoration("Contraseña", Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                      ),
                      const SizedBox(height: 15),

                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscureConfirm,
                        // AQUÍ ESTABA EL ERROR: lock_check no existe. Usamos check_circle_outline
                        decoration: _inputDecoration("Confirmar Contraseña", Icons.check_circle_outline).copyWith(
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Repite tu contraseña';
                          if (v != _passCtrl.text) return 'Las contraseñas no coinciden';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      const Text("Selecciona tu perfil", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _RoleCard(
                            label: "Vecino", 
                            isSelected: _role == UserRole.neighbor, 
                            onTap: () => setState(() => _role = UserRole.neighbor)
                          )),
                          const SizedBox(width: 10),
                          Expanded(child: _RoleCard(
                            label: "Admin", 
                            isSelected: _role == UserRole.admin, 
                            onTap: () => setState(() => _role = UserRole.admin)
                          )),
                        ],
                      ),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          onPressed: _register,
                          child: const Text('Registrarme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("¿Ya tienes cuenta? ", style: TextStyle(color: Colors.grey)),
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: Text(
                    "Inicia sesión aquí",
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.bold
            ),
          ),
        ),
      ),
    );
  }
}
