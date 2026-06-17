import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vive_core/core/utils/logger_service.dart';
import 'package:vive_core/core/utils/qr_download_widget.dart';
import 'package:vive_core/features/home/data/models/establishment_model.dart';
import 'package:vive_core/features/home/data/models/product_model.dart';
import 'package:vive_core/features/home/data/repositories/product_repository.dart';

final productsByEstablishmentProvider = FutureProvider.family
    .autoDispose<List<ProductModel>, int>((ref, establishmentId) async {
      final allProducts = await ref.read(productRepositoryProvider).getAllProducts();
      return allProducts.where((p) => p.establishmentId == establishmentId).toList();
    });

// CAMBIO: Ahora es ConsumerStatefulWidget para manejar la visibilidad del PIN
class AdminEstablishmentDetailScreen extends ConsumerStatefulWidget {
  final EstablishmentModel establishment;

  const AdminEstablishmentDetailScreen({
    super.key,
    required this.establishment,
  });

  @override
  ConsumerState<AdminEstablishmentDetailScreen> createState() => _AdminEstablishmentDetailScreenState();
}

class _AdminEstablishmentDetailScreenState extends ConsumerState<AdminEstablishmentDetailScreen> {
  // Estado para el ojito del PIN
  bool _isPinVisible = false;

  @override
  Widget build(BuildContext context) {
    final establishment = widget.establishment; // Atajo
    final productsAsync = ref.watch(productsByEstablishmentProvider(establishment.id));

    final String? imageUrl = establishment.coverImage != null
        ? "${establishment.coverImage!}?t=${DateTime.now().millisecondsSinceEpoch}"
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(establishment.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Editar Datos",
            onPressed: () {
              context.push('/admin/socios/edit', extra: establishment);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IMAGEN DE PORTADA
            SizedBox(
              height: 300,
              width: double.infinity,
              child: imageUrl != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(imageUrl, fit: BoxFit.cover),
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                          child: Container(color: Colors.black.withValues(alpha: 0.5)),
                        ),
                        Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_,_,_) => const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 50)),
                        ),
                      ],
                    )
                  : Container(
                      color: Colors.orange.shade50,
                      child: const Center(child: Icon(Icons.store, size: 80, color: Colors.orange)),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // 🔥 NUEVA TARJETA DE SEGURIDAD (PIN)
                  Card(
                    elevation: 0,
                    color: Colors.red[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), 
                      side: BorderSide(color: Colors.red.shade100)
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: Colors.red, size: 30),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("PIN DE CAMARERO", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    _isPinVisible 
                                        ? (establishment.waiterPin ?? "SIN PIN") 
                                        : "••••",
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 3),
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton(
                                    icon: Icon(_isPinVisible ? Icons.visibility_off : Icons.visibility, color: Colors.red),
                                    onPressed: () => setState(() => _isPinVisible = !_isPinVisible),
                                    tooltip: "Mostrar/Ocultar PIN",
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // DATOS PROPIETARIO Y REDES
                  Text("Datos del Propietario", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 0,
                    color: Colors.grey[50],
                    shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person, color: Colors.grey),
                          title: Text(establishment.ownerName ?? "Nombre no registrado"),
                          subtitle: const Text("Propietario / Gerente"),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.contact_phone, color: Colors.grey),
                          title: Text(establishment.ownerPhone ?? "Sin móvil"),
                          subtitle: Text(establishment.ownerEmail ?? "Sin email"),
                          dense: true,
                        ),
                        const Divider(height: 1),
                        // 🔥 FILA DE REDES SOCIALES
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _SocialButton(icon: Icons.language, url: establishment.website, color: Colors.blue),
                              _SocialButton(icon: Icons.facebook, url: establishment.facebook, color: Colors.indigo),
                              _SocialButton(icon: Icons.camera_alt, url: establishment.instagram, color: Colors.purple), // Instagram
                              _SocialButton(icon: Icons.music_note, url: establishment.socialTiktok, color: Colors.black), // TikTok
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // HISTORIAL DE PRODUCTOS
                  Text("Historial de Productos", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  productsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text("Error: $e"),
                    data: (products) {
                      if (products.isEmpty) {
                        return const Center(child: Text("Sin productos registrados.", style: TextStyle(color: Colors.grey)));
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, index) {
                          final prod = products[index]; 
                          return ListTile(
                            onTap: () => context.push('/admin/products/detail', extra: prod),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: prod.imageUrl != null
                                  ? Image.network(prod.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                                  : Container(width: 50, height: 50, color: Colors.grey[300], child: const Icon(Icons.fastfood)),
                            ),
                            title: Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("${prod.price}€"),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 30),
                  const Divider(),

                  // ZONA QR (Tu widget personalizado)
                  const SizedBox(height: 10),
                  const Text("Código QR Oficial", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        QrDownloadSection(
                          dataContent: establishment.qrUuid,
                          establishmentName: establishment.name,
                        ),
                        const SizedBox(height: 20),
                        SelectableText(
                          establishment.qrUuid,
                          style: const TextStyle(fontFamily: 'Courier', fontSize: 14, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget auxiliar para iconos de redes
class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String? url;
  final Color color;
  const _SocialButton({required this.icon, required this.url, required this.color});

  @override
  Widget build(BuildContext context) {
    final bool isActive = url != null && url!.isNotEmpty;
    return IconButton(
      icon: Icon(icon),
      color: isActive ? color : Colors.grey[300],
      onPressed: isActive ? () {
        // Aquí podrías usar url_launcher para abrir el link
        Logger.info("Abrir URL: $url", "ADMIN_ESTABLISHMENT_DETAIL_SCREEN");
      } : null, // Desactivado si no hay URL
    );
  }
}