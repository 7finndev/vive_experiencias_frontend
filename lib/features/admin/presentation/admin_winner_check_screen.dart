import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vive_core/core/utils/logger_service.dart';

// Importamos el modelo de evento para tipado fuerte
import 'package:vive_core/features/home/data/models/event_model.dart';

class AdminWinnerCheckScreen extends StatefulWidget {
  const AdminWinnerCheckScreen({super.key});

  @override
  State<AdminWinnerCheckScreen> createState() => _AdminWinnerCheckScreenState();
}

class _AdminWinnerCheckScreenState extends State<AdminWinnerCheckScreen> {
  final _userIdController = TextEditingController();
  final _minVotesController = TextEditingController(text: "10"); // Valor por defecto

  // ESTADO
  bool _isLoading = false;
  List<EventModel> _events = [];
  EventModel? _selectedEvent;
  
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _minVotesController.dispose();
    super.dispose();
  }

  // 1. CARGAR LISTA DE EVENTOS
  Future<void> _loadEvents() async {
    try {
      // Pedimos todos los eventos (o solo los activos)
      final response = await Supabase.instance.client
          .from('events')
          .select()
          .order('start_date', ascending: false); // Los más recientes primero

      final List<EventModel> loaded = (response as List)
          .map((e) => EventModel.fromJson(e))
          .toList();

      setState(() {
        _events = loaded;
        // Seleccionamos el primero por defecto si existe (normalmente el activo)
        if (loaded.isNotEmpty) {
          _selectedEvent = loaded.first;
        }
      });
    } catch (e) {
      setState(() => _error = "Error cargando eventos: $e");
    }
  }

  // 2. ESCANEAR QR
  Future<void> _scanQR() async {
    final String? scannedCode = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const _SimpleScannerPage(),
      ),
    );

    if (scannedCode != null && scannedCode.isNotEmpty) {
      setState(() {
        _userIdController.text = scannedCode;
      });
      // Opcional: Lanzar comprobación automática al escanear
      // _checkWinner(); 
    }
  }

  // 3. LÓGICA DE COMPROBACIÓN
  Future<void> _checkWinner() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      setState(() => _error = "Introduce un ID de usuario");
      return;
    }
    if (_selectedEvent == null) {
      setState(() => _error = "Selecciona un evento primero");
      return;
    }

    setState(() { _isLoading = true; _result = null; _error = null; });

    try {
      final int minVotes = int.tryParse(_minVotesController.text) ?? 10;
      final int eventId = _selectedEvent!.id;

      // CONSULTA A SUPABASE
      // "Cuenta los sellos de ESTE usuario en ESTE evento"
      final countResponse = await Supabase.instance.client
          .from('passport_entries')
          .select('*') 
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .count(CountOption.exact); 

      final int totalVotes = countResponse.count;

      // DATOS DEL USUARIO (Nombre y Email)
      final userProfile = await Supabase.instance.client
          .from('profiles')
          .select('full_name, email, phone')
          .eq('id', userId)
          .maybeSingle();

      setState(() {
        _result = {
          'votes': totalVotes,
          'required': minVotes,
          'isWinner': totalVotes >= minVotes,
          'name': userProfile?['full_name'] ?? 'Usuario Desconocido',
          'email': userProfile?['email'] ?? 'Sin email',
          'phone': userProfile?['phone'] ?? 'Sin teléfono',
          'eventName': _selectedEvent!.name,
        };
      });

    } catch (e) {
      setState(() => _error = "Error al comprobar (¿ID válido?): $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Validar Ganador")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECCIÓN 1: CONFIGURACIÓN ---
            const Text("1. Configuración del Sorteo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 10),
            
            // SELECTOR DE EVENTO
            DropdownButtonFormField<EventModel>(
              isExpanded: true,
              initialValue: _selectedEvent,
              decoration: const InputDecoration(
                labelText: "Selecciona el Evento",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.event),
              ),
              items: _events.map((event) {
                // Indicador visual si el evento está activo
                final bool isActive = event.status == 'active';
                return DropdownMenuItem(
                  value: event,
                  child: Text(
                    event.name + (isActive ? " (Activo)" : ""),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: isActive ? Colors.black : Colors.grey,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedEvent = val),
            ),
            const SizedBox(height: 15),

            // MINIMO DE VOTOS
            TextField(
              controller: _minVotesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Mínimo de Sellos requeridos",
                helperText: "Ej: 10 tapas para completar el pasaporte",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
            ),
            
            const Divider(height: 40, thickness: 2),

            // --- SECCIÓN 2: IDENTIFICACIÓN USUARIO ---
            const Text("2. Identificar Participante", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 10),
            
            TextField(
              controller: _userIdController,
              decoration: InputDecoration(
                labelText: "UUID del Usuario",
                hintText: "Escanea el QR del móvil del usuario",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.blue, size: 30),
                  tooltip: "Abrir cámara",
                  onPressed: _scanQR, 
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _checkWinner,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  foregroundColor: Colors.white,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("VERIFICAR REQUISITOS", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 30),

            // --- SECCIÓN 3: RESULTADOS ---
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(10),
                width: double.infinity,
                color: Colors.red[50],
                child: Text(_error!, style: TextStyle(color: Colors.red[900]), textAlign: TextAlign.center),
              ),

            if (_result != null)
              _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final bool isWinner = _result!['isWinner'];
    final int votes = _result!['votes'];
    final int required = _result!['required'];

    return Card(
      elevation: 4,
      color: isWinner ? Colors.green[50] : Colors.red[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isWinner ? Colors.green : Colors.red, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              isWinner ? Icons.check_circle : Icons.cancel,
              size: 80,
              color: isWinner ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 10),
            Text(
              isWinner ? "¡CUMPLE REQUISITOS!" : "NO CUMPLE",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold,
                color: isWinner ? Colors.green[800] : Colors.red[800],
              ),
            ),
            Text(
              "Evento: ${_result!['eventName']}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Divider(height: 30),
            _InfoRow(icon: Icons.person, label: "Nombre", value: _result!['name']),
            _InfoRow(icon: Icons.email, label: "Email", value: _result!['email']),
            _InfoRow(icon: Icons.phone, label: "Teléfono", value: _result!['phone']),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("$votes", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: isWinner ? Colors.green : Colors.red)),
                Text(" / $required sellos", style: const TextStyle(fontSize: 20, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final String label; final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

// 🔥 WIDGET ESCÁNER CORREGIDO (COMPATIBLE CON NUEVAS VERSIONES)
class _SimpleScannerPage extends StatefulWidget {
  const _SimpleScannerPage();

  @override
  State<_SimpleScannerPage> createState() => _SimpleScannerPageState();
}

class _SimpleScannerPageState extends State<_SimpleScannerPage> {
  final MobileScannerController _cameraController = MobileScannerController();
  
  // Variable local para saber si hemos encendido el flash nosotros
  bool _isFlashOn = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Escanear QR Usuario"),
        backgroundColor: Colors.black, 
        foregroundColor: Colors.white,
        actions: [
          // 💡 BOTÓN DE FLASH (Controlado manualmente)
          IconButton(
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off, 
              color: _isFlashOn ? Colors.yellow : Colors.grey,
            ),
            tooltip: "Alternar Flash",
            onPressed: () async {
              try {
                // Mandamos la orden a la cámara
                await _cameraController.toggleTorch();
                // Cambiamos el icono
                setState(() {
                  _isFlashOn = !_isFlashOn;
                });
              } catch (e) {
                // Por si el dispositivo no tiene flash (ej. algunas tablets o Web)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Flash no disponible en este dispositivo")),
                );
              }
            },
          ),
          
          // 🔄 BOTÓN DE CAMBIAR CÁMARA
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white),
            tooltip: "Cambiar Cámara",
            onPressed: () {
              try {
                 _cameraController.switchCamera();
              } catch (e) {
                 Logger.error("Error cambiando cámara: $e", "ADMIN_WINNER_CHECK_SCREEN");
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  Navigator.pop(context, barcode.rawValue);
                  break; 
                }
              }
            },
          ),
          
          Container(
            decoration: ShapeDecoration(
              shape: _ScannerOverlayShape(
                borderColor: Colors.blue, 
                borderRadius: 10, 
                borderLength: 30, 
                borderWidth: 10, 
                cutOutSize: 300
              ),
            ),
          ),
          
          Positioned(
            bottom: 80, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: Colors.black54,
              child: const Text(
                "Encuadra el QR del usuario", 
                textAlign: TextAlign.center, 
                style: TextStyle(color: Colors.white, fontSize: 16)
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// 🎨 CLASE DE DIBUJO DEL MARCO (La misma de antes)
class _ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const _ScannerOverlayShape({
    this.borderColor = Colors.blue,
    this.borderWidth = 10.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 10,
    this.borderLength = 40,
    this.cutOutSize = 300,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path()..fillType = PathFillType.evenOdd..addPath(getOuterPath(rect), Offset.zero);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) => Path()..moveTo(rect.left, rect.bottom)..lineTo(rect.left, rect.top)..lineTo(rect.right, rect.top);
    return getLeftTopPath(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final double cutOutWidth = cutOutSize < width ? cutOutSize : width - borderOffset;
    final double cutOutHeight = cutOutSize < height ? cutOutSize : height - borderOffset;

    final backgroundPaint = Paint()..color = overlayColor..style = PaintingStyle.fill;
    final borderPaint = Paint()..color = borderColor..style = PaintingStyle.stroke..strokeWidth = borderWidth;
    
    final cutOutRect = Rect.fromLTWH(rect.left + width / 2 - cutOutWidth / 2 + borderOffset, rect.top + height / 2 - cutOutHeight / 2 + borderOffset, cutOutWidth - borderOffset * 2, cutOutHeight - borderOffset * 2);

    canvas..saveLayer(rect, backgroundPaint)..drawRect(rect, backgroundPaint)..drawRRect(RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)), Paint()..blendMode = BlendMode.clear)..restore();
    canvas.drawRRect(RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)), borderPaint);
  }

  @override
  ShapeBorder scale(double t) => _ScannerOverlayShape(borderColor: borderColor, borderWidth: borderWidth, overlayColor: overlayColor);
}