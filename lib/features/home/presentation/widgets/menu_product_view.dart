import 'package:flutter/material.dart';
import 'package:vive_core/features/home/data/models/product_model.dart';
import 'package:vive_core/features/home/data/models/product_item_model.dart';

class MenuProductView extends StatelessWidget {
  final ProductModel product;

  const MenuProductView({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Colores elegantes
    const Color goldColor = Color(0xFFD4AF37);

    // Usamos un Container en lugar de Scaffold para que se adapte al scroll del padre
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black, // Fondo base
        borderRadius: BorderRadius.circular(16),
        // Sombra para darle profundidad
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 5)),
        ],
        // IMAGEN DE FONDO (Si existe)
        image: product.imageUrl != null
            ? DecorationImage(
                image: NetworkImage(product.imageUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.7), // Oscurecemos la imagen para leer el texto
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      // Padding interno
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TÍTULO DEL MENÚ
          Center(
            child: Text(
              product.name.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: goldColor,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                fontFamily: 'Serif', 
              ),
            ),
          ),
          
          const SizedBox(height: 10),
          
          // 2. PRECIO
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: goldColor.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(20),
                color: Colors.black.withValues(alpha: 0.5),
              ),
              child: Text(
                "${product.price?.toStringAsFixed(2)} € / p.p.",
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 3. DESCRIPCIÓN
          if (product.description != null && product.description!.isNotEmpty)
            Text(
              product.description!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[300], fontSize: 15, height: 1.4, fontStyle: FontStyle.italic),
            ),

          const SizedBox(height: 30),
          const Divider(color: goldColor, thickness: 1),
          const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text("COMPOSICIÓN", style: TextStyle(color: Colors.white70, letterSpacing: 3, fontSize: 12)),
          )),
          const Divider(color: goldColor, thickness: 1),
          const SizedBox(height: 30),

          // 4. LISTA DE PLATOS
          if (product.items.isEmpty)
             const Center(child: Text("Detalles no disponibles", style: TextStyle(color: Colors.grey)))
          else
            ...product.items.map((item) => _buildMenuItem(item)),

          const SizedBox(height: 20),

          // 5. ALÉRGENOS
          if (product.allergens != null && product.allergens!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Text("ALÉRGENOS", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.allergens!.map((a) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(a, style: const TextStyle(fontSize: 11, color: Colors.white)),
                    )).toList(),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }

  // WIDGET PARA CADA PLATO
  Widget _buildMenuItem(ProductItemModel item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getColorForCourse(item.courseType).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Icon(
              _getIconForCourse(item.courseType),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          // Textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.courseType.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFD4AF37), // Dorado
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  item.name,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (item.description != null && item.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      item.description!,
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helpers
  Color _getColorForCourse(String type) {
    switch (type) {
      case 'entrante': return Colors.green;
      case 'principal': return Colors.orange;
      case 'postre': return Colors.pink;
      case 'bebida': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getIconForCourse(String type) {
    switch (type) {
      case 'entrante': return Icons.soup_kitchen;
      case 'principal': return Icons.restaurant;
      case 'postre': return Icons.icecream;
      case 'bebida': return Icons.wine_bar;
      default: return Icons.fastfood;
    }
  }
}