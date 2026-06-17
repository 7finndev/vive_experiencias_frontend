import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vive_core/core/widgets/error_view.dart';
import 'package:vive_core/features/admin/data/superadmin_repository.dart';

class SuperadminDashboardScreen extends ConsumerWidget {
  const SuperadminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(superadminDashboardStatsProvider);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Métricas Globales", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorView(error: err, onRetry: () => ref.invalidate(superadminDashboardStatsProvider)),
        data: (stats) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text("Salud del Negocio", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 16),
              
              // --- TARJETAS DE MÉTRICAS GLOBALES ---
              GridView.count(
                crossAxisCount: isDesktop ? 4 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                // 🔥 RELACIÓN DE ASPECTO CORREGIDA: 1.0 (Cuadrado) en móviles da más altura
                childAspectRatio: isDesktop ? 1.5 : 1.0, 
                children: [
                  _StatCard(title: 'Franquicias Activas', value: stats['total_cities']?.toString() ?? '-', icon: Icons.location_city, color: Colors.blue[900]!),
                  _StatCard(title: 'Gestores Alta', value: stats['total_admins']?.toString() ?? '-', icon: Icons.manage_accounts, color: Colors.indigo),
                  _StatCard(title: 'Turistas (Total)', value: stats['total_users']?.toString() ?? '-', icon: Icons.people, color: Colors.teal),
                  _StatCard(title: 'Escaneos App', value: stats['total_scans']?.toString() ?? '-', icon: Icons.qr_code, color: Colors.orange),
                ],
              ),

              const SizedBox(height: 40),
              const Text("Accesos Directos", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 16),

              // --- BOTONES GRANDES DE NAVEGACIÓN (Estructura segura sin Flex) ---
              if (isDesktop) 
                Row(
                  children: [
                    Expanded(
                      child: _QuickAccessCard(
                        title: "Franquicias / Ayuntamientos",
                        subtitle: "Activar, desactivar o modificar colores corporativos.",
                        icon: Icons.location_city,
                        color: Colors.blue[900]!,
                        onTap: () => context.go('/superadmin/cities'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _QuickAccessCard(
                        title: "Gestores de Cuenta",
                        subtitle: "Asignar usuarios administradores a las franquicias.",
                        icon: Icons.manage_accounts,
                        color: Colors.indigo,
                        onTap: () => context.go('/superadmin/managers'),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _QuickAccessCard(
                      title: "Franquicias / Ayuntamientos",
                      subtitle: "Activar, desactivar o modificar colores corporativos.",
                      icon: Icons.location_city,
                      color: Colors.blue[900]!,
                      onTap: () => context.go('/superadmin/cities'),
                    ),
                    const SizedBox(height: 16),
                    _QuickAccessCard(
                      title: "Gestores de Cuenta",
                      subtitle: "Asignar usuarios administradores a las franquicias.",
                      icon: Icons.manage_accounts,
                      color: Colors.indigo,
                      onTap: () => context.go('/superadmin/managers'),
                    ),
                  ],
                ),
            ],
          );
        }
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value; final IconData icon; final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});
  
  @override 
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12), // Un poco menos de padding ayuda
      decoration: BoxDecoration(
        color: color, 
        borderRadius: BorderRadius.circular(12), 
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 3))]
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10, 
            top: -10, 
            child: Icon(icon, size: 70, color: Colors.white.withValues(alpha: 0.15))
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            mainAxisAlignment: MainAxisAlignment.center, // Centramos verticalmente
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 8),
              // 🔥 FLEXIBLE asegura que el texto se encoja si no hay espacio
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value, 
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                  )
                ),
              ),
              const SizedBox(height: 2),
              // 🔥 ELIPSIS para que el título nunca rompa el diseño
              Text(
                title, 
                style: const TextStyle(color: Colors.white70, fontSize: 11), 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis
              )
            ]
          )
        ],
      )
    );
  }
}
class _QuickAccessCard extends StatelessWidget {
  final String title, subtitle; final IconData icon; final Color color; final VoidCallback onTap;
  const _QuickAccessCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 30)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}