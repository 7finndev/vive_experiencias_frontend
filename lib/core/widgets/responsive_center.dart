import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart';

class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 500, // Anchura típica de un móvil grande / tablet pequeña
  });

  @override
  Widget build(BuildContext context) {
    // Si NO es web, devolvemos el hijo tal cual (comportamiento nativo móvil)
    if (!kIsWeb) return child;

    // Si ES web, centramos y limitamos el ancho
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor, // Fondo del tema
            boxShadow: [
              // Le damos una sombra para que destaque sobre el fondo del navegador
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
            // Opcional: Borde finito para separar visualmente
            border: Border.symmetric(
              vertical: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}