import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

// WIDGETS Y UTILS
import 'package:vive_core/core/widgets/web_container.dart';
import 'package:vive_core/core/utils/image_helper.dart';

// PROVIDERS Y REPOSITORIOS
import 'package:vive_core/features/auth/presentation/providers/auth_provider.dart';
import 'package:vive_core/features/scan/data/repositories/passport_repository.dart';
import 'package:vive_core/features/scan/presentation/providers/sync_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final int? eventId;
  const ProfileScreen({super.key, this.eventId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  Uint8List? _selectedImageBytes;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final bytes = await ImageHelper.pickAndCompress(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      quality: 85,
    );

    if (bytes != null) {
      setState(() {
        _selectedImageBytes = bytes;
        _isEditing = true;
      });
    }
  }

  Future<void> _saveProfile(String userId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(authRepositoryProvider).updateProfile(
            userId: userId,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            imageBytes: _selectedImageBytes,
          );

      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Perfil guardado correctamente'), backgroundColor: Colors.green));
        setState(() {
          _isEditing = false;
          _selectedImageBytes = null;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final repo = ref.read(passportRepositoryProvider);
    final authRepo = ref.read(authRepositoryProvider);

    if (repo.hasPendingData) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("⚠️ Datos sin guardar"),
          content: const Text("Tienes votos pendientes de subir. Si cierras sesión ahora, se perderán."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR")),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("SALIR IGUAL")),
          ],
        ),
      );
      if (confirm != true) return;
    }

    await repo.clearLocalData();
    await authRepo.signOut();
    if (context.mounted) context.pop();
  }

  // 🔥 FIX APLICADO AQUÍ: Scroll en el diálogo
  void _showEnlargedQR(String data) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView( // <--- ¡ESTO SOLUCIONA EL PROBLEMA EN HORIZONTAL!
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("TU PASE DIGITAL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 250,
                  width: 250,
                  child: QrImageView(
                    data: data,
                    version: QrVersions.auto,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Presenta este código", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("CERRAR"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final profileAsync = ref.watch(userProfileProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Mi Perfil")),
        body: const Center(child: Text("No hay sesión activa")),
      );
    }

    String currentName = '';
    String currentPhone = '';
    String currentEmail = user.email ?? '';
    String? remoteAvatarUrl;

    if (profileAsync.value != null) {
      final data = profileAsync.value!;
      currentName = data['full_name'] ?? '';
      currentPhone = data['phone'] ?? '';
      remoteAvatarUrl = data['avatar_url'];
      if (remoteAvatarUrl != null) remoteAvatarUrl = "$remoteAvatarUrl?t=${DateTime.now().millisecondsSinceEpoch}";
    } else {
      final meta = user.userMetadata;
      currentName = meta?['full_name'] ?? meta?['name'] ?? '';
      currentPhone = meta?['phone'] ?? '';
      remoteAvatarUrl = meta?['avatar_url'];
    }

    if (!_isEditing) {
      _nameController.text = currentName;
      _phoneController.text = currentPhone;
      _emailController.text = currentEmail;
    }

    ImageProvider? imageProvider;
    if (_selectedImageBytes != null) {
      imageProvider = MemoryImage(_selectedImageBytes!);
    } else if (remoteAvatarUrl != null && remoteAvatarUrl.isNotEmpty) {
      imageProvider = NetworkImage(remoteAvatarUrl);
    }

    final isDesktop = MediaQuery.of(context).size.width > 900;

    return WebContainer(
      backgroundColor: Colors.grey[100],
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text("Ficha de Usuario", style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          actions: [
            if (_isEditing)
              IconButton(
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check, color: Colors.green, size: 28),
                onPressed: _isLoading ? null : () => _saveProfile(user.id),
                tooltip: "Guardar Cambios",
              )
            else
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => setState(() => _isEditing = true),
                tooltip: "Editar Perfil",
              ),
          ],
        ),
        body: isDesktop
            ? _buildDesktopLayout(user.id, imageProvider)
            : _buildMobileLayout(user.id, imageProvider),
      ),
    );
  }

  Widget _buildMobileLayout(String userId, ImageProvider? imageProvider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageHeight = screenWidth > 400 ? 400.0 : screenWidth;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildImageSection(imageProvider, height: imageHeight),
          const SizedBox(height: 20),
          _buildDataSection(userId),
          const SizedBox(height: 30),
          _buildLogoutButton(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(String userId, ImageProvider? imageProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              children: [
                _buildImageSection(imageProvider, height: 500),
                const SizedBox(height: 20),
                _buildLogoutButton(context),
              ],
            ),
          ),
          const SizedBox(width: 40),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDataSection(userId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(ImageProvider? imageProvider, {required double height}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: imageProvider != null
                ? Image(
                    image: imageProvider,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Center(
                        child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person, size: 80, color: Colors.white54),
                        SizedBox(height: 10),
                        Text("Sin foto de perfil", style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
          ),
          if (_isEditing)
            Positioned(
              bottom: 15,
              right: 15,
              child: FloatingActionButton(
                heroTag: 'fab_pick_image', // Evita conflictos si hay varios FAB
                onPressed: _pickImage,
                backgroundColor: Colors.blue,
                child: const Icon(Icons.camera_alt, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDataSection(String userId) {
    return Column(
      children: [
        Card(
          elevation: 0,
          color: Colors.grey[50],
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("INFORMACIÓN PERSONAL",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)),
                  const SizedBox(height: 20),
                  _buildTextField(
                      label: "Nombre Completo",
                      controller: _nameController,
                      icon: Icons.badge_outlined,
                      enabled: _isEditing),
                  const SizedBox(height: 15),
                  _buildTextField(
                      label: "Teléfono",
                      controller: _phoneController,
                      icon: Icons.phone_android,
                      enabled: _isEditing,
                      inputType: TextInputType.phone),
                  const SizedBox(height: 15),
                  _buildTextField(
                      label: "Email",
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      enabled: false,
                      isReadOnly: true),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        GestureDetector(
          onTap: () => _showEnlargedQR(userId),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100)),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("TU PASE DIGITAL", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      SizedBox(height: 5),
                      Text(
                        "Pulsa el código QR para ampliarlo.",
                        style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Muéstralo a la organización para identificarte.",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Hero(
                  tag: 'qr_hero',
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)]),
                    child: QrImageView(
                      data: userId,
                      version: QrVersions.auto,
                      size: 90.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (widget.eventId != null && !_isEditing) ...[
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sincronizando... ☁️")));
                try {
                  await ref.read(syncServiceProvider).syncPendingVotes(targetEventId: widget.eventId!);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("¡Sincronizado! ✅"), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: const Icon(Icons.cloud_sync),
              label: const Text("Sincronizar Votos"),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    if (_isEditing) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _logout(context),
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
        style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            side: BorderSide(color: Colors.red.shade200),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }

  Widget _buildTextField(
      {required String label,
      required TextEditingController controller,
      required IconData icon,
      bool enabled = true,
      bool isReadOnly = false,
      TextInputType inputType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: inputType,
      style: TextStyle(color: isReadOnly ? Colors.grey[600] : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: !enabled || isReadOnly,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }
}