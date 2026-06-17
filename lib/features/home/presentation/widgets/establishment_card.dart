import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vive_core/features/home/data/models/establishment_model.dart';
import 'package:vive_core/core/utils/smart_image_container.dart';

class EstablishmentCard extends StatelessWidget {
  final EstablishmentModel establishment;

  const EstablishmentCard({super.key, required this.establishment});

  @override
  Widget build(BuildContext context) {
    // 1. DETECTAR SI ESTÁ CERRADO
    final bool isClosed = !establishment.isActive;

    return GestureDetector(
      onTap: () => context.push('/detail', extra: establishment),
      child: Container(
        decoration: BoxDecoration(
          color: isClosed ? Colors.grey[100] : Colors.white, // Fondo más oscuro si cerrado
          borderRadius: BorderRadius.circular(16),
          boxShadow: isClosed 
              ? [] // Sin sombra si cerrado (efecto plano)
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // 1. IMAGEN (IZQUIERDA)
            SizedBox(
              width: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // IMAGEN CON FILTRO B/N SI ESTÁ CERRADO
                  ColorFiltered(
                    colorFilter: isClosed
                        ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                        : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                    child: SmartImageContainer(
                      imageUrl: establishment.coverImage,
                      borderRadius: 0,
                    ),
                  ),
                  
                  // SOMBRA INTERIOR
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [Colors.black.withValues(alpha: 0.1), Colors.transparent],
                      ),
                    ),
                  ),

                  // ETIQUETA "CERRADO" SOBRE LA FOTO
                  if (isClosed)
                    Container(
                      color: Colors.black.withValues(alpha: 0.6),
                      child: const Center(
                        child: Text(
                          "CERRADO\nTEMPORALMENTE",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 10
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 2. INFORMACIÓN (DERECHA)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // A. TÍTULO
                    Text(
                      establishment.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        color: isClosed ? Colors.grey : Colors.black, // Texto gris si cerrado
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 6),

                    // B. UBICACIÓN
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: isClosed ? Colors.grey : Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            establishment.address ?? "Ver mapa",
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // C. HORARIO / ESTADO
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: isClosed ? Colors.grey : Colors.blue),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            isClosed ? "No disponible" : (establishment.schedule ?? "Consultar horario"),
                            style: TextStyle(
                              color: isClosed ? Colors.grey : Colors.blue,
                              fontSize: 11,
                              fontWeight: FontWeight.w500
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}