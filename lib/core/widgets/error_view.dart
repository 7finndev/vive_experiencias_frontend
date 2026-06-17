import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final bool isCompact;

  const ErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final errString = error.toString().toLowerCase();
    final isNetworkError = errString.contains('socketexception') || 
                           errString.contains('clientexception') || 
                           errString.contains('network') ||
                           errString.contains('handshake') ||
                           errString.contains('lookup');

    final message = isNetworkError
        ? "No hay conexión a internet."
        : "Ocurrió un problema inesperado.";

    final icon = isNetworkError ? Icons.wifi_off_rounded : Icons.error_outline_rounded;

    // A. VERSIÓN COMPACTA (Para sitios pequeños como Noticias)
    if (isCompact) {
      return Center(
        child: SingleChildScrollView( 
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.grey, size: 24),
              const SizedBox(height: 4),
              Text(
                "Sin conexión",
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null)
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18, color: Colors.blue),
                  onPressed: onRetry,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: "Reintentar",
                )
            ],
          ),
        ),
      );
    }

    // B. VERSIÓN COMPLETA (Pantallas enteras)
    return Center(
      child: SingleChildScrollView( 
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Se encoge al contenido
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
              Text(
                isNetworkError ? "¡Vaya! No tienes internet" : "Algo salió mal",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isNetworkError 
                  ? "Revisa tu conexión para ver el contenido actualizado."
                  : "No pudimos cargar la información.\n(Detalle técnico oculto)", 
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 24),
              if (onRetry != null)
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Reintentar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}