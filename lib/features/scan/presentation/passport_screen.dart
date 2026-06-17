import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:vive_core/core/local_storage/local_db_service.dart';
import 'package:vive_core/core/widgets/responsive_center.dart';
import 'package:vive_core/features/home/presentation/providers/home_providers.dart'; 
import 'package:vive_core/features/scan/data/models/passport_entry_model.dart';

class PassportScreen extends ConsumerWidget {
  const PassportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingBox = Hive.box(LocalDbService.pendingVotesBoxName);
    final syncedBox = Hive.box(LocalDbService.syncedStampsBoxName);
    final currentEventId = ref.watch(currentEventIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Pasaporte"),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      backgroundColor: Colors.grey[50],
      
      // 🔥 REFRESH INDICATOR AÑADIDO
      body: RefreshIndicator(
        color: Colors.blue,
        onRefresh: () async {
          // Aquí podríamos llamar al servicio de sincronización (subir votos pendientes)
          // Como no tengo tu SyncService aquí, pongo un delay para la animación.
          await Future.delayed(const Duration(seconds: 1));
        },
        child: ValueListenableBuilder(
          valueListenable: pendingBox.listenable(),
          builder: (context, Box boxPend, _) {
            
            return ValueListenableBuilder(
              valueListenable: syncedBox.listenable(),
              builder: (context, Box boxSync, _) {
                
                var allStamps = [...boxPend.values, ...boxSync.values].cast<PassportEntryModel>();
                
                final filteredStamps = allStamps.where((stamp) {
                   return stamp.eventId == currentEventId;
                }).toList();
                
                filteredStamps.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));

                if (filteredStamps.isEmpty) {
                  // ListView scrollable para que funcione el gesto en vacío
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_outlined, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 20),
                            const Text(
                              "Aún no tienes sellos en este evento",
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 10),
                            const Text("¡Ve a un bar y escanea su QR!"),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  // 🔥 OBLIGATORIO: Physics scrollable
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredStamps.length,
                  itemBuilder: (context, index) {
                    final stamp = filteredStamps[index];
                    return _StampCard(stamp: stamp);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _StampCard extends StatelessWidget {
  final PassportEntryModel stamp;

  const _StampCard({required this.stamp});

  @override
  Widget build(BuildContext context) {
    String dateStr;
    try {
      dateStr = DateFormat('d MMM y - HH:mm', 'es').format(stamp.scannedAt);
    } catch (e) {
      dateStr = stamp.scannedAt.toString().substring(0, 16); 
    }

    return ResponsiveCenter(
      child: Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: stamp.isSynced ? Colors.blue[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: stamp.isSynced ? Colors.blue.shade200 : Colors.orange.shade200
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.verified, 
                  color: stamp.isSynced ? Colors.blue : Colors.orange, 
                  size: 30
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stamp.establishmentName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Visado el: $dateStr",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  if (stamp.rating > 0)
                     Text("Valoración: ${stamp.rating}⭐", style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Column(
              children: [
                Icon(
                  stamp.isSynced ? Icons.cloud_done : Icons.cloud_upload,
                  color: stamp.isSynced ? Colors.blue : Colors.grey,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  stamp.isSynced ? "Cloud" : "Local",
                  style: TextStyle(
                    fontSize: 10, 
                    color: stamp.isSynced ? Colors.blue : Colors.grey
                  ),
                )
              ],
            )
          ],
        ),
      ),
    ),
    );
  }
}