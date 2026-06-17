import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart';

class WebContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Color? backgroundColor;

  const WebContainer({
    super.key, 
    required this.child, 
    this.maxWidth = 1400, // 1000px es el estándar "Sweet Spot" para lectura cómoda
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Si NO es web, devolvemos el hijo tal cual (comportamiento nativo móvil)
    if (!kIsWeb) return child;

    return Container(
      color: backgroundColor, // Color de fondo "infinito" (ej. gris claro)
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          // Opcional: Sombras laterales para dar efecto de "hoja de papel"
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}