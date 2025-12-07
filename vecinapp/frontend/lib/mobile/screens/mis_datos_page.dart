import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'dart:io'; // Necesario para manejar la foto si viene de archivo
import 'package:vecinapp/core/theme/app_theme.dart';

// Si tienes tus modelos en carpetas, impórtalos. 
// Si no, este código funcionará igual con datos simulados.
// import '../services/local_auth.dart';
// import '../models/app_user.dart';

class MisDatosPage extends StatefulWidget {
  const MisDatosPage({super.key});

  @override
  State<MisDatosPage> createState() => _MisDatosPageState();
}

class _MisDatosPageState extends State<MisDatosPage> {
  // Índice 2 porque corresponde a la pestaña "Perfil"
  int _selectedIndex = 2; 

  @override
  Widget build(BuildContext context) {
    // --- SIMULACIÓN DE DATOS (Recuperar argumentos si existen) ---
    // Aquí puedes conectar tu lógica real de AppUser como en la pagina principal
    final arg = (ModalRoute.of(context)?.settings.arguments ?? '') as String?;
    
    String nombre = "Carlos Pérez"; // Valor por defecto
    String email = "carlos.perez@email.com";
    String rol = "Propietario";
    String condominio = "Condominio Conecta Huechuraba";
    String unidad = "Depto 2205";
    String? photoPath;

    // Lógica simple para detectar si es el demo o un usuario real
    // (Adapta esto a tu modelo AppUser real cuando lo integres)
    if (arg != null && arg.contains('@')) {
       email = arg;
       // Aquí buscarías en tu BD local: u = LocalAuth.byEmail(arg);
       // nombre = u.name; etc...
    }
    // -----------------------------------------------------------

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          children: [
            // 1. ENCABEZADO PERFIL (Más alto para incluir la foto)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Fila superior: Botón volver y Título
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12)
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          "Mi Perfil",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.white
                          ),
                        ),
                      ),
                      // Botón "Editar" decorativo
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12)
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 25),

                  // FOTO DE PERFIL
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4), // Borde blanco
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          // Lógica para mostrar foto de archivo o iniciales
                          backgroundImage: (photoPath != null && photoPath!.isNotEmpty)
                              ? FileImage(File(photoPath!))
                              : null,
                          child: (photoPath == null || photoPath!.isEmpty)
                              ? Text(
                                  nombre[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 40, color: AppColors.primary, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                      ),
                      // Icono de cámara pequeño
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.success, // Verde", "StartLine">132
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2)
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      )
                    ],
                  ),

                  const SizedBox(height: 15),

                  // NOMBRE Y ROL DEBAJO DE LA FOTO
                  Text(
                    nombre,
                    style: GoogleFonts.lato(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white
                    ),
                  ),
                  Text(
                    rol,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: Colors.white70
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. LISTA DE DATOS
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Text(
                    "Información Personal",
                    style: GoogleFonts.lato(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 14
                    ),
                  ),
                  const SizedBox(height: 15),

                  _ProfileInfoTile(
                    icon: Icons.person_outline,
                    label: "Nombre Completo",
                    value: nombre,
                  ),
                  _ProfileInfoTile(
                    icon: Icons.email_outlined,
                    label: "Correo Electrónico",
                    value: email,
                  ),
                  _ProfileInfoTile(
                    icon: Icons.badge_outlined, // Icono de credencial
                    label: "Perfil / Rol",
                    value: rol,
                  ),
                   
                  const SizedBox(height: 20),
                  Text(
                    "Información de la Propiedad",
                    style: GoogleFonts.lato(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 14
                    ),
                  ),
                  const SizedBox(height: 15),

                  _ProfileInfoTile(
                    icon: Icons.domain, // Icono de edificio
                    label: "Condominio",
                    value: condominio,
                  ),
                  _ProfileInfoTile(
                    icon: Icons.meeting_room_outlined, // Icono de puerta
                    label: "Unidad",
                    value: unidad,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 3. BARRA DE NAVEGACIÓN
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
                GButton(icon: Icons.person_outline, text: 'Perfil'),
              ],
              selectedIndex: _selectedIndex, // Seleccionado el índice 2 (Perfil)
              onTabChange: (index) {
                if (index == 0) {
                   Navigator.pop(context); // Volver al inicio
                } else {
                   setState(() => _selectedIndex = index);
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

// WIDGET AUXILIAR: Tarjeta de información
class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
