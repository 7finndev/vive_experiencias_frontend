import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vive_core/features/home/presentation/widgets/city_selector_modal.dart';

class PublicLandingScreen extends StatelessWidget {
  const PublicLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      
      // Interior del menú (revertido a oscuro para mejor integración)
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E1E1E),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.black),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.tour, color: Colors.orangeAccent, size: 40),
                  SizedBox(height: 10),
                  Text(
                    'Vive Experiencias', 
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.android, color: Colors.green),
              title: const Text('Descargar App (Android)', style: TextStyle(color: Colors.white)),
              onTap: () async {
                final url = Uri.parse('https://vivetorredelmar.7finn.es/vive_experiencias.apk');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
            const Divider(color: Colors.white10),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.white54),
              title: const Text('Contacto', style: TextStyle(color: Colors.white70)),
              onTap: () async {
                final url = Uri.parse('mailto:info@7finn.es');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.gavel, color: Colors.white54),
              title: const Text('Aviso Legal', style: TextStyle(color: Colors.white70)),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1E1E1E),
                    title: const Text('Aviso Legal', style: TextStyle(color: Colors.white)),
                    content: const Text(
                      'Proyecto desarrollado como TFG de DAM. Datos y logos utilizados con fines estrictamente académicos.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CERRAR', style: TextStyle(color: Colors.orangeAccent)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.black,
            
            // 🔥 AQUÍ ESTÁ LA CORRECCIÓN PARA LAS TRES LÍNEAS 🔥
            // Usamos un Builder para poder ejecutar openDrawer() correctamente
            leading: Builder(
              builder: (BuildContext context) {
                return IconButton(
                  // Icono de menú (hamburguesa / tres líneas)
                  icon: const Icon(Icons.menu), 
                  // 🚀 COLOR NARANJA AVISO SOLICITADO
                  color: Colors.orangeAccent, 
                  tooltip: 'Abrir menú de navegación',
                  onPressed: () {
                    // Esta función abre el Drawer
                    Scaffold.of(context).openDrawer();
                  },
                );
              },
            ),
            
            flexibleSpace: FlexibleSpaceBar(
              title: const Text("VIVE EXPERIENCIAS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1514933651103-005eec06c04b?q=80&w=1974&auto=format&fit=crop', 
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, const Color(0xFF121212).withValues(alpha: 0.9)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  const Text(
                    "Descubre la mejor gastronomía de tu ciudad",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Selecciona tu localidad para empezar a explorar.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 40),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          CitySelectorModal.show(context);
                        },
                        icon: const Icon(Icons.location_on),
                        label: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("Explorar Localidades", style: TextStyle(fontSize: 18)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}