import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vive_core/core/utils/image_helper.dart';
import 'package:vive_core/core/utils/logger_service.dart';
import 'package:vive_core/features/home/data/repositories/establishment_repository.dart';
import 'package:vive_core/features/home/data/repositories/product_repository.dart';
import 'package:vive_core/features/home/data/models/product_model.dart';
import 'package:vive_core/features/home/data/models/establishment_model.dart';
import 'package:vive_core/features/admin/presentation/controllers/product_form_controller.dart';
import 'package:vive_core/features/home/presentation/providers/home_providers.dart'
    hide establishmentRepositoryProvider;
import 'package:uuid/uuid.dart';

// Lista constante de alérgenos
const List<String> _commonAllergens = [
  'Gluten',
  'Lácteos',
  'Huevo',
  'Frutos Secos',
  'Marisco',
  'Pescado',
  'Soja',
  'Apio',
  'Mostaza',
  'Sulfitos',
  'Altramuces',
  'Moluscos',
  'Otros',
];

final establishmentsListProvider =
    FutureProvider.autoDispose<List<EstablishmentModel>>((ref) async {
      return ref.read(establishmentRepositoryProvider).getAllEstablishments();
    });

class ProductFormScreen extends ConsumerStatefulWidget {
  final int initialEventId;
  final ProductModel? productToEdit;

  const ProductFormScreen({
    super.key,
    required this.initialEventId,
    this.productToEdit,
  });

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  Uint8List? _newImageBytes;

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _priceController = TextEditingController(text: '0.0');
  final _imageUrlController = TextEditingController();

  // 🔥 1. AQUÍ ESTABA EL ERROR: FALTABA DECLARAR ESTA VARIABLE
  bool _hasInitializedPrice = false;
  // ---------------------------------------------------------

  bool _useImageUpload = true;
  int? _selectedEstablishmentId;

  // Estado de los switches y alérgenos
  bool _isAvailable = true;
  bool _isWinner = false;
  List<String> _selectedAllergens = [];

  @override
  void initState() {
    super.initState();
    // CARGA DE DATOS BÁSICOS SI ES EDICIÓN
    if (widget.productToEdit != null) {
      final p = widget.productToEdit!;
      _nameController.text = p.name;
      _descController.text = p.description ?? '';
      _ingredientsController.text = p.ingredients ?? '';
      _priceController.text = p.price?.toString() ?? '0.0';
      _imageUrlController.text = p.imageUrl ?? '';
      _selectedEstablishmentId = p.establishmentId;

      _isAvailable = p.isAvailable;
      _isWinner = p.isWinner;
      _selectedAllergens = List.from(p.allergens ?? []);

      if (p.items.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(productFormControllerProvider.notifier)
              .loadInitialItems(p.items);
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _ingredientsController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final establishmentsAsync = ref.watch(establishmentsListProvider);
    final formState = ref.watch(productFormControllerProvider);

    // Obtenemos el evento para saber el tipo (menú/tapa) y AHORA EL PRECIO BASE
    final eventAsync = ref.watch(eventDetailsProvider(widget.initialEventId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.productToEdit != null ? 'Editar Producto' : 'Nuevo Producto',
        ),
      ),
      body: eventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error cargando evento: $e")),
        data: (event) {
          // 🔥 2. LÓGICA CORREGIDA DE PRECIO AUTOMÁTICO 🔥
          // Si es un producto NUEVO y aún no hemos puesto el precio automático
          if (widget.productToEdit == null && !_hasInitializedPrice) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Usamos .basePrice porque así se llama en tu modelo EventModel
              if (event.basePrice != null) {
                setState(() {
                  _priceController.text = event.basePrice.toString();
                  _hasInitializedPrice =
                      true; // Marcamos como hecho para que no se repita
                });
                Logger.info("✅ Precio automático aplicado: ${event.basePrice}€", "PRODUCT_FORM_SCREEN");
              }
            });
          }
          // ------------------------------------------------

          final bool showMenuBuilder =
              event.type == 'menu' || formState.items.isNotEmpty;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  if (formState.isLoading) const LinearProgressIndicator(),
                  const SizedBox(height: 20),

                  // SELECTOR DE ESTABLECIMIENTO
                  establishmentsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => const Text('Error cargando locales'),
                    data: (establishments) {
                      return DropdownSearch<EstablishmentModel>(
                        items: (filter, loadProps) {
                          if (filter.isEmpty) return establishments;
                          return establishments
                              .where(
                                (element) => element.name
                                    .toLowerCase()
                                    .contains(filter.toLowerCase()),
                              )
                              .toList();
                        },
                        compareFn: (item1, item2) => item1.id == item2.id,
                        itemAsString: (EstablishmentModel u) => u.name,
                        decoratorProps: const DropDownDecoratorProps(
                          decoration: InputDecoration(
                            labelText: "Establecimiento / Local",
                            hintText: "Seleccione un local",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.store),
                          ),
                        ),
                        popupProps: const PopupProps.menu(
                          showSearchBox: true,
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              hintText: "Buscar...",
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                            ),
                          ),
                        ),
                        onChanged: (EstablishmentModel? data) {
                          if (data != null) {
                            setState(() => _selectedEstablishmentId = data.id);
                          }
                        },
                        selectedItem: _selectedEstablishmentId != null
                            ? establishments.firstWhere(
                                (e) => e.id == _selectedEstablishmentId,
                                orElse: () => establishments.first,
                              )
                            : null,
                        validator: (item) {
                          if (_selectedEstablishmentId == null && item == null) {
                            return "Requerido";
                          }
                          return null;
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // DATOS BÁSICOS
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre Producto / Menú',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.fastfood),
                    ),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),

                  // PRECIO
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Precio (€)',
                      border: OutlineInputBorder(),
                      suffixText: '€',
                      prefixIcon: Icon(Icons.euro),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- SECCIÓN IMAGEN ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Foto Principal',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Text(
                            _useImageUpload ? "Archivo" : "URL",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          Switch(
                            value: _useImageUpload,
                            activeThumbColor: Colors.black,
                            onChanged: (val) =>
                                setState(() => _useImageUpload = val),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_useImageUpload)
                    /*
                    ImagePickerWidget(
                      bucketName: 'products',
                      initialUrl: _imageUrlController.text.isNotEmpty ? _imageUrlController.text : null,
                      onImageUploaded: (url) {
                        setState(() => _imageUrlController.text = url);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Imagen lista")));
                      },
                    )
                  */
                    Column(
                      children: [
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _newImageBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(
                                    _newImageBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : (_imageUrlController.text.isNotEmpty
                                    ? Image.network(
                                        _imageUrlController.text,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(
                                        Icons.image,
                                        size: 50,
                                        color: Colors.grey,
                                      )),
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.upload),
                          label: const Text("Seleccionar Foto"),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "💡 Recomendado: Formato cuadrado (800x800 px). La app la optimizará automáticamente.",
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  else
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: "Pegar URL",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                      ),
                      onChanged: (val) => setState(() {}),
                    ),

                  const SizedBox(height: 24),

                  // SECCIÓN MENÚ
                  if (showMenuBuilder) ...[
                    const Divider(thickness: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "PLATOS DEL MENÚ",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showAddDishDialog(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text("Añadir Plato"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    // Sacamos el texto fuera del Row para que se coloque debajo
                    const SizedBox(height: 8),
                    const Text(
                      "💡 Recomendado: Formato cuadrado (800x800 px). Se optimizará a Calidad 75%.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 10),

                    if (formState.items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.orange.shade50,
                        child: const Text(
                          "Menú vacío. Añade entrantes, principales, etc.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.orange),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: formState.items.length,
                        itemBuilder: (context, index) {
                          final item = formState.items[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getColorForCourse(
                                  item.courseType,
                                ),
                                child: Icon(
                                  _getIconForCourse(item.courseType),
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              title: Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(item.courseType.toUpperCase()),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  ref
                                      .read(
                                        productFormControllerProvider.notifier,
                                      )
                                      .removeMenuCourse(index);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    const Divider(thickness: 2),
                    const SizedBox(height: 20),
                  ],

                  // Descripción e Ingredientes
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.description),
                      ),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _ingredientsController,
                    decoration: const InputDecoration(
                      labelText: 'Ingredientes',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.list),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Alérgenos
                  const Text(
                    'Alérgenos',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    children: _commonAllergens.map((allergen) {
                      final isSelected = _selectedAllergens.contains(allergen);
                      return FilterChip(
                        label: Text(allergen),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _selectedAllergens.add(allergen);
                            } else {
                              _selectedAllergens.remove(allergen);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Estados
                  SwitchListTile(
                    title: const Text('Disponible'),
                    value: _isAvailable,
                    onChanged: (val) => setState(() => _isAvailable = val),
                  ),
                  SwitchListTile(
                    title: const Text('🏆 Marcar como Ganador'),
                    value: _isWinner,
                    onChanged: (val) => setState(() => _isWinner = val),
                  ),

                  const SizedBox(height: 32),

                  // BOTÓN GUARDAR
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: Text(
                        formState.isLoading
                            ? 'GUARDANDO...'
                            : 'GUARDAR PRODUCTO',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: formState.isLoading
                          ? null
                          : () => _saveProduct(context),
                    ),
                  ),

                  if (formState.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        "Error: ${formState.error}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  //Función nueva:
  Future<void> _pickImage() async {
    final bytes = await ImageHelper.pickAndCompress(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      quality: 75,
    );
    if (bytes != null) {
      setState(() {
        _newImageBytes = bytes;
        _useImageUpload = true;
      });
    }
  }

  Future<void> _saveProduct(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedEstablishmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Falta seleccionar el establecimiento'),
        ),
      );
      return;
    }

    final price = double.tryParse(_priceController.text) ?? 0.0;
    final allergensString = _selectedAllergens.join(', ');

    String currentUrl = _imageUrlController.text;

    if (_useImageUpload && _newImageBytes != null) {
      //1.-Borrar antigua si existe
      if (widget.productToEdit != null &&
          widget.productToEdit!.imageUrl!.isNotEmpty) {
        await ref
            .read(productRepositoryProvider)
            .deleteProductImage(widget.productToEdit!.imageUrl!);
      }

      //2.-Subir nueva
      final fileName = 'tapa_${const Uuid().v4()}.jpg';
      currentUrl = await ref
          .read(productRepositoryProvider)
          .uploadProductImage(fileName, _newImageBytes!);
    }

    await ref
        .read(productFormControllerProvider.notifier)
        .saveProduct(
          id: widget.productToEdit?.id,
          name: _nameController.text,
          description: _descController.text,
          price: price,
          establishmentId: _selectedEstablishmentId!,
          eventId: widget.initialEventId,
          //newImage: null,
          //currentImageUrl: currentUrl,//_imageUrlController.text,
          finalImageUrl: currentUrl,
          ingredients: _ingredientsController.text,
          allergens: allergensString,
        );

    if (mounted) {
      final state = ref.read(productFormControllerProvider);
      if (state.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Producto guardado correctamente"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  void _showAddDishDialog(BuildContext context) {
    String name = '';
    String description = '';

    final currentItems = ref.read(productFormControllerProvider).items;
    final usedTypes = currentItems.map((e) => e.courseType).toList();

    final allTypes = {
      'entrante': 'Entrante',
      'principal': 'Plato Principal',
      'postre': 'Postre',
      'bebida': 'Bebida',
    };

    final availableTypes = allTypes.entries
        .where((entry) => !usedTypes.contains(entry.key))
        .toList();

    if (availableTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("¡El menú ya está completo!")),
      );
      return;
    }

    String courseType = availableTypes.first.key;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Añadir Plato al Menú"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: courseType,
                items: availableTypes.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (v) => courseType = v!,
                decoration: const InputDecoration(labelText: "Tipo"),
              ),
              const SizedBox(height: 10),

              TextField(
                decoration: const InputDecoration(
                  labelText: "Nombre del plato",
                ),
                onChanged: (v) => name = v,
                autofocus: true,
              ),
              const SizedBox(height: 10),

              TextField(
                decoration: const InputDecoration(
                  labelText: "Descripción (opcional)",
                  hintText: "Ej: Con salsa de almendras",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                minLines: 3,
                onChanged: (v) => description = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              if (name.isNotEmpty) {
                ref
                    .read(productFormControllerProvider.notifier)
                    .addMenuCourse(
                      name: name,
                      courseType: courseType,
                      description: description,
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text("Añadir"),
          ),
        ],
      ),
    );
  }

  Color _getColorForCourse(String type) {
    switch (type) {
      case 'entrante':
        return Colors.green;
      case 'principal':
        return Colors.orange;
      case 'postre':
        return Colors.pink;
      case 'bebida':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForCourse(String type) {
    switch (type) {
      case 'entrante':
        return Icons.soup_kitchen;
      case 'principal':
        return Icons.restaurant;
      case 'postre':
        return Icons.icecream;
      case 'bebida':
        return Icons.local_bar;
      default:
        return Icons.fastfood;
    }
  }
}
