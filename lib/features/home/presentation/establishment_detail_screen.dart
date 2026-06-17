import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vive_core/core/utils/logger_service.dart';
import 'package:vive_core/features/home/presentation/widgets/menu_product_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';

// CORE & WIDGETS
import 'package:vive_core/core/widgets/web_container.dart'; // <--- USAMOS ESTE AHORA
import 'package:vive_core/core/utils/smart_image_container.dart';
import 'package:vive_core/core/widgets/error_view.dart';

// MODELOS
import 'package:vive_core/features/home/data/models/establishment_model.dart';
import 'package:vive_core/features/home/data/models/product_model.dart';

// PROVIDERS
import 'package:vive_core/features/home/presentation/providers/home_providers.dart';
import 'package:vive_core/features/scan/presentation/providers/scan_status_provider.dart';
import 'package:vive_core/features/scan/presentation/providers/sync_provider.dart';

// WIDGETS AUXILIARES
import 'package:vive_core/features/scan/presentation/widgets/star_rating_selector.dart';

class EstablishmentDetailScreen extends ConsumerStatefulWidget {
  final EstablishmentModel establishment;

  const EstablishmentDetailScreen({super.key, required this.establishment});

  @override
  ConsumerState<EstablishmentDetailScreen> createState() => _EstablishmentDetailScreenState();
}

class _EstablishmentDetailScreenState extends ConsumerState<EstablishmentDetailScreen> {
  // Variables de Estado para el Mapa y Ruta
  List<LatLng> routePoints = [];
  bool isRouteLoading = false;
  LatLng? myPosition;

