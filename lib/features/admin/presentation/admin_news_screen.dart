import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

// RUTA AL IMAGE HELPER
import 'package:vive_core/core/utils/image_helper.dart';
import 'package:vive_core/core/utils/logger_service.dart';

// MODELOS
import 'package:vive_core/features/hub/data/models/app_config_model.dart';
import 'package:vive_core/features/hub/data/models/app_news_model.dart'; 

// =============================================================================
// 🔥 PROVIDER SEGURO: Busca la ciudad REAL del Admin en su perfil de base de datos
// =============================================================================
final adminNewsProvider = FutureProvider.autoDispose<List<AppNewsModel>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  
  if (user == null) return [];

  // 1. Buscamos a qué ciudad pertenece el Admin logueado
  final profile = await supabase.from('profiles').select('city_id').eq('id', user.id).maybeSingle();
  final adminCityId = profile?['city_id'];

  if (adminCityId == null) return [];

  // 2. Traemos SOLO las noticias de esa ciudad
  final response = await supabase
      .from('app_news')
      .select()
      .eq('city_id', adminCityId)
      .order('priority', ascending: false)
      .order('published_at', ascending: false);
      
  return response.map((json) => AppNewsModel.fromJson(json)).toList();
});


class AdminNewsScreen extends ConsumerStatefulWidget {
  const AdminNewsScreen({super.key});

  @override
  ConsumerState<AdminNewsScreen> createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends ConsumerState<AdminNewsScreen> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    // Escuchamos el provider seguro que acabamos de crear
    final newsAsync = ref.watch(adminNewsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Noticias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar lista',
            onPressed: () {
              ref.invalidate(adminNewsProvider);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Actualizando...'), duration: Duration(milliseconds: 800)));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuración',
            onPressed: () => _showConfigDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_add_news', // Evita conflictos si hay varios FAB
        child: const Icon(Icons.add),
        onPressed: () => _showNewsForm(context, null),
      ),
      body: newsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (data) {
          if (data.isEmpty) return const Center(child: Text('No hay noticias en tu franquicia.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final news = data[index];
              return _NewsCard(
                news: news,
                onEdit: () => _showNewsForm(context, news),
                onDelete: () => _deleteNews(news.id),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteNews(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Borrar noticia?'),
        content: const Text('Se eliminará permanentemente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Borrar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _supabase.from('app_news').delete().eq('id', id);
      
      ref.invalidate(adminNewsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Noticia eliminada')));
      }
    }
  }

  void _showConfigDialog(BuildContext context) async {
    try {
      // Obtenemos la ciudad del perfil del admin
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      final profile = await _supabase.from('profiles').select('city_id').eq('id', user.id).maybeSingle();
      final adminCityId = profile?['city_id'];

      final data = await _supabase.from('app_config').select().eq('city_id', adminCityId).maybeSingle();
      
      if (!mounted) return;
      
      if (data == null) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay configuración para esta ciudad aún')));
         return;
      }
      
      final config = AppConfigModel.fromJson(data);
      showDialog(context: context, builder: (ctx) => _ConfigDialog(config: config));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando config: $e')));
    }
  }

  void _showNewsForm(BuildContext context, AppNewsModel? news) {
    showDialog(
      context: context,
      builder: (ctx) => _NewsFormDialog(news: news),
    );
  }
}

// =============================================================================
// WIDGET: CARD DE NOTICIA
// =============================================================================
class _NewsCard extends StatelessWidget {
  final AppNewsModel news;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NewsCard({required this.news, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: news.imageUrl != null
              ? Image.network(news.imageUrl!, width: 50, height: 50, fit: BoxFit.cover, 
                  errorBuilder: (_,_,_) => Container(width: 50, height: 50, color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 20)))
              : Container(width: 50, height: 50, color: Colors.blue[100], child: const Icon(Icons.newspaper, color: Colors.blue)),
        ),
        title: Text(
          news.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            decoration: news.isActive ? null : TextDecoration.lineThrough,
            color: news.isActive ? null : Colors.grey,
          ),
        ),
        subtitle: Text('Prioridad: ${news.priority}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DIÁLOGO: FORMULARIO 
// =============================================================================
class _NewsFormDialog extends ConsumerStatefulWidget {
  final AppNewsModel? news;

  const _NewsFormDialog({this.news});

  @override
  ConsumerState<_NewsFormDialog> createState() => _NewsFormDialogState();
}

class _NewsFormDialogState extends ConsumerState<_NewsFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleCtrl;
  late TextEditingController _linkCtrl;
  late double _priority;
  late bool _isActive;

  String? _currentImageUrl; 
  Uint8List? _newImageBytes; 
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final n = widget.news;
    _titleCtrl = TextEditingController(text: n?.title ?? '');
    _linkCtrl = TextEditingController(text: n?.linkUrl ?? '');
    _priority = (n?.priority ?? 0).toDouble();
    _isActive = n?.isActive ?? true;
    _currentImageUrl = n?.imageUrl;
  }

  Future<void> _pickImage() async {
    final Uint8List? bytes = await ImageHelper.pickAndCompress(
      source: ImageSource.gallery,
      quality: 70, 
      maxWidth: 1024,
    );

    if (bytes != null) {
      setState(() {
        _newImageBytes = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.news == null ? 'Nueva Noticia' : 'Editar Noticia'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildPreview(),
                ),
              ),
              const SizedBox(height: 5),
              const Text("Toca para subir imagen", style: TextStyle(fontSize: 10, color: Colors.grey)),
              
              const SizedBox(height: 15),

              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Título', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _linkCtrl,
                decoration: const InputDecoration(labelText: 'Enlace (Opcional)', prefixIcon: Icon(Icons.link), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              
              Row(
                children: [
                  const Text('Prioridad: '),
                  Expanded(
                    child: Slider(
                      value: _priority, min: 0, max: 10, divisions: 10, label: _priority.round().toString(),
                      onChanged: (v) => setState(() => _priority = v),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                title: const Text('Visible'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (_isUploading)
          const Padding(padding: EdgeInsets.only(right: 20, bottom: 10), child: CircularProgressIndicator())
        else ...[
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(onPressed: _save, child: const Text('Guardar')),
        ]
      ],
    );
  }

  Widget _buildPreview() {
    const BoxFit fitMode = BoxFit.contain; 
    if (_newImageBytes != null) {
      return Image.memory(_newImageBytes!, fit: fitMode);
    } else if (_currentImageUrl != null) {
      return Image.network(_currentImageUrl!, fit: fitMode, errorBuilder: (_,_,_) => const Icon(Icons.broken_image));
    }
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey), Text("Toca para subir", style: TextStyle(color: Colors.grey))]
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUploading = true);

    try {
      final supabase = Supabase.instance.client;
      
      // 🔥 OBTENEMOS LA CIUDAD REAL DEL ADMIN ANTES DE GUARDAR
      final user = supabase.auth.currentUser;
      final profile = await supabase.from('profiles').select('city_id').eq('id', user!.id).maybeSingle();
      final adminCityId = profile?['city_id'];

      if (adminCityId == null) throw Exception("No se encontró la franquicia de este usuario");

      String? finalImageUrl = _currentImageUrl;

      if (_newImageBytes != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg'; 
        final filePath = 'news_images/$fileName'; 

        await supabase.storage.from('news').uploadBinary(
          filePath, _newImageBytes!,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );

        finalImageUrl = supabase.storage.from('news').getPublicUrl(filePath);
      }

      final data = {
        'title': _titleCtrl.text,
        'image_url': finalImageUrl,
        'link_url': _linkCtrl.text.isNotEmpty ? _linkCtrl.text : null,
        'priority': _priority.round(),
        'is_active': _isActive,
        'updated_at': DateTime.now().toIso8601String(),
        'city_id': adminCityId, // 🔥 GUARDADO BLINDADO
      };

      if (widget.news == null) {
        await supabase.from('app_news').insert(data);
      } else {
        await supabase.from('app_news').update(data).eq('id', widget.news!.id);
      }

      ref.invalidate(adminNewsProvider);

      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.news == null ? 'Noticia creada con éxito' : 'Noticia actualizada'), backgroundColor: Colors.green));
      }
    } catch (e) {
      Logger.error("Error guardando noticia: $e", "ADMIN_NEWS_SCREEN");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        setState(() => _isUploading = false); 
      }
    }
  }
}

