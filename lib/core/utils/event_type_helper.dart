import 'package:flutter/material.dart';

class EventTypeHelper {
  
  // Usamos Dart Records (la sintaxis que ya tenías)
  static ({String label, Color color, IconData icon}) getAppearance(String type) {
    switch (type.toLowerCase()) {
      
      // --- GRUPO GASTRONÓMICO ---
      case 'tapa':
      case 'gastronomic': // Por si acaso hay alguno antiguo con este nombre
        return (
          label: 'Gastronomic',
          color: Colors.orange.shade800,
          icon: Icons.local_dining
        );
      
      case 'menu':
        return (
          label: 'Gastronomic',
          color: Colors.purple.shade700,
          icon: Icons.restaurant_menu 
        );
      
      // --- GRUPO BEBIDAS ---
      case 'cocktail':
      case 'drink':
      case 'drinks':
        return (
          label: 'Drink',
          color: Colors.pink.shade600,
          icon: Icons.local_bar
        );

      // --- OTROS ---
      case 'shopping':
      case 'commercial':
        return (
          label: 'Shopping',
          color: Colors.blue.shade700,
          icon: Icons.shopping_bag
        );
      
      case 'elfos':
      case 'adventure':
      case 'gymkhana':
        return (
          label: 'Adventure',
          color: Colors.green.shade700,
          icon: Icons.map
        );

      default:
        return (
          label: 'Event',
          color: Colors.grey.shade700,
          icon: Icons.event
        );
    }
  }
}