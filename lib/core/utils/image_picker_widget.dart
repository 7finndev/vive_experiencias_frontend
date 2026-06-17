import 'dart:io';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mime/mime.dart';
import 'package:vive_core/core/utils/logger_service.dart';

class ImagePickerWidget extends StatefulWidget {
  final String? initialUrl;
  final String bucketName;
  final Function(String newUrl) onImageUploaded;
  final double height; // Altura configurable

  const ImagePickerWidget({
    super.key,
    this.initialUrl,
    required this.bucketName,
    required this.onImageUploaded,
    this.height = 250, // Hacemos el cuadro más alto por defecto
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  File? _imageFile;
  XFile? _webImageFile; // Para manejar web mejor
  bool _isUploading = false;
  String? _previewUrl;

  @override
  void initState() {
    super.initState();
    _previewUrl = widget.initialUrl;
  }

  @override
  void didUpdateWidget(covariant ImagePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialUrl != oldWidget.initialUrl) {
      setState(() {
        _previewUrl = widget.initialUrl;
      });
    }
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    
    if (picked == null) return;

    setState(() {
      if (kIsWeb) {
        _webImageFile = picked;
      } else {
        _imageFile = File(picked.path);
      }
      _isUploading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      
      final fileExt = picked.name.split('.').last; 
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName;

      String mimeType = picked.mimeType ?? lookupMimeType(picked.name) ?? 'image/$fileExt';

      final bytes = await picked.readAsBytes();

      await supabase.storage.from(widget.bucketName).uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: mimeType, 
        ),
      );

      final publicUrl = supabase.storage.from(widget.bucketName).getPublicUrl(filePath);

      setState(() {
        _previewUrl = publicUrl;
        _isUploading = false;
      });

      widget.onImageUploaded(publicUrl);

    } catch (e) {
      Logger.error("Error subiendo: $e", "IMAGE_PICKER_WIDGET");
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lógica para determinar qué imagen mostrar
    ImageProvider? imageProvider;
    
    if (kIsWeb && _webImageFile != null) {
      imageProvider = NetworkImage(_webImageFile!.path); // En web, path es un blob url
    } else if (_imageFile != null) {
      imageProvider = FileImage(_imageFile!);
    } else if (_previewUrl != null && _previewUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_previewUrl!);
    }

    return Column(
      children: [
        GestureDetector(
          onTap: _pickAndUpload,
          child: Container(
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200], // Fondo gris para ver los bordes de la imagen
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400, width: 1.5, style: BorderStyle.solid),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : imageProvider != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            // 1. Imagen en modo CONTAIN (Se ve entera)
                            Image(
                              image: imageProvider,
                              fit: BoxFit.contain, 
                              errorBuilder: (c, e, s) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                            ),
                            // 2. Icono de edición en la esquina
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, color: Colors.white, size: 18),
                              ),
                            )
                          ],
                        )
                      : Column( // Placeholder
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 50, color: Colors.grey[500]),
                            const SizedBox(height: 8),
                            Text("Subir Imagen", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                            Text("(JPG, PNG)", style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                          ],
                        ),
            ),
          ),
        ),
      ],
    );
  }
}