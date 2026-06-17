import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vive_core/core/widgets/web_container.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // Controladores de texto
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); 

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    // 1. Validaciones básicas
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      return _showError("Por favor, rellena todos los campos.");
    }
    if (password.length < 6) {
      return _showError("La contraseña debe tener al menos 6 caracteres.");
    }

    setState(() => _isLoading = true);

    try {
      // 2. Registro en Supabase
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        // 🔥 IMPORTANTE: Enviamos el nombre en los metadatos.
        // El Trigger SQL que configuramos ayer lo copiará a la tabla 'profiles'.
        data: {'full_name': name}, 
      );

      if (mounted) {
        setState(() => _isLoading = false);

        // 3. Feedback al usuario
        // Si Supabase requiere confirmar email (configuración por defecto)
        if (response.user != null && response.session == null) {
          _showDialogExito("Te hemos enviado un correo de confirmación. Por favor, revísalo para poder entrar.");
        } else {
          // Si entra directo (autocofirmado desactivado o login automático)
          _showDialogExito("¡Cuenta creada con éxito! Bienvenido.", irAlHome: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String msg = "Error al registrarse.";
        // Mensajes de error amigables
        if (e.toString().contains("already registered")) {
          msg = "Este correo ya está registrado. Prueba a iniciar sesión.";
        } else if (e.toString().contains("network")) {
          msg = "Error de conexión. Revisa tu internet.";
        }
        _showError(msg);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showDialogExito(String msg, {bool irAlHome = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("¡Registro Completado!"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Cerrar diálogo
              if (irAlHome) {
                context.go('/'); // Ir al Hub
              } else {
                context.go('/login'); // Ir al Login
              }
            },
            child: const Text("Entendido"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usamos WebContainer para que en PC se vea centrado y con fondo bonito
    return WebContainer(
      backgroundColor: Colors.grey[100],
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Crear Cuenta"), 
          centerTitle: true,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              // Limitamos el ancho para que no se estire en PC
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  const Icon(Icons.person_add_outlined, size: 80, color: Colors.blueGrey),
                  const SizedBox(height: 20),
                  const Text(
                    "Únete a la experiencia", 
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Rellena tus datos para empezar.",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 30),

                  // CAMPO NOMBRE
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: "Nombre Completo",
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // CAMPO EMAIL
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Correo electrónico",
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // CAMPO PASSWORD
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "Contraseña",
                      helperText: "Mínimo 6 caracteres",
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // BOTÓN REGISTRO
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("CREAR CUENTA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),

                  // VOLVER AL LOGIN
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text("¿Ya tienes cuenta? Inicia sesión"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}