// mis_datos.dart
import 'dart:io';                        // [NEW]
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // [NEW]
import 'package:vecinapp/core/theme/app_theme.dart';
import '../services/local_auth.dart';
import '../models/app_user.dart';

class MisDatos extends StatefulWidget {             // [CHANGED] antes era Stateless
  const MisDatos({super.key});

  @override
  State<MisDatos> createState() => _MisDatosState(); // [NEW]
}

class _MisDatosState extends State<MisDatos> {       // [NEW]
  AppUser? u;
  String nombre = 'Usuario';
  String rol = 'Vecino';
  String email = '';
  File? _photoFile;                                  // [NEW]
  final _picker = ImagePicker();                     // [NEW]

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = (ModalRoute.of(context)?.settings.arguments ?? '') as String?;
    if (id != null && id.contains('@')) {
      u = LocalAuth.byEmail(id);
      if (u != null) {
        nombre = u!.name;
        rol = u!.role == UserRole.admin ? 'Administrador' : 'Vecino';
        email = u!.email;
        if (u!.photoPath != null && u!.photoPath!.isNotEmpty) {
          _photoFile = File(u!.photoPath!);
        }
      } else {
        // vino un email pero no se encontró (muestra igual)
        email = id;
      }
    } else if ((id ?? '').toLowerCase() == LocalAuth.demoUser.toLowerCase()) {
      nombre = 'Usuario01 (demo)';
      rol = 'Vecino';
      email = 'demo@condominio.app';
    }
    setState(() {}); // refresca UI
  }

  Future<void> _pickPhoto() async {                  // [NEW]
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión de demo: no se puede guardar foto')),
      );
      return;
    }
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x != null) {
      final file = File(x.path);
      // Persistimos en "BD" local
      final ok = LocalAuth.updatePhoto(email: email, photoPath: file.path);
      if (ok) {
        setState(() => _photoFile = file);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto actualizada')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar la foto')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Datos'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
            icon: const Icon(Icons.logout),
            tooltip: 'Salir',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // [NEW] Avatar editable arriba de los "campos"
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: _photoFile != null ? FileImage(_photoFile!) : null,
                      child: _photoFile == null
                          ? const Icon(Icons.person, size: 48)
                          : null,
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Material(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: _pickPhoto,
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.edit, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Nombre
              Text(
                nombre,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              // Rol
              Text('Rol: $rol', style: const TextStyle(color: Colors.grey)),
              // [NEW] Email debajo del rol
              if (email.isNotEmpty)
                Text(email, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),

              // (Opcional) botones de acción o campos extra
              SizedBox(
                width: 220,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
