import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SmartImageContainer extends StatelessWidget {
  final String? imageUrl;
  final double borderRadius;
  final double? width;
  final double? height;
  final bool useBlurBackground; 

  const SmartImageContainer({
    super.key,
    required this.imageUrl,
    this.borderRadius = 12.0,
    this.width,
    this.height,
    this.useBlurBackground = true, // Activado por defecto para evitar recortes
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // CAPA 1: FONDO BORROSO (Rellena el hueco)
            if (useBlurBackground)
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Desenfoque fuerte
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover, // Este sí se recorta, pero da igual porque es el fondo
                  width: double.infinity,
                  height: double.infinity,
                  errorWidget: (context, url, error) => Container(color: Colors.grey[200]),
                ),
              ),
            
            // CAPA 2: OSCURECIMIENTO LIGERO (Para resaltar la imagen principal)
            if (useBlurBackground)
              Container(color: Colors.black.withValues(alpha: 0.3)),

            // CAPA 3: LA IMAGEN REAL (Entera, sin recortar nada)
            CachedNetworkImage(
              imageUrl: imageUrl!,
              // 'contain' muestra TODO el texto, 'cover' recorta.
              fit: BoxFit.contain, 
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (context, url, error) => _buildPlaceholder(isError: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder({bool isError = false}) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(
          isError ? Icons.broken_image_outlined : Icons.image_outlined,
          color: Colors.grey[400],
          size: 30,
        ),
      ),
    );
  }
}