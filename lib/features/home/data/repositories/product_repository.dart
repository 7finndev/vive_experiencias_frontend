import 'dart:convert'; // NUEVO
import 'dart:typed_data';
import 'package:http/http.dart' as http; // NUEVO
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vive_core/core/constants/app_data.dart'; // NUEVO
import 'package:vive_core/core/utils/logger_service.dart';
import '../models/product_model.dart';

part 'product_repository.g.dart';

class ProductRepository {
  final SupabaseClient _client;

  ProductRepository(this._client);

  // ====================================================================
  // 📸 MÉTODOS STORAGE
  // ====================================================================
  Future<String> uploadProductImage(
    String fileName,
    Uint8List fileBytes,
  ) async {
    try {
      final path = 'products/$fileName';
      await _client.storage
          .from('products')
          .uploadBinary(
            path,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );
      return _client.storage.from('products').getPublicUrl(path);
    } catch (e) {
      throw Exception("Error subiendo imagen de producto");
    }
  }

  Future<void> deleteProductImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.last;
      await _client.storage.from('products').remove([fileName]);
    } catch (e) {
      Logger.error(
        "⚠️ Error borrando imagen producto: $e",
        "PRODUCT_REPOSITORY",
      );
    }
  }

  // ====================================================================
  // 📱 MÉTODOS DE LECTURA (APP) - 🔥 AHORA CONECTADOS A FASTAPI
  // ====================================================================

  // 3. Obtener Productos por Evento
  Future<List<ProductModel>> getProductsByEvent(int eventId) async {
    try {
      Logger.info(
        '🥘 Bajando Tapas del Evento $eventId desde FastAPI...',
        "PRODUCT_REPOSITORY",
      );

      final url = Uri.parse('${AppData.apiUrl}/api/v1/products/$eventId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> data = jsonResponse['data'];

        // NOTA: FastAPI ahora mismo no devuelve los 'product_items' anidados (hijos).
        // Mostraremos las tapas base. Lo mejoraremos cuando ataquemos el Admin.
        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw Exception('Error de FastAPI: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('⚠️ ERROR REMOTO (Tapas): $e', "PRODUCT_REPOSITORY");
      throw Exception('Error cargando productos desde el servidor');
    }
  }

  // ====================================================================
  // 🛠️ MÉTODOS DE ADMINISTRACIÓN (CRUD) - AHORA VÍA FASTAPI
  // ====================================================================

  Future<void> createProduct(ProductModel product) async {
    // 1. Conseguir el token del admin logueado
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) throw Exception('No hay sesión activa.');

    // 2. Preparar el JSON (Flutter llamará a product.toJson() y enviará todo,
    // pero debemos asegurarnos de añadir 'items' que tu toJson actual ignoraba).
    final data = product.toJson();
    data.remove('id');
    data['items'] = product.items.map((i) => i.toJson()).toList();

    // 3. Enviar a FastAPI
    final url = Uri.parse('${AppData.apiUrl}/api/v1/admin/products');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error del servidor: ${response.body}');
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) throw Exception('No hay sesión activa.');

    final data = product.toJson();
    final productId = product.id;
    data.remove('id');
    data['items'] = product.items.map((i) => i.toJson()).toList();

    final url = Uri.parse('${AppData.apiUrl}/api/v1/admin/products/$productId');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Error del servidor: ${response.body}');
    }
  }

  // (El delete lo dejaremos por ahora directo a Supabase, o puedes migrarlo también)
  Future<void> deleteProduct(int productId) async {
    await _client.from('event_products').delete().eq('id', productId);
  }

  Future<List<ProductModel>> getAllProducts() async {
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) return []; // Si no hay sesión, devolvemos vacío

      // Llamamos a la ruta protegida que trae los productos de ESA ciudad
      final url = Uri.parse('${AppData.apiUrl}/api/v1/admin/products');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> data = jsonResponse['data'];
        return data.map((e) => ProductModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      Logger.error(
        'Error cargando todos los productos: $e',
        'PRODUCT_REPOSITORY',
      );
      return [];
    }
  }
}

@riverpod
ProductRepository productRepository(ProductRepositoryRef ref) {
  return ProductRepository(Supabase.instance.client);
}
