import 'package:flutter/material.dart';

class AppConstants {
  // Base de datos
  static const String databaseName = 'psicografias.db';
  static const String databaseAssetPath = 'assets/database/psicografias.db';
  
  // Paginación
  static const int pageSize = 20;
  static const int totalPsicografias = 1313;
  
  // UI
  static const double cardBorderRadius = 12.0;
  static const int mensajeResumenLength = 100;
  
  // Textos
  static const String appTitle = 'Psicografías';
  static const String searchHint = 'Buscar psicografías...';
  static const String noDataMessage = 'No hay psicografías para mostrar';
  static const String errorLoadingMessage = 'Error al cargar los datos';
  static const String detalleTitle = 'Detalle';

  // ============================================================
  // PALETA DE COLORES
  // ============================================================
  
  // --- TEMA CLARO ---
  static const Color lightBackground = Color.fromARGB(255, 183, 216, 243);     // Blanco
  static const Color lightSurface = Color(0xFFF5F9FE);         // #c5def2 (azul muy claro)
  static const Color lightPrimary = Color(0xFF2196F3);         // Azul principal
  static const Color lightSecondary = Color.fromARGB(255, 253, 152, 1);       // Naranja
  static const Color lightText = Color(0xFF212121);            // Gris oscuro
  static const Color lightSuccess = Color(0xFF28f02c);         // Verde

  // --- TEMA OSCURO ---
  static const Color darkBackground = Color(0xFF121212);       // Casi negro
  static const Color darkSurface = Color(0xFF1C1E20);          // Gris muy oscuro
  static const Color darkPrimary = Color(0xFF67b0eb);          // Azul brillante
  static const Color darkSecondary = Color(0xFFeda945);        // Naranja suave
  static const Color darkText = Color(0xFFDEDEDE);             // Gris claro
  static const Color darkSuccess = Color(0xFF1ec821);          // Verde oscuro
}