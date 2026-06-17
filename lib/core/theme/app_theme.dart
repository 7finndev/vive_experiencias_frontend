import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData getLight() {
    // Definimos el color base
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.orange);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      
      // 1. FUENTE GLOBAL (Cuerpo de texto, botones, inputs...)
      textTheme: GoogleFonts.latoTextTheme(),
      
      // 2. FUENTE PARA TÍTULOS (AppBar)
      appBarTheme: AppBarTheme(
        centerTitle: true, // Centramos títulos por defecto (estilo moderno)
        backgroundColor: colorScheme.primary, // Fondo naranja
        foregroundColor: Colors.white, // Texto blanco
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5, // Un pelín de espaciado queda elegante
        ),
      ),
      
      // 3. ESTILO DE BOTONES
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}