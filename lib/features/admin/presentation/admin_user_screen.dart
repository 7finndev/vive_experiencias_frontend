import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vive_core/core/constants/app_data.dart';
import 'package:vive_core/core/utils/image_picker_widget.dart';
import 'package:vive_core/core/utils/logger_service.dart'; // Asegúrate de tener este import

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = "";
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  Future<void> _loadAllUsers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) throw Exception("Sesión expirada");

      final url = Uri.parse('${AppData.apiUrl}/api/v1/admin/users');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _allUsers = List<Map<String, dynamic>>.from(json['data']);
            _filterList(_searchQuery);
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Error de servidor: ${response.statusCode}");
      }
    } catch (e) {
      Logger.error("Error cargando: $e", "ADMIN_USERS_SCREEN");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterList(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredUsers = _allUsers.where((user) {
        final email = (user['email'] ?? '').toString().toLowerCase();
        final name = (user['full_name'] ?? '').toString().toLowerCase();
        return email.contains(_searchQuery) || name.contains(_searchQuery);
      }).toList();
    });
  }

  // --- LÓGICA DE ACTUALIZACIÓN DE ROL ---
  Future<void> _updateUserRole(String userId, String newRole, {String? newName, String? newAvatar}) async {
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      final updates = {'role': newRole};
      if (newName != null) updates['full_name'] = newName;
      if (newAvatar != null) updates['avatar_url'] = newAvatar;

      final url = Uri.parse('${AppData.apiUrl}/api/v1/admin/users/$userId');
      final response = await http.put(
        url, 
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(updates)
      );

      if (response.statusCode == 200) {
        await _loadAllUsers(); 
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Usuario actualizado a: ${newRole.toUpperCase()}"), backgroundColor: Colors.green));
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      await _loadAllUsers();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  // --- DIÁLOGO DE EDICIÓN ---
  Future<void> _editUserDialog(Map<String, dynamic> user) async {
    final nameCtrl = TextEditingController(text: user['full_name'] ?? '');
    String selectedRole = user['role'] ?? 'user';
    String currentAvatar = user['avatar_url'] ?? '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Editar Usuario"),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // AVATAR
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: ImagePickerWidget(
                      // 🔥 CORRECCIÓN: CAMBIADO DE 'logos' A 'avatars'
                      bucketName: 'avatars', 
                      initialUrl: currentAvatar,
                      height: 120,
                      onImageUploaded: (url) => setDialogState(() => currentAvatar = url),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Nombre", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: "Rol", border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('Usuario Estándar')),
                      DropdownMenuItem(value: 'manager', child: Text('Gestor')),
                      DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                    ],
                    onChanged: (val) => setDialogState(() => selectedRole = val!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _updateUserRole(user['id'], selectedRole, newName: nameCtrl.text, newAvatar: currentAvatar);
              },
              child: const Text("Guardar"),
            )
          ],
        ),
      ),
    );
  }

  // --- BORRAR (SOFT DELETE VÍA FASTAPI) ---
  Future<void> _deleteUser(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Estás seguro?"),
        content: const Text("Se desactivará el perfil de este usuario, pero sus votos se mantendrán para no alterar el concurso."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Desactivar", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // 1. Obtenemos el token de seguridad
        final token = Supabase.instance.client.auth.currentSession?.accessToken;
        if (token == null) throw Exception("Sesión expirada");

        // 2. Llamamos a FastAPI para que actualice el campo is_active a false
        final url = Uri.parse('${AppData.apiUrl}/api/v1/admin/users/$id');
        final response = await http.put(
          url, 
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: jsonEncode({'is_active': false}) // 🔥 El Soft Delete
        );

        if (response.statusCode == 200) {
          await _loadAllUsers(); // Refrescamos la lista
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Usuario desactivado"), backgroundColor: Colors.orange));
        } else {
          throw Exception("Error de servidor: ${response.body}");
        }
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Gestión de Usuarios"),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAllUsers)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "Buscar...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); _filterList(""); }),
                filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
              ),
              onChanged: _filterList,
            ),
          ),
          // --- LISTA DE USUARIOS ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            const Text("No se encontraron usuarios", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredUsers.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          
                          // DATOS
                          final String role = user['role'] ?? 'user';
                          final String name = user['full_name'] ?? 'Sin Nombre';
                          final String email = user['email'] ?? 'Sin Email';
                          
                          // AQUÍ RECUPERAMOS EL AVATAR DE LA BD
                          final String? avatarUrl = user['avatar_url']; 

                          // Lógica Visual de Roles
                          final bool isAdmin = role == 'admin';
                          final bool isManager = role == 'manager';
                          
                          // Comprobar si está activo (por defecto True si es null)
                          final bool isActive = user['is_active'] ?? true;

                          //Color color = isAdmin ? Colors.green : (isManager ? Colors.blue : Colors.grey);
                          //IconData icon = isAdmin ? Icons.admin_panel_settings : (isManager ? Icons.manage_accounts : Icons.person);

                          //Si esta inactivo, todo gris. Si no, colores normales.
                          Color color = !isActive
                            ? Colors.grey
                            : (isAdmin ? Colors.green : (isManager ? Colors.blue : Colors.grey));

                          IconData icon = !isActive
                            ? Icons.block //Icono de bloqueado
                            : (isAdmin ? Icons.admin_panel_settings : (isManager ? Icons.manage_accounts : Icons.person));
                          return Card(
                            elevation: isActive ? 2 : 0,
                            color: isActive ? Colors.white : Colors.grey[100],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: isAdmin || isManager ? color : Colors.transparent, width: 1.5)
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              onTap: () {
                                _editUserDialog(user);
                              },
                              // --- CORRECCIÓN: MOSTRAR AVATAR SI EXISTE ---
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: color.withValues(alpha: 0.1),
                                // Si hay URL válida, la usamos como fondo
                                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) 
                                    ? NetworkImage(avatarUrl) 
                                    : null,
                                // Si NO hay URL, mostramos el icono correspondiente
                                child: (avatarUrl == null || avatarUrl.isEmpty)
                                    ? Icon(icon, color: color)
                                    : null, // Si hay foto, no mostramos icono encima
                              ),
                              // ---------------------------------------------

                              title: Text(
                                name.isNotEmpty ? name : "Usuario", 
                                style: TextStyle(fontWeight: FontWeight.bold, color: isAdmin ? Colors.green.shade900 : Colors.black87)
                              ),
                              
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(email, style: const TextStyle(fontSize: 12)),
                                  if(isAdmin || isManager)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                      child: Text(role.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                                    )
                                ],
                              ),
                              
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blueGrey),
                                    onPressed: () => _editUserDialog(user),
                                    tooltip: "Editar / Avatar",
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _deleteUser(user['id']),
                                    tooltip: "Borrar",
                                  ),
                                  // Switch Rápido
                                  Transform.scale(
                                    scale: 0.8,
                                    child: Switch(
                                      value: isAdmin,
                                      activeThumbColor: Colors.green,
                                      onChanged: (val) {
                                        _updateUserRole(user['id'], val ? 'admin' : 'user');
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}