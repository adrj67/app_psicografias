import 'package:flutter/material.dart';

class AppConstants {
  // Base de datos
  static const String databaseName = 'psicografias.db';
  static const String databaseAssetPath = 'assets/database/psicografias.db';
    
  // Paginación
  static const int pageSize = 20;
  
  // UI
  //static const Color primaryColor = Colors.indigo;
  //static const Color suaveColor = Color.fromARGB(255, 96, 111, 192);
  static const double cardBorderRadius = 12.0;
  //static const double imageHeight = 200.0;
  static const int mensajeResumenLength = 100;
  
  // Textos
  static const String appTitle = 'Psicografías';
  static const String searchHint = 'Buscar psicografías...';
  static const String noDataMessage = 'No hay psicografías para mostrar';
  static const String errorLoadingMessage = 'Error al cargar los datos';
  static const String detalleTitle = 'Detalle';

  // Colores personalizados - Tema Claro
  static const Color primaryLight = Color(0xFF6B2D8A);      // Morado principal
  static const Color primaryLightLight = Color(0xFF8B4DAA); // Morado más claro
  static const Color accentLight = Color(0xFFE65100);       // Naranja acento
  static const Color backgroundLight = Color.fromARGB(248, 233, 216, 240);
  static const Color surfaceLight = Colors.white;
  static const Color textLight = Color(0xFF1A1A1A);
  static const Color textHintLight = Color(0xFF757575);
  
  // Colores personalizados - Tema Oscuro
  static const Color primaryDark = Color(0xFF9B6DB5);       // Morado más brillante
  static const Color primaryDarkDark = Color(0xFF7B4D95);   // Morado medio
  static const Color accentDark = Color(0xFFFF8C42);        // Naranja más brillante
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color.fromARGB(255, 53, 53, 53);
  static const Color textDark = Color(0xFFEEEEEE);
  static const Color textHintDark = Color(0xFF9E9E9E);
}