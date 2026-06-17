import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vive_core/core/utils/logger_service.dart';

class GeocodingHelper {
  /// Devuelve [lat, lng] o null si falla
  static Future<List<double>?> getCoordinatesFromAddress(String address) async {
    try {
      // Añadimos ", Torre del Mar, España" para mejorar la precisión
      // si el usuario solo escribe la calle.
      final query = "$address, Torre del Mar, Málaga, España";
      
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1'
      );

      // Nominatim requiere un User-Agent (normas de uso)
      final response = await http.get(url, headers: {
        'User-Agent': 'TorreDelMarApp/1.0 (com.tuempresa.app)'
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          return [lat, lon];
        }
      }
    } catch (e) {
      Logger.error("Error geocoding: $e", "GEOCODING_HELPER");
    }
    return null;
  }
// Obtener dirección desde coordenadas (Reverse Geocoding)
  static Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1');
      
      final response = await http.get(url, headers: {
        'User-Agent': 'TorreDelMarApp/1.1.3 (es.sietefinn.appvivetorredelmar)',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        final address = data['address'];
        if (address != null) {
          // Intentamos construir una dirección legible
          // OpenStreetMap devuelve las partes por separado (calle, número, barrio...)
          String road = address['road'] ?? address['pedestrian'] ?? address['footway'] ?? '';
          String number = address['house_number'] ?? '';
          
          if (road.isEmpty) return null; // Si no hay calle, no devolvemos nada raro

          String result = road;
          if (number.isNotEmpty) result += ", $number";
          
          return result;
        }
      }
    } catch (e) {
      Logger.error("Error Reverse Geocoding: $e", "GEOCODING_HELPER");
    }
    return null;
  }
}