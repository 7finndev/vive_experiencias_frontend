import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vive_core/features/home/data/models/event_model.dart';
import 'package:vive_core/features/home/data/repositories/event_repository.dart';
import 'package:vive_core/features/home/presentation/providers/home_providers.dart';
import 'event_form_screen.dart'; 

class AdminEventsScreen extends ConsumerWidget {
  const AdminEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos el provider de la lista de eventos
    final eventsAsync = ref.watch(adminEventsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Eventos')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_add_event', // Evita conflictos si hay varios FAB
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Evento'),
        onPressed: () async {
          // 1. Navegar al formulario y ESPERAR (await) a que vuelva
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EventFormScreen()),
          );

          // 2. Si result es true (guardó cambios) o simplemente al volver, refrescamos.
          //    Es seguro llamar a refresh aunque no haya cambios, asegura consistencia.
          if (result == true) {
            ref.refresh(adminEventsListProvider);
          }
        },
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (events) {
          if (events.isEmpty) {
            return const Center(child: Text('No hay eventos creados.'));
          }
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    // Mostramos el color del tema del evento
                    backgroundColor: _hexToColor(event.themeColorHex),
                    child: const Icon(Icons.event, color: Colors.white),
                  ),
                  title: Text(
                    event.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  
                  // Usamos la función auxiliar para pintar el estado correctamente
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: _getStatusLabel(event.status),
                  ),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          // Navegar al formulario en modo EDITAR y esperar resultado
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventFormScreen(eventToEdit: event),
                            ),
                          );
                          
                          // Refrescar la lista al volver
                          if (result == true) {
                            ref.refresh(adminEventsListProvider);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, ref, event),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- FUNCIONES AUXILIARES ---

  // Convierte el String de estado en un Widget 
  // Coincide con el mapa usado en event_form_screen.dart
  Widget _getStatusLabel(String statusRaw) {
    // Normalizamos a minúsculas y quitamos espacios por seguridad
    final status = statusRaw.toLowerCase().trim();

    switch (status) {
      case 'active':
      case 'activo': // Por compatibilidad con datos viejos
        return const Text(
          '🟢 ACTIVO',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        );
      
      case 'upcoming':
      case 'proximamente':
      case 'próximamente': // Por compatibilidad
        return const Text(
          '🔜 PRÓXIMAMENTE',
          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
        );
      
      case 'archived':
      case 'finished':
      case 'finalizado': // Por compatibilidad
        return const Text(
          '🔴 FINALIZADO',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        );
      
      default:
        // Si llega algo raro, lo mostramos en gris para depurar
        return Text(
          '⚪ $statusRaw', 
          style: const TextStyle(color: Colors.grey),
        );
    }
  }

  Color _hexToColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.grey; // Color por defecto si falla el hex
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, EventModel event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Borrar Evento?'),
        content: Text('Vas a borrar "${event.name}". Esto eliminará también sus productos asociados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(eventRepositoryProvider).deleteEvent(event.id);
              // Refrescamos la lista tras borrar
              ref.refresh(adminEventsListProvider);
            },
            child: const Text('Borrar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}