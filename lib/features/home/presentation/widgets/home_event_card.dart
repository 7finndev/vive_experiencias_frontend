import 'package:flutter/material.dart';
// Asegúrate de importar tu nuevo SmartImageContainer
import 'package:vive_core/core/utils/smart_image_container.dart';
import 'package:vive_core/core/utils/event_type_helper.dart';

class HomeEventCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String? logoUrl;
  final String eventType;
  final VoidCallback onTap;

  const HomeEventCard({
    super.key,
    required this.title,
    required this.imageUrl,
    this.logoUrl,
    required this.eventType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasLogo = logoUrl != null && logoUrl!.isNotEmpty;
    final appearance = EventTypeHelper.getAppearance(eventType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200, // Altura fija
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        // USAMOS EL COMPONENTE INTELIGENTE AQUÍ
        child: Stack(
          children: [
            // 1. LA IMAGEN CON FONDO BORROSO (Cubre todo, muestra imagen entera)
            SmartImageContainer(
              imageUrl: imageUrl,
              borderRadius: 20,
              width: double.infinity,
              height: 200,
              useBlurBackground: true, // <--- ESTO ACTIVA EL EFECTO
            ),

            // 2. GRADIENTE NEGRO (Para que el texto blanco se lea)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6), // Un poco de sombra abajo
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),

            // 3. ETIQUETA DE TIPO (Gastronómico, etc.)
            Positioned(
              top: 15,
              right: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: appearance.color,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2), width: 1)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(appearance.icon, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      appearance.label.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. TÍTULO O LOGO
            if (hasLogo)
              Positioned(
                bottom: 16,
                right: 16,
                child: SmartImageContainer(
                  imageUrl: logoUrl,
                  height: 60,
                  width: 100,
                  borderRadius: 0,
                  useBlurBackground: false, // El logo no necesita fondo borroso
                  // fit: BoxFit.contain (esto ya lo hace por defecto al quitar el blur)
                ),
              ),

            if (!hasLogo)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    height: 1.1,
                    shadows: [
                      Shadow(
                        offset: const Offset(2, 2),
                        blurRadius: 4.0,
                        color: Colors.black.withValues(alpha: 0.9),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}