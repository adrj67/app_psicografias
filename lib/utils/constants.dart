import 'package:flutter/material.dart';

class AppConstants {
  // Base de datos
  static const String databaseName = 'psicografias.db';
  static const String databaseAssetPath = 'assets/database/psicografias.db';
  static const String ubicacionBDOriginal = 'C:/Users/adrj/Escritorio/Argentina Programa/Flutter/BSP/BD/psicografias_texto.csv';
  
  // Paginación
  static const int pageSize = 20;
  
  // UI
  static const Color primaryColor = Colors.indigo;
  static const Color suaveColor = Color.fromARGB(255, 96, 111, 192);
  static const double cardBorderRadius = 12.0;
  static const double imageHeight = 200.0;
  static const int mensajeResumenLength = 100;
  
  // Textos
  static const String appTitle = 'Psicografías';
  static const String searchHint = 'Buscar psicografías...';
  static const String noDataMessage = 'No hay psicografías para mostrar';
  static const String errorLoadingMessage = 'Error al cargar los datos';
  static const String detalleTitle = 'Detalle';
}