import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppData {
  // Patrocinadores estáticos del MVP
  static const List<Map<String, String>> sponsors = [
    {
      "name": "ACET",
      "logo": "https://www.torredelmar.org/wp-content/uploads/2024/03/Logo-ACET-Torre-del-Mar--e1711372971163.png",
      "url": "https://www.torredelmar.org/",
    },
    {
      "name": "Torre del Mar",
      "logo": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRp0ljDLY-gdLu9_6WU1DMblFD8frhjonWcGQ&s",
      "url": "https://velezmalaga.es/",
    },
    {
      "name": "Cervezas Victoria",
      "logo": "https://www.cervezavictoria.es/sites/default/files/2018-11/posavasos.jpg",
      "url": "https://www.cervezavictoria.es/",
    },
     {
      "name": "APTA Axarquía Costa del Sol",
      "logo": "https://www.axarquiacostadelsol.es/wp-content/uploads/2022/06/LogoLineaNegra.png",
      "url": "https://axarquiacostadelsol.es/",
    },
  ];

  // Distancia máxima para validar el QR (en metros):
  static const double maxQrDistance = 150.0;

  // 🔥 MAGIA DE LA MARCA BLANCA 🔥
  // Si falla el archivo .env, por defecto cargará la ciudad 1 (Torre del Mar)
  static int get cityId => int.tryParse(dotenv.env['CITY_ID'] ?? '1') ?? 1;
  
  // 🚀 URL DE PRODUCCIÓN BLINDADA 🚀
  // Si el .env no carga correctamente en el móvil, apuntará siempre a tu servidor Xeon
  static String get apiUrl => dotenv.env['API_URL'] ?? 'https://api.7finn.es';
}