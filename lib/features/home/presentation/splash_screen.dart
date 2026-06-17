import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vive_core/core/widgets/responsive_center.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // 1. Esperamos unos segundos para "hacer marca" (branding)
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // 2. Vamos a la pantalla principal 
      context.go('/'); // O la ruta inicial que quiera
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveCenter(
      child: Scaffold(
      backgroundColor: Colors.white, // El mismo color que la nativa
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0), // Márgenes de seguridad
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // LOGO COMPLETO (Con Texto)
              // Aquí SÍ se redimensiona solo gracias a Flutter
              Image.asset(
                'assets/images/app_logo.png', 
                fit: BoxFit.contain, // <--- Se ajusta sin cortarse
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(), // Opcional: Spinner de carga
            ],
          ),
        ),
      ),
    ),
    );
  }
}