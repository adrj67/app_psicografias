import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImagenBlobWidget extends StatelessWidget {
  final Uint8List? imagenBytes;
  final double? height;
  final double? width;
  final BoxFit fit;

  const ImagenBlobWidget({
    super.key,
    this.imagenBytes,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    // Guardar en variable local para promoción de tipo
    final bytes = imagenBytes;
    
    // Si no hay imagen, mostrar placeholder
    if (bytes == null || bytes.isEmpty) {
      return Container(
        height: height ?? 200,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('Sin imagen', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // Mostrar imagen completa (bytes NO es nulo aquí)
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Image.memory(
          bytes,  // Usamos la variable local que es Uint8List (no nullable)
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => Container(
            height: height ?? 200,
            width: width ?? double.infinity,
            color: Colors.grey.shade200,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 48, color: Colors.red),
                  SizedBox(height: 8),
                  Text('Error al cargar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}