// =============================================================================
// DIÁLOGO CONFIGURACIÓN 
// =============================================================================
class _ConfigDialog extends StatefulWidget {
  final AppConfigModel config;
  const _ConfigDialog({required this.config});
  @override
  State<_ConfigDialog> createState() => _ConfigDialogState();
}

class _ConfigDialogState extends State<_ConfigDialog> {
  late TextEditingController _intervalCtrl;
  late TextEditingController _maxCountCtrl;
  late bool _externalEnabled;

  @override
  void initState() {
    super.initState();
    _intervalCtrl = TextEditingController(text: (widget.config.carouselIntervalMs / 1000).toString());
    _maxCountCtrl = TextEditingController(text: widget.config.maxNewsCount.toString());
    _externalEnabled = widget.config.enableExternalSource;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configuración Global'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Noticias Externas'),
            subtitle: const Text('Mostrar desde web oficial'),
            value: _externalEnabled,
            onChanged: (v) => setState(() => _externalEnabled = v),
          ),
          TextField(controller: _intervalCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Segundos Carrusel')),
          TextField(controller: _maxCountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Máx. Noticias')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _save, child: const Text('Actualizar')),
      ],
    );
  }

  Future<void> _save() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      final profile = await supabase.from('profiles').select('city_id').eq('id', user!.id).maybeSingle();
      final adminCityId = profile?['city_id'];

      final interval = (int.tryParse(_intervalCtrl.text) ?? 5) * 1000;
      final max = int.tryParse(_maxCountCtrl.text) ?? 5;
      
      await supabase.from('app_config').update({
        'carousel_interval_ms': interval,
        'max_news_count': max,
        'enable_external_source': _externalEnabled,
      }).eq('city_id', adminCityId);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración guardada'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}