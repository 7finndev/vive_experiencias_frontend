import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vive_core/features/home/data/models/product_model.dart';
import 'package:vive_core/features/home/data/models/product_item_model.dart';
import 'package:vive_core/features/home/data/repositories/product_repository.dart';

part 'product_form_controller.g.dart';

// Estado del formulario
class ProductFormState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  
  // Lista temporal de platos para el menú
  final List<ProductItemModel> items; 

  ProductFormState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.items = const [],
  });

  ProductFormState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    List<ProductItemModel>? items,
  }) {
    return ProductFormState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // Si no se pasa, se limpia el error (null)
      isSuccess: isSuccess ?? this.isSuccess,
      items: items ?? this.items,
    );
  }
}

@riverpod
class ProductFormController extends _$ProductFormController {
  @override
  ProductFormState build() {
    return ProductFormState();
  }

  // --- GESTIÓN DE ITEMS DEL MENÚ ---
  
  // Cargar items iniciales (al editar un producto existente)
  void loadInitialItems(List<ProductItemModel> existingItems) {
    state = state.copyWith(items: existingItems);
  }

  // Añadir un plato a la lista temporal
  void addMenuCourse({
    required String name,
    required String courseType, // 'entrante', 'principal', etc.
    String? description,
  }) {
    final newItem = ProductItemModel(
      name: name,
      courseType: courseType,
      description: description,
      displayOrder: state.items.length, // Lo ponemos al final
    );
    
    // Añadimos a la lista actual
    state = state.copyWith(items: [...state.items, newItem]);
  }

  // Borrar un plato de la lista temporal
  void removeMenuCourse(int index) {
    final updatedList = List<ProductItemModel>.from(state.items);
    updatedList.removeAt(index);
    state = state.copyWith(items: updatedList);
  }

  // --- GUARDADO FINAL ---

  Future<void> saveProduct({
    required int? id, // Si es null, es CREAR. Si tiene valor, es EDITAR.
    required String name,
    required String description,
    required double price,
    required int establishmentId,
    required int eventId,
    required String? finalImageUrl,
    String? allergens, // "Gluten, Huevo"
    String? ingredients,
  }) async {
    state = state.copyWith(isLoading: true, isSuccess: false);

    try {
      final repository = ref.read(productRepositoryProvider);
      
      /*
      String? finalImageUrl = currentImageUrl;

      // 1. Subir imagen si hay una nueva
      if (newImage != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final imageBytes = await newImage.readAsBytes();
        finalImageUrl = await repository.uploadProductImage(fileName, imageBytes);
      }
      */
      
      // 2. Preparar listas (Alergenos)
      List<String>? allergensList;
      if (allergens != null && allergens.isNotEmpty) {
        allergensList = allergens.split(',').map((e) => e.trim()).toList();
      }

      // 3. Crear el Objeto Modelo
      final product = ProductModel(
        id: id ?? 0, // 0 si es nuevo (se ignora en create)
        name: name,
        description: description,
        price: price,
        imageUrl: finalImageUrl,
        establishmentId: establishmentId,
        eventId: eventId,
        ingredients: ingredients,
        allergens: allergensList,
        // AQUÍ METEMOS LA LISTA DE PLATOS DEL ESTADO
        items: state.items, 
      );

      // 4. Llamar al Repo
      if (id == null) {
        await repository.createProduct(product);
      } else {
        await repository.updateProduct(product);
      }

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}