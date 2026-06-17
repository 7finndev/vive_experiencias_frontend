import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vive_core/features/auth/presentation/providers/auth_provider.dart';
import 'package:vive_core/core/widgets/version_tag.dart';

class SuperadminShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const SuperadminShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Detectamos si es pantalla grande
    final width = MediaQuery.of(context).size.width;
    final bool isDesktop = width > 900;

    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'Superadmin';

    final menuContent = _SuperadminMenuContent(
      navigationShell: navigationShell,
      email: email,
      onLogout: () async {
        await ref.read(authRepositoryProvider).signOut();
        if (context.mounted) context.go('/hq'); // Volvemos a la puerta trasera
      },
    );

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text(
                "SaaS Workspace",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              backgroundColor: const Color(0xFF121212), // Color B2B
              iconTheme: const IconThemeData(color: Colors.white),
            ),
      drawer: isDesktop ? null : Drawer(child: menuContent),
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          if (isDesktop) SizedBox(width: 250, child: menuContent),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

class _SuperadminMenuContent extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final String email;
  final VoidCallback onLogout;

  const _SuperadminMenuContent({
    required this.navigationShell,
    required this.email,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    // Por mejoras de Flutter se modifica Container por Material
    //return Container(
    return Material(
      color: const Color(0xFF1E1E1E), // Fondo menú Superadmin
      child: Column(
        children: [
          // 1. CABECERA
          Container(
            padding: const EdgeInsets.only(
              top: 50,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            color: const Color(0xFF121212),
            width: double.infinity,
            child: Column(
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  size: 50,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 10),
                const Text(
                  "GESTIÓN GLOBAL",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  email,
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 2. LISTA CON TODO
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: Text(
                    "CONTROL GLOBAL",
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _SuperadminMenuItem(
                  icon: Icons.public,
                  label: "Vista General",
                  index: 0,
                  navigationShell: navigationShell,
                ),
                _SuperadminMenuItem(
                  icon: Icons.location_city,
                  label: "Franquicias",
                  index: 1,
                  navigationShell: navigationShell,
                ),
                _SuperadminMenuItem(
                  icon: Icons.manage_accounts,
                  label: "Gestores",
                  index: 2,
                  navigationShell: navigationShell,
                ),

                const Divider(color: Colors.white10, height: 30),

                const Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 8),
                  child: Text(
                    "SISTEMA",
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                ListTile(
                  leading: const Icon(
                    Icons.home_outlined,
                    color: Colors.greenAccent,
                  ),
                  title: const Text(
                    "Ir a la Web Pública",
                    style: TextStyle(color: Colors.greenAccent),
                  ),
                  onTap: () {
                    context.go('/');
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    "Cerrar Sesión",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: onLogout,
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: VersionTag(color: Colors.white30)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuperadminMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final StatefulNavigationShell navigationShell;

  const _SuperadminMenuItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = navigationShell.currentIndex == index;

    return Material(
      color: isSelected
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.blueAccent : Colors.white70,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        //tileColor: isSelected ? Colors.white.withValues(alpha: 0.1) : null,
        onTap: () {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
          if (Scaffold.of(context).hasDrawer &&
              Scaffold.of(context).isDrawerOpen) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