  // --- LÓGICA DE CÁLCULO DE RUTA (TU CÓDIGO ORIGINAL) ---
  Future<void> _calculateRoute() async {
    if (widget.establishment.latitude == null || widget.establishment.longitude == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ubicación no definida")));
      return;
    }

    setState(() => isRouteLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw "Activa el GPS para ver la ruta.";

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw "Permiso de ubicación denegado.";
      }
      if (permission == LocationPermission.deniedForever) throw "Permiso denegado permanentemente.";

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      setState(() => myPosition = LatLng(position.latitude, position.longitude));

      final distanceInMeters = const Distance().as(
        LengthUnit.Meter,
        LatLng(position.latitude, position.longitude),
        LatLng(widget.establishment.latitude!, widget.establishment.longitude!),
      );

      final String profile = distanceInMeters > 1500 ? 'driving' : 'foot';
      final url = Uri.parse('https://router.project-osrm.org/route/v1/$profile/${position.longitude},${position.latitude};${widget.establishment.longitude},${widget.establishment.latitude}?geometries=geojson&overview=full');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] == null || (data['routes'] as List).isEmpty) throw "Ruta no encontrada.";
        final List<dynamic> coords = data['routes'][0]['geometry']['coordinates'];
        setState(() {
          routePoints = coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
        });
      } else {
        throw "Error servidor rutas.";
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isRouteLoading = false);
    }
  }

  Future<void> _openExternalMap() async {
    if (widget.establishment.latitude == null) return;
    final Uri mapUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=${widget.establishment.latitude},${widget.establishment.longitude}");
    if (!await launchUrl(mapUrl, mode: LaunchMode.externalApplication)) {
      await launchUrl(mapUrl, mode: LaunchMode.platformDefault);
    }
  }

  Future<void> _launchSocial(BuildContext context, String? urlString, {bool isTel = false}) async {
    if (urlString == null || urlString.isEmpty) return;
    final Uri uri = isTel ? Uri(scheme: 'tel', path: urlString) : Uri.parse(urlString);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // 1. DETECTAR TAMAÑO DE PANTALLA
    final isDesktop = MediaQuery.of(context).size.width > 900;

    // 2. DATOS
    final productsAsync = ref.watch(productsListProvider);
    final eventAsync = ref.watch(currentEventProvider);

    // Lógica de Evento
    String eventStatus = 'active';
    int currentEventId = 1;
    double? basePrice;
    Color themeColor = Colors.orange;

    if (eventAsync.hasValue && eventAsync.value != null) {
      eventStatus = eventAsync.value!.computedStatus;
      currentEventId = eventAsync.value!.id;
      basePrice = eventAsync.value!.basePrice;
      try {
        if (eventAsync.value!.themeColorHex.isNotEmpty) {
          String hex = eventAsync.value!.themeColorHex.replaceAll('#', '');
          if (hex.length == 6) hex = 'FF$hex';
          themeColor = Color(int.parse(hex, radix: 16));
        }
      } catch (_) {}
    }

    // Estado del Sello
    final hasStamp = ref.watch(hasStampProvider(establishmentId: widget.establishment.id, eventId: currentEventId));
    final ProductModel? product = productsAsync.valueOrNull?.where((p) => p.establishmentId == widget.establishment.id).firstOrNull;

    return WebContainer(
      backgroundColor: Colors.grey[100],
      child: Scaffold(
        backgroundColor: Colors.white,
        body: RefreshIndicator(
          color: themeColor,
          onRefresh: () async {
            ref.invalidate(productsListProvider);
            ref.invalidate(currentEventProvider);
            ref.invalidate(establishmentsListProvider);
            ref.invalidate(hasStampProvider(establishmentId: widget.establishment.id, eventId: currentEventId));
            await Future.delayed(const Duration(seconds: 1));
          },
          child: isDesktop
              // --- DISEÑO PC (2 COLUMNAS) ---
              ? _buildDesktopLayout(product, productsAsync, hasStamp, eventStatus, currentEventId, basePrice, themeColor)
              // --- DISEÑO MÓVIL (ORIGINAL) ---
              : _buildMobileLayout(product, productsAsync, hasStamp, eventStatus, currentEventId, basePrice, themeColor),
        ),
      ),
    );
  }

  // ===========================================================================
  // 📱 DISEÑO MÓVIL (Tu código original encapsulado)
  // ===========================================================================
  Widget _buildMobileLayout(ProductModel? product, AsyncValue productsAsync, bool hasStamp, String eventStatus, int currentEventId, double? basePrice, Color themeColor) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 250.0,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(widget.establishment.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 4, color: Colors.black)])),
            background: Stack(
              fit: StackFit.expand,
              children: [
                SmartImageContainer(imageUrl: widget.establishment.coverImage, borderRadius: 0),
                Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)]))),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildActionButtons(),
                const SizedBox(height: 20),
                _buildSocialButtons(),
                const SizedBox(height: 20),
                _buildInfoSection(),
                const Divider(height: 40),
                _buildProductSection(product, productsAsync, hasStamp, eventStatus, currentEventId, basePrice),
                const Divider(height: 40),
                _buildMapSection(height: 350),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 💻 DISEÑO DE ESCRITORIO (Híbrido: Misma lógica, diferente layout)
  // ===========================================================================
  Widget _buildDesktopLayout(ProductModel? product, AsyncValue productsAsync, bool hasStamp, String eventStatus, int currentEventId, double? basePrice, Color themeColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          // Cabecera Simple
          Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
            const SizedBox(width: 10),
            Text(widget.establishment.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 20),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- COLUMNA IZQUIERDA (40%): FOTO + MAPA ---
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 16/10,
                      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: SmartImageContainer(imageUrl: widget.establishment.coverImage, borderRadius: 0)),
                    ),
                    const SizedBox(height: 20),
                    _buildMapSection(height: 300), // MAPA REUTILIZADO
                  ],
                ),
              ),
              const SizedBox(width: 40),
              
              // --- COLUMNA DERECHA (60%): INFO + PRODUCTO ---
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildActionButtons(), // BOTONES DE LLAMADA/WEB
                    const SizedBox(height: 20),
                    _buildInfoSection(),
                    const SizedBox(height: 20),
                    _buildSocialButtons(),
                    const Divider(height: 40),
                    // AQUÍ ESTÁ EL PRODUCTO (GASTRONOMÍA)
                    _buildProductSection(product, productsAsync, hasStamp, eventStatus, currentEventId, basePrice),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 🧩 BLOQUES REUTILIZABLES (LA LÓGICA COMPARTIDA)
  // ===========================================================================

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(icon: Icons.call, label: "Llamar", onTap: () => _launchSocial(context, widget.establishment.phone, isTel: true)),
        _ActionButton(icon: Icons.language, label: "Web", color: widget.establishment.website != null ? Colors.orange : Colors.grey, onTap: () => _launchSocial(context, widget.establishment.website)),
        _ActionButton(icon: Icons.directions, label: "Ir", onTap: _openExternalMap),
      ],
    );
  }

  Widget _buildSocialButtons() {
    if (widget.establishment.facebook == null && widget.establishment.instagram == null && widget.establishment.socialTiktok == null) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Síguenos en redes", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 12),
        Row(
          children: [
            if (widget.establishment.facebook != null) _SocialButton(icon: FontAwesomeIcons.facebook, color: const Color(0xFF1877F2), onTap: () => _launchSocial(context, widget.establishment.facebook)),
            if (widget.establishment.instagram != null) _SocialButton(icon: FontAwesomeIcons.instagram, color: const Color(0xFFE4405F), onTap: () => _launchSocial(context, widget.establishment.instagram)),
            if (widget.establishment.socialTiktok != null) _SocialButton(icon: FontAwesomeIcons.tiktok, color: Colors.black, onTap: () => _launchSocial(context, widget.establishment.socialTiktok)),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Sobre el local", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(widget.establishment.description ?? "Sin descripción disponible.", style: const TextStyle(color: Colors.grey, height: 1.4)),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.access_time, size: 20, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(widget.establishment.schedule ?? "Horario no disponible", style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
      ],
    );
  }

  Widget _buildProductSection(ProductModel? product, AsyncValue productsAsync, bool hasStamp, String eventStatus, int currentEventId, double? basePrice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Propuesta Gastronómica", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ErrorView(error: err, isCompact: true, onRetry: () => ref.invalidate(productsListProvider)),
          data: (products) {
            if (product == null) return const Text("Este local no tiene tapa en este evento.");
            
            // 1. REVISAMOS SI ES UN MENÚ COMPLETO (AQUÍ ESTABA EL FALLO)
            // Si tiene items, devolvemos TU widget original con efecto Plex
            if (product.items.isNotEmpty) {
               return Column(
                 children: [
                   MenuProductView(product: product), // <--- ESTO RECUPERA EL EFECTO
                   const SizedBox(height: 20),
                   _buildScanButton(product, productsAsync, hasStamp, eventStatus, currentEventId),
                 ],
               );
            }

            // 2. SI NO ES MENÚ, ES TAPA INDIVIDUAL (Lógica estándar)
            String priceText = "";
            if ((product.price ?? basePrice) != null) priceText = "${(product.price ?? basePrice)!.toStringAsFixed(2)} €";
            
            return Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(16), 
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    border: hasStamp ? Border.all(color: Colors.green, width: 2) : null
                  ),
                  child: Column(
                    children: [
                      // FOTO PRODUCTO
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: SizedBox(
                          height: 250, 
                          width: double.infinity, 
                          child: SmartImageContainer(imageUrl: product.imageUrl, borderRadius: 0)
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                                if (priceText.isNotEmpty) Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                                  child: Text(priceText, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(product.description ?? "...", style: TextStyle(color: Colors.grey[800])),
                            if (product.ingredients != null) ...[const SizedBox(height: 10), Text("Ingredientes: ${product.ingredients}", style: const TextStyle(fontSize: 12, color: Colors.grey))],
                             if (product.allergens != null && product.allergens!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Wrap(spacing: 5, children: product.allergens!.map((a) => _AllergenChip(label: a)).toList())//Chip(label: Text(a, style: const TextStyle(fontSize: 10)))).toList())
                             ]
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // BOTÓN ESCANEAR
                _buildScanButton(product, productsAsync, hasStamp, eventStatus, currentEventId),
              ],
            );
          },
        ),
      ],
    );
  }
/*
  Widget _buildScanButton(ProductModel? product, AsyncValue productsAsync, bool hasStamp, String eventStatus, int currentEventId) {
    // LÓGICA DE BOTÓN (Exactamente la tuya)
    String label = "ESCANEAR CÓDIGO";
    IconData icon = Icons.qr_code_scanner;
    Color btnColor = Colors.orange;
    VoidCallback? action;

    if (hasStamp) {
      label = "¡VISADO!"; icon = Icons.check_circle; btnColor = Colors.green;
      action = () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ya completado!"), backgroundColor: Colors.green));
    } else if (eventStatus == 'upcoming') {
      label = "PRÓXIMAMENTE"; icon = Icons.calendar_today; btnColor = Colors.blue;
      action = () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aún no ha comenzado.")));
    } else {
      action = () async {
        final bool? result = await context.push<bool>('/scan', extra: widget.establishment);
        if (result == true && context.mounted) {
          _showVotingDialog(context, ref, widget.establishment, currentEventId);
        }
      };
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: action, icon: Icon(icon), label: Text(label),
        style: ElevatedButton.styleFrom(backgroundColor: btnColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
      ),
    );
  }
*/
  Widget _buildScanButton(ProductModel? product, AsyncValue productsAsync, bool hasStamp, String eventStatus, int currentEventId) {
    // BLOQUEO SI EL ESTABLECIMIENTO ESTÁ INACTIVO 🔥
    if (!widget.establishment.isActive) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: const [
            Icon(Icons.lock_clock, color: Colors.grey, size: 30),
            SizedBox(height: 8),
            Text(
              "ESTABLECIMIENTO NO DISPONIBLE",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            Text(
              "No se pueden realizar votaciones actualmente.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    String label = "ESCANEAR CÓDIGO";
    IconData icon = Icons.qr_code_scanner;
    Color btnColor = Colors.orange;
    VoidCallback? action;

    // Lógica normal de estados
    if (hasStamp) {
      label = "¡VISADO!"; icon = Icons.check_circle; btnColor = Colors.green;
      action = () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ya completado!"), backgroundColor: Colors.green));
    } else if (eventStatus == 'upcoming') {
      label = "PRÓXIMAMENTE"; icon = Icons.calendar_today; btnColor = Colors.blue;
      action = () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aún no ha comenzado.")));
    } else {
      // Acción de Escáner QR normal
      action = () async {
        final bool? result = await context.push<bool>('/scan', extra: widget.establishment);
        if (result == true && context.mounted) {
          _showVotingDialog(context, ref, widget.establishment, currentEventId);
        }
      };
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: action, icon: Icon(icon), label: Text(label),
            style: ElevatedButton.styleFrom(backgroundColor: btnColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),

        // 🔥 ENLACE DE EMERGENCIA (PIN)
        // Solo aparece si el evento está activo y el usuario NO ha votado todavía.
        if (!hasStamp && eventStatus == 'active')
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: InkWell(
              onTap: () => _showWaiterPinDialog(context, currentEventId),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      "¿Problemas técnicos? Usar código manual",
                      style: TextStyle(
                        color: Colors.grey[700], 
                        fontSize: 12, 
                        decoration: TextDecoration.underline
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMapSection({required double height}) {
    // 🔥 1. SI NO HAY COORDENADAS: Mostramos la tarjeta elegante
    if (widget.establishment.latitude == null || widget.establishment.longitude == null) {
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!)
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, color: Colors.grey, size: 30),
            SizedBox(height: 8),
            Text("Ubicación exacta no disponible", style: TextStyle(color: Colors.grey)),
          ],
        )
      );
    }

    // 🔥 2. SI SÍ HAY COORDENADAS: Mostramos el mapa interactivo (Tu código original)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Ubicación", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(
              height: height,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(widget.establishment.latitude!, widget.establishment.longitude!),
                    initialZoom: 15.0,
                  ),
                  children: [
                    
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'es.sietefinn.appvivetorredelmar',
                    ),
                    
                    if (routePoints.isNotEmpty) PolylineLayer(polylines: [Polyline(points: routePoints, strokeWidth: 5.0, color: Colors.blueAccent)]),
                    MarkerLayer(markers: [
                      Marker(point: LatLng(widget.establishment.latitude!, widget.establishment.longitude!), width: 60, height: 60, child: const Icon(Icons.location_on, color: Colors.red, size: 50)),
                      if (myPosition != null) Marker(point: myPosition!, width: 40, height: 40, child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40)),
                    ]),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16, right: 16,
              child: FloatingActionButton.extended(
                heroTag: "btn_route_${widget.establishment.id}",
                onPressed: isRouteLoading ? null : _calculateRoute,
                icon: isRouteLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()) : const Icon(Icons.route),
                label: Text(routePoints.isEmpty ? "Ver Ruta" : "Recalcular"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- DIÁLOGO PIN CAMARERO ---
  void _showWaiterPinDialog(BuildContext context, int eventId) {
    final pinController = TextEditingController();
    bool loading = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.vpn_key, color: Colors.orange),
              SizedBox(width: 10),
              Text("Validación Manual"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Si tienes problemas con el QR o el GPS, pide al personal el código de validación.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, letterSpacing: 8, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: "••••",
                  counterText: "",
                  errorText: errorText,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: (_) {
                  if (errorText != null) setDialogState(() => errorText = null);
                },
              ),
              const SizedBox(height: 10),
              if (loading) const LinearProgressIndicator(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: loading ? null : () async {
                final inputPin = pinController.text.trim();
                if (inputPin.length < 4) {
                  setDialogState(() => errorText = "Introduce 4 dígitos");
                  return;
                }

                setDialogState(() => loading = true);

                try {
                  // CONSULTA A SUPABASE (Simple y directa)
                  final response = await Supabase.instance.client
                      .from('establishments')
                      .select('waiter_pin')
                      .eq('id', widget.establishment.id)
                      .single();

                  final String? realPin = response['waiter_pin'];

                  // Verificamos (Si realPin es null, nadie puede votar por PIN aquí)
                  if (realPin != null && realPin == inputPin) {
                    // ✅ PIN CORRECTO
                    if (context.mounted) Navigator.pop(ctx); // Cerrar diálogo PIN
                    
                    // Abrir votación directamente
                    if (mounted) {
                      _showVotingDialog(context, ref, widget.establishment, eventId);
                    }
                  } else {
                    // ❌ PIN INCORRECTO
                    setDialogState(() {
                      loading = false;
                      errorText = "Código incorrecto";
                      pinController.clear();
                    });
                  }
                } catch (e) {
                  Logger.error("Error PIN: $e", "ESTABLISHMENT_DETAIL_SCREEN");
                  setDialogState(() {
                    loading = false;
                    errorText = "Error de conexión";
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text("VALIDAR"),
            ),
          ],
        ),
      ),
    );
  }

}

// --- WIDGETS DE BOTONES ---
class _ActionButton extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap; final Color color;
  const _ActionButton({required this.icon, required this.label, required this.onTap, this.color = Colors.orange});
  @override
  Widget build(BuildContext context) {
    return Column(children: [InkWell(onTap: onTap, child: CircleAvatar(radius: 26, backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color, size: 24))), const SizedBox(height: 6), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54))]);
  }
}

class _SocialButton extends StatelessWidget {
  final dynamic icon; // <--- LA CLAVE: Cambiado de IconData a dynamic
  final Color color; 
  final VoidCallback onTap;
  
  const _SocialButton({required this.icon, required this.color, required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12), 
      child: InkWell(
        onTap: onTap, 
        child: Container(
          padding: const EdgeInsets.all(10), 
          decoration: const BoxDecoration(
            shape: BoxShape.circle, 
            color: Colors.white, 
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]
          ), 
          child: FaIcon(icon, color: color, size: 22) // Usamos FaIcon
        )
      )
    );
  }
}

// --- WIDGET ALÉRGENOS ---
class _AllergenChip extends StatelessWidget {
  final String label;
  const _AllergenChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1), // Amarillo muy claro (Amber 50)
        borderRadius: BorderRadius.circular(4), // Borde casi cuadrado (etiqueta)
        border: Border.all(color: Colors.amber.shade800, width: 1.5), // Borde oscuro
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.orange.shade800, // Texto oscuro para contraste
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic, 
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// --- DIÁLOGOS DE VOTACIÓN (Tu código original intacto) ---
void _showVotingDialog(BuildContext context, WidgetRef ref, EstablishmentModel establishment, int eventId) {
  int rating = 0;
  showDialog(
    context: context, barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text("¡Código Correcto! ✅"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [const Text("Valora la tapa:"), const SizedBox(height: 20), StarRatingSelector(onRatingChanged: (v) => setState(() => rating = v))]),
        actions: [TextButton(onPressed: rating == 0 ? null : () async {
          Navigator.pop(context);
          await ref.read(passportRepositoryProvider).saveStamp(establishmentId: establishment.id, establishmentName: establishment.name, gpsVerified: true, rating: rating, eventId: eventId);
          ref.invalidate(hasStampProvider(establishmentId: establishment.id, eventId: eventId));
          ref.read(syncServiceProvider).syncPendingVotes(targetEventId: eventId);
          if (context.mounted) _showSuccessAndShareDialog(context, establishment.name, rating);
        }, child: const Text("GUARDAR"))],
      ),
    ),
  );
}

void _showSuccessAndShareDialog(BuildContext context, String barName, int rating) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("¡Voto Guardado!"),
      content: Text("Has dado $rating estrellas ⭐"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Salir")),
        ElevatedButton.icon(
          icon: Icon(kIsWeb ? Icons.copy : Icons.share), // Icono cambia en web
          label: Text(kIsWeb ? "Copiar enlace" : "Compartir"),
          onPressed: () {
            final String message = "¡Acabo de probar la tapa de *$barName* en la Ruta de la Tapa! 🥘😋\nMi valoración: $rating/5 ⭐\n\nDescarga la App: www.torredelmar.org";
            
            if (kIsWeb) {
              // LÓGICA WEB: COPIAR AL PORTAPAPELES
              Clipboard.setData(ClipboardData(text: message)).then((_) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Texto copiado al portapapeles. ¡Pégalo en WhatsApp!"), backgroundColor: Colors.green),
                );
              });
            } else {
              // LÓGICA MÓVIL: COMPARTIR NATIVO
              Share.share(message);
              Navigator.pop(ctx);
            }
          },
        ),
      ],
    ),
  );
}