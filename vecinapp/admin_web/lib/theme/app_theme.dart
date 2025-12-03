import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colores extraídos e inspirados en el logo
  static const Color primaryColor = Color(0xFF6200EA); // Morado vibrante (Escudo)
  static const Color secondaryColor = Color(0xFF00BFA5); // Turquesa/Cian (Señal)
  static const Color accentColor = Color(0xFF7C4DFF); // Variación más clara del morado
  
  static const Color backgroundLight = Color(0xFFF8F9FA); // Gris muy suave para fondo
  static const Color surfaceWhite = Colors.white;
  
  static const Color textDark = Color(0xFF1F2937); // Gris oscuro para textos principales
  static const Color textGrey = Color(0xFF6B7280); // Gris para subtítulos

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceWhite,
        background: backgroundLight,
        brightness: Brightness.light,
      ),
      
      // Tipografía moderna y limpia
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),
      
      // Estilo de Tarjetas (Glassmorphism sutil / Moderno)
      cardTheme: CardTheme(
        color: surfaceWhite,
        elevation: 2,
        shadowColor: primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Bordes redondeados modernos
        ),
      ),
      
      // Estilo de Botones
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      
      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
