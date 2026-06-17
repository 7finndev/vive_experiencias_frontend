import 'package:flutter/material.dart';

class ResponsiveListBuilder extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final double minItemWidth; 
  final EdgeInsetsGeometry? padding;

  const ResponsiveListBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.minItemWidth = 350, // 350px es un buen tamaño para tarjetas de eventos
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // Usamos LayoutBuilder para saber si estamos en móvil o PC
    return LayoutBuilder(
      builder: (context, constraints) {
        // MÓVIL (< 600px): Usamos lista normal vertical (scrollea mejor en móvil)
        if (constraints.maxWidth < 600) {
          return ListView.builder(
            itemCount: itemCount,
            padding: padding ?? const EdgeInsets.all(16),
            itemBuilder: itemBuilder,
          );
        }

        // DESKTOP (> 600px): Usamos GRID automático
        return GridView.builder(
          itemCount: itemCount,
          padding: padding ?? const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: minItemWidth, // Ancho máximo de tarjeta
            childAspectRatio: 1.1, // Relación de aspecto (1.1 es casi cuadrado)
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemBuilder: itemBuilder,
        );
      },
    );
  }
}