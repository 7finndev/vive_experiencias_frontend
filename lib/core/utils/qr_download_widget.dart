import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; 
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_saver/file_saver.dart';
import 'package:vive_core/core/utils/logger_service.dart'; 

class QrDownloadSection extends StatelessWidget {
  final String dataContent;
  final String establishmentName;
  final GlobalKey _qrKey = GlobalKey();

  QrDownloadSection({
    super.key, 
    required this.dataContent,
    required this.establishmentName,
  });

  Future<void> _descargarQr(BuildContext context) async {
    try {
      // 1. CAPTURA
      // Verificamos que el contexto siga montado y sea válido
      if (_qrKey.currentContext == null) return;
      
      RenderRepaintBoundary boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      // 2. CONVERSIÓN
      ui.Image image = await boundary.toImage(pixelRatio: 5.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();

        // Lógica de nombre limpio
        final cleanName = establishmentName
          .toLowerCase()
          .replaceAll(RegExp(r'[áàäâ]'), 'a')
          .replaceAll(RegExp(r'[éèëê]'), 'e')
          .replaceAll(RegExp(r'[íìïî]'), 'i')
          .replaceAll(RegExp(r'[óòöô]'), 'o')
          .replaceAll(RegExp(r'[úùüû]'), 'u')
          .replaceAll('ñ', 'n')
          .replaceAll(RegExp(r'[^\w\s]'), '') 
          .trim()
          .replaceAll(RegExp(r'\s+'), '_');
        
        final fileName = 'qr_$cleanName'; // Sin extensión aquí, la librería la pone

        // 3. GUARDADO UNIVERSAL (Web + Linux + Windows + Mac + Móvil)
        // Esta función detecta si es Web (descarga) o Desktop (guardar como)
        String? path = await FileSaver.instance.saveFile(
          name: fileName,
          bytes: pngBytes,
          fileExtension: 'png',
          mimeType: MimeType.png,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ QR descargado correctamente${path.isNotEmpty ? " en: $path" : ""}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      Logger.error("Error guardando QR: $e", "QR_DOWNLOAD_WIDGET");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar la imagen'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Envolvemos el QR en RepaintBoundary
        RepaintBoundary(
          key: _qrKey,
          child: Container(
            color: Colors.white, 
            padding: const EdgeInsets.all(20.0),
            child: QrImageView(
              data: dataContent,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        ElevatedButton.icon(
          onPressed: () => _descargarQr(context),
          icon: const Icon(Icons.download_rounded),
          label: const Text("Descargar Imagen QR"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
      ],
    );
  }
}