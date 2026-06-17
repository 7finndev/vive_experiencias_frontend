import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vive_core/core/utils/logger_service.dart';
import 'package:vive_core/features/home/presentation/providers/home_providers.dart';

class EventShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  final String eventId;

  const EventShellScreen({
    required this.navigationShell,
    required this.eventId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Lógica de ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final int id = int.parse(eventId);
        if (ref.read(currentEventIdProvider) != id) {
          ref.read(currentEventIdProvider.notifier).state = id;
        }
      } catch (e) {
        Logger.error("Error parsing event ID: $e", "EVENT_SHELL_SCREEN");
      }
    });

    // 2. Lógica Visual (BRANDING REAL) 🎨
    final eventAsync = ref.watch(currentEventProvider);
    
    // Valores por defecto
    String productLabel = "Tapas";
    IconData productIcon = Icons.local_dining_outlined;
    IconData productIconSelected = Icons.local_dining;
    
    // COLORES POR DEFECTO
    Color themeColor = Colors.orange; // Color Principal (Seleccionado)
    Color bgColor = Colors.white;     // Color Fondo Pantalla
    Color navColor = Colors.white;    // Color Barra Navegación
    Color textColor = Colors.black;   // Color Iconos inactivos / Texto

    if (eventAsync.hasValue && eventAsync.value != null) {
      final event = eventAsync.value!;
      final type = event.type;
      
      // Iconos según tipo
      if (type == 'menu') {
        productLabel = "Menús";
        productIcon = Icons.restaurant_menu_outlined;
        productIconSelected = Icons.restaurant_menu;
      } else if (type == 'drinks' || type == 'cocktail') {
        productLabel = "Cócteles";
        productIcon = Icons.local_bar_outlined;
        productIconSelected = Icons.local_bar;
      } else if (type == 'shopping') {
        productLabel = "Tiendas";
        productIcon = Icons.shopping_bag_outlined;
        productIconSelected = Icons.shopping_bag;
      }

      // PARSEO DE COLORES (Protegido contra errores)
      try {
         if (event.themeColorHex.isNotEmpty) {
           themeColor = Color(int.parse(event.themeColorHex.replaceAll('#', '0xff')));
         }
         if (event.bgColorHex != null && event.bgColorHex!.isNotEmpty) {
           bgColor = Color(int.parse(event.bgColorHex!.replaceAll('#', '0xff')));
         }
         if (event.navColorHex != null && event.navColorHex!.isNotEmpty) {
           navColor = Color(int.parse(event.navColorHex!.replaceAll('#', '0xff')));
         }
         if (event.textColorHex != null && event.textColorHex!.isNotEmpty) {
           textColor = Color(int.parse(event.textColorHex!.replaceAll('#', '0xff')));
         }
       } catch (_) {
         Logger.error("Error parsing colors: $e", "EVENT_SHELL_SCREEN");
         // Si falla algún color, mantenemos los defaults
       }
    }

    // 3. Responsive
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final bool isDesktop = width > 900;

    // DEFINIMOS LOS DESTINOS APLICANDO LOS COLORES DIRECTAMENTE AQUI
    // Así evitamos el error de intentar acceder a .icon más tarde
    final destinations = [
      NavigationDestination(
        icon: Icon(Icons.home_outlined, color: textColor.withValues(alpha: 0.6)), // Color inactivo
        selectedIcon: Icon(Icons.home, color: themeColor), // Color activo
        label: 'Inicio'
      ),
      NavigationDestination(
        icon: Icon(Icons.map_outlined, color: textColor.withValues(alpha: 0.6)),
        selectedIcon: Icon(Icons.map, color: themeColor),
        label: 'Mapa'
      ),
      NavigationDestination(
        icon: Icon(Icons.storefront_outlined, color: textColor.withValues(alpha: 0.6)),
        selectedIcon: Icon(Icons.storefront, color: themeColor),
        label: 'Locales'
      ),
      NavigationDestination(
        icon: Icon(productIcon, color: textColor.withValues(alpha: 0.6)),
        selectedIcon: Icon(productIconSelected, color: themeColor),
        label: productLabel
      ),
      NavigationDestination(
        icon: Icon(Icons.emoji_events_outlined, color: textColor.withValues(alpha: 0.6)),
        selectedIcon: Icon(Icons.emoji_events, color: themeColor),
        label: 'Ranking'
      ),
      NavigationDestination(
        icon: Icon(Icons.verified_outlined, color: textColor.withValues(alpha: 0.6)),
        selectedIcon: Icon(Icons.verified, color: themeColor),
        label: 'Pasaporte'
      ),
    ];

    // Para la versión Desktop (Rail), usamos una conversión simple
    final railDestinations = destinations.map((d) => NavigationRailDestination(
      icon: d.icon, 
      selectedIcon: d.selectedIcon, 
      label: Text(d.label),
    )).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final currentTab = navigationShell.currentIndex;
        if (currentTab != 0) {
          navigationShell.goBranch(0);
        } else {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: bgColor, // <--- AQUI APLICAMOS EL COLOR DE FONDO
        
        body: isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: height),
                      child: IntrinsicHeight(
                        child: NavigationRail(
                          backgroundColor: navColor, // <--- COLOR BARRA LATERAL
                          selectedIndex: navigationShell.currentIndex,
                          onDestinationSelected: (index) => _onTap(context, navigationShell, index),
                          
                          leading: Column(
                            children: [
                              const SizedBox(height: 20),
                              FloatingActionButton(
                                heroTag: 'fab_back_to_home', // Evita conflictos si hay varios FAB
                                elevation: 0,
                                backgroundColor: themeColor.withValues(alpha: 0.1), // Botón atrás sutil
                                foregroundColor: themeColor,
                                tooltip: "Volver al inicio",
                                onPressed: () => context.go('/'),
                                child: const Icon(Icons.arrow_back),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),

                          labelType: NavigationRailLabelType.all,
                          destinations: railDestinations,
                          
                          // TEMAS DE ICONOS
                          selectedIconTheme: IconThemeData(color: themeColor),
                          unselectedIconTheme: IconThemeData(color: textColor.withValues(alpha: 0.6)),
                          selectedLabelTextStyle: TextStyle(color: themeColor, fontWeight: FontWeight.bold),
                          unselectedLabelTextStyle: TextStyle(color: textColor.withValues(alpha: 0.6)),
                          
                          useIndicator: true,
                          indicatorColor: themeColor.withValues(alpha: 0.2),
                          elevation: 1,
                          minWidth: 80,
                          groupAlignment: -1.0, 
                        ),
                      ),
                    ),
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(child: navigationShell),
                ],
              )
            : navigationShell,

        bottomNavigationBar: isDesktop
            ? null
            : NavigationBar(
                backgroundColor: navColor, // <--- COLOR BARRA INFERIOR
                selectedIndex: navigationShell.currentIndex,
                indicatorColor: themeColor.withValues(alpha: 0.2), // Fondo del botón activo
                
                // Aquí usamos directamente la lista que ya creamos con colores
                destinations: destinations,
                
                onDestinationSelected: (index) => _onTap(context, navigationShell, index),
              ),
      ),
    );
  }

  void _onTap(BuildContext context, StatefulNavigationShell shell, int index) {
    shell.goBranch(
      index,
      initialLocation: index == shell.currentIndex,
    );
  }
}