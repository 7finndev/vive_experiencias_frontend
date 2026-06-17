import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:vive_core/core/widgets/error_view.dart';
// import 'package:vive_core/core/widgets/version_tag.dart'; // No hace falta aquí, irá en el Shell
import 'package:vive_core/features/admin/data/dashboard_repository.dart';
import 'package:vive_core/features/home/data/models/event_model.dart';

import 'package:go_router/go_router.dart';
import 'package:vive_core/features/home/presentation/providers/home_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsListAsync = ref.watch(adminEventsListProvider);
    final selectedEvent = ref.watch(dashboardSelectedEventProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      // SIN DRAWER (Ya lo maneja tu AdminShellScreen)
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                title: const Text("Panel de Control", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.white,
                pinned: true,
                floating: true,
                forceElevated: innerBoxIsScrolled,
                iconTheme: const IconThemeData(color: Colors.black87),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      ref.invalidate(dashboardStatsProvider);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Actualizando..."), duration: Duration(milliseconds: 500)));
                    },
                  ),
                ],
                // 🔥 ARREGLO ERROR 5PX OVERFLOW: Aumentamos a 150
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(150),
                  child: Column(
                    children: [
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: _buildEventSelector(context, ref, eventsListAsync, selectedEvent),
                      ),
                      Container(
                        color: Colors.white,
                        child: const TabBar(
                          labelColor: Colors.blue,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Colors.blue,
                          tabs: [
                            Tab(text: "Resumen", icon: Icon(Icons.dashboard_outlined)),
                            Tab(text: "Oferta", icon: Icon(Icons.pie_chart_outline)),
                            Tab(text: "Tecnología", icon: Icon(Icons.devices)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: ErrorView(error: err, onRetry: () => ref.invalidate(dashboardStatsProvider))),
            data: (stats) => TabBarView(
              children: [
                _SummaryTab(stats: stats, selectedEvent: selectedEvent),
                _ChartsTab(stats: stats),
                _DevicesTab(stats: stats),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventSelector(BuildContext context, WidgetRef ref, AsyncValue<List<EventModel>> eventsAsync, EventModel? selectedEvent) {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: eventsAsync.when(
        loading: () => const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        error: (_, _) => const Text("Error"),
        data: (events) {
          EventModel? value = selectedEvent;
          if (value != null && !events.any((e) => e.id == value?.id)) value = null;
          return DropdownButtonHideUnderline(
            child: DropdownButton<EventModel>(
              isExpanded: true,
              hint: const Text("🌍 Todos los Eventos"),
              value: value,
              items: [
                const DropdownMenuItem(value: null, child: Text("🌍 Global (Todos)")),
                ...events.map((e) => DropdownMenuItem(value: e, child: Text(e.name, overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (v) {
                ref.read(dashboardSelectedEventProvider.notifier).state = v;
                Future.delayed(const Duration(milliseconds: 100), () => ref.invalidate(dashboardStatsProvider));
              },
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------
// 📊 TAB 1: RESUMEN (RESPONSIVO REAL)
// -----------------------------------------------------------
class _SummaryTab extends StatelessWidget {
  final DashboardStats stats;
  final EventModel? selectedEvent;
  const _SummaryTab({required this.stats, this.selectedEvent});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false, bottom: false,
      child: Align(
        alignment: Alignment.topCenter, // Centramos el contenido en pantallas grandes
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200), // Ancho máximo para PC
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (selectedEvent != null) ...[
                _EventStatusBanner(event: selectedEvent!), 
                const SizedBox(height: 16)
              ],
              
              const Text("Métricas Clave", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 10),
              
              // GRÁFICA RESPONSIVA (GRID)
              LayoutBuilder(builder: (context, constraints) {
                // Si es ancho > 600 (Tablet/PC) usa 4 columnas, si no 2.
                final int crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
                // Ajustamos el ratio para que las tarjetas no se vean ni muy altas ni muy chatas
                final double ratio = constraints.maxWidth > 800 ? 1.8 : 1.4; 
                
                return GridView.count(
                  crossAxisCount: crossAxisCount, 
                  crossAxisSpacing: 12, 
                  mainAxisSpacing: 12, 
                  shrinkWrap: true, 
                  physics: const NeverScrollableScrollPhysics(), 
                  childAspectRatio: ratio,
                  children: [
                    _StatCard(title: 'Escaneos', value: stats.totalScans.toString(), icon: Icons.qr_code, color: Colors.indigo),
                    _StatCard(title: 'Usuarios', value: stats.totalUsers.toString(), icon: Icons.people, color: Colors.blue),
                    _StatCard(title: 'Productos', value: stats.activeProducts.toString(), icon: Icons.restaurant, color: Colors.orange),
                    _StatCard(title: 'Socios', value: stats.activeEstablishments.toString(), icon: Icons.store, color: Colors.teal),
                  ],
                );
              }),

              const SizedBox(height: 30),
              
              const Text("Acciones Rápidas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 10),
              
              // Aquí usamos LayoutBuilder para decidir si mostramos las acciones en lista o grid
              LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: constraints.maxWidth > 800 
                            ? (constraints.maxWidth - 16) / 2 
                            : constraints.maxWidth,
                        child: _ActionCard(
                          icon: Icons.qr_code_scanner,
                          title: "Validar Ganadores",
                          subtitle: "Comprobar requisitos de sorteo",
                          color: Colors.purple,
                          onTap: () {
                            // 1. OBTENER EL EVENTO SELECCIONADO
                            // Usamos ref.read porque estamos dentro de un callback
                            // Nota: _SummaryTab necesita acceso a 'ref'. 
                            // Como es un StatelessWidget simple, lo mejor es pasárselo 
                            // o convertirlo a ConsumerWidget. 
                            
                            // OPCIÓN RÁPIDA: El widget padre (AdminDashboardScreen) ya tiene el 'selectedEvent'.
                            // Como _SummaryTab recibe 'selectedEvent' en el constructor, lo usamos directo:
                            
                            if (selectedEvent == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("⚠️ Por favor, selecciona un evento específico arriba."),
                                  backgroundColor: Colors.orange
                                )
                              );
                              return;
                            }

                            // 2. VALIDAR ESTADO DEL EVENTO
                            if (selectedEvent!.status == 'upcoming') {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("⏳ Evento no iniciado"),
                                  content: Text("El evento '${selectedEvent!.name}' aún no ha comenzado. No se pueden validar ganadores."),
                                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Entendido"))],
                                ),
                              );
                              return;
                            }

                            // 3. SI TODO OK, NAVEGAMOS
                            // Pasamos el evento como 'extra' para que la pantalla sepa qué validar
                            context.go('/admin/check-winner', extra: selectedEvent);
                          },
                        ),
                      ),
                    ],
                  );
                }
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------
// 🥧 TAB 2: GRÁFICAS (DONUT CENTRADO)
// -----------------------------------------------------------
class _ChartsTab extends StatefulWidget {
  final DashboardStats stats;
  const _ChartsTab({required this.stats});
  @override
  State<_ChartsTab> createState() => _ChartsTabState();
}

class _ChartsTabState extends State<_ChartsTab> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.stats.activeProducts == 0) return const Center(child: Text("Sin datos suficientes"));

    final tapas = widget.stats.countProducts;
    final drinks = widget.stats.countDrinks;
    final shop = widget.stats.countShopping;
    final total = tapas + drinks + shop;

    final isMobile = MediaQuery.of(context).size.width < 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000), 
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
                child: Column(
                  children: [
                    const Text("Oferta Gastronómica", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 30),

                    Flex(
                      direction: isMobile ? Axis.vertical : Axis.horizontal,
                      mainAxisAlignment: MainAxisAlignment.center, 
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 250, 
                          // 🔥 AJUSTE ANCHO PARA EVITAR OVERFLOW EN MÓVIL
                          width: isMobile ? MediaQuery.of(context).size.width * 0.6 : 250,
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(touchCallback: (e, r) {
                                setState(() {
                                  if (r != null && r.touchedSection != null) {
                                    touchedIndex = r.touchedSection!.touchedSectionIndex;
                                  } else {
                                    touchedIndex = -1;
                                  }
                                });
                              }),
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 2, centerSpaceRadius: 40,
                              sections: [
                                _buildSection(0, tapas, total, Colors.orange, Icons.restaurant),
                                _buildSection(1, drinks, total, Colors.purple, Icons.local_bar),
                                _buildSection(2, shop, total, Colors.teal, Icons.shopping_bag),
                              ],
                            ),
                          ),
                        ),
                        if (!isMobile) const SizedBox(width: 60) else const SizedBox(height: 30),
                        Column(
                          crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                          children: _buildLegendItems(tapas, drinks, shop, total),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLegendItems(int tapas, int drinks, int shop, int total) {
      return [
        _LegendIndicator(color: Colors.orange, text: "Tapas", value: tapas, total: total, isTouched: touchedIndex == 0),
        const SizedBox(height: 10),
        _LegendIndicator(color: Colors.purple, text: "Bebidas", value: drinks, total: total, isTouched: touchedIndex == 1),
        const SizedBox(height: 10),
        _LegendIndicator(color: Colors.teal, text: "Tienda", value: shop, total: total, isTouched: touchedIndex == 2),
      ];
    }
  PieChartSectionData _buildSection(int index, int value, int total, Color color, IconData icon) {
      final isTouched = index == touchedIndex;
      final double radius = isTouched ? 100 : 80;
      final double fontSize = isTouched ? 20 : 14;
      return PieChartSectionData(
        color: color, value: value.toDouble(), title: total > 0 ? '${(value/total*100).toStringAsFixed(0)}%' : '0%',
        radius: radius, titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white),
        badgeWidget: _Badge(icon, size: isTouched ? 40 : 30, borderColor: color), badgePositionPercentageOffset: .98,
      );
    }
}

// -----------------------------------------------------------
// 📱 TAB 3: DISPOSITIVOS
// -----------------------------------------------------------
// -----------------------------------------------------------
// 📱 TAB 3: DISPOSITIVOS (ACTUALIZADO)
// -----------------------------------------------------------
class _DevicesTab extends StatelessWidget {
  final DashboardStats stats;
  const _DevicesTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    // Calculamos el total incluyendo Escritorio
    final total = stats.deviceAndroid + stats.deviceIOS + stats.deviceWeb + stats.deviceDesktop;
    
    if (total == 0) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phonelink_off, size: 50, color: Colors.grey),
            SizedBox(height: 10),
            Text("No se han registrado dispositivos aún.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(16), 
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Tecnología de Usuarios", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Text("Distribución por Sistema Operativo real", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 20),
              
              // 1. ANDROID (Verde)
              _DeviceBar(
                label: "Android (Móvil/Tablet)", 
                count: stats.deviceAndroid, 
                total: total, 
                color: const Color(0xFF3DDC84), 
                icon: Icons.android
              ),
              const SizedBox(height: 16),
              
              // 2. iOS (Negro/Gris)
              _DeviceBar(
                label: "iOS (iPhone/iPad)", 
                count: stats.deviceIOS, 
                total: total, 
                color: Colors.black87, 
                icon: Icons.apple
              ),
              const SizedBox(height: 16),

              // 3. ESCRITORIO (Azul Índigo) -> ¡NUEVO!
              _DeviceBar(
                label: "Escritorio (Windows/Mac)", 
                count: stats.deviceDesktop, 
                total: total, 
                color: Colors.indigo, 
                icon: Icons.desktop_windows
              ),
              const SizedBox(height: 16),
              
              // 4. OTROS / WEB (Gris Azulado)
              _DeviceBar(
                label: "Otros / Web Genérico", 
                count: stats.deviceWeb, 
                total: total, 
                color: Colors.blueGrey, 
                icon: Icons.public
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceBar extends StatelessWidget {
  final String label; final int count; final int total; final Color color; final IconData icon;
  const _DeviceBar({required this.label, required this.count, required this.total, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final double percentage = total > 0 ? count / total : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [Icon(icon, size: 20, color: color), const SizedBox(width: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.bold))]),
            Text("$count (${(percentage * 100).toStringAsFixed(1)}%)", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage, minHeight: 10, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value; final IconData icon; final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});
  @override 
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 3))]),
      child: Stack(
        children: [
          Positioned(right: -10, top: -10, child: Icon(icon, size: 60, color: Colors.white.withValues(alpha: 0.2))),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon, color: Colors.white, size: 20), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))), Text(title, style: const TextStyle(color: Colors.white, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)])])
        ],
      )
    );
  }
}
class _Badge extends StatelessWidget {
  final IconData icon; final double size; final Color borderColor;
  const _Badge(this.icon, {required this.size, required this.borderColor});
  @override Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: borderColor)), child: Icon(icon, size: size * 0.6, color: borderColor));
}
class _LegendIndicator extends StatelessWidget {
  final Color color; final String text; final int value; final int total; final bool isTouched;
  const _LegendIndicator({required this.color, required this.text, required this.value, required this.total, required this.isTouched});
  @override Widget build(BuildContext context) => Row(children: [Container(width: 12, height: 12, color: color), const SizedBox(width: 8), Text("$text: $value")]);
}
class _EventStatusBanner extends StatelessWidget {
  final EventModel event; const _EventStatusBanner({required this.event});
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(8), color: Colors.blue[50], child: Text(event.status));
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0, // Plano para diseño moderno
      margin: EdgeInsets.zero, // El margen lo controla el contenedor padre
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono con fondo suave
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              
              // Textos (Con protección anti-desbordamiento)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Flechita
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}