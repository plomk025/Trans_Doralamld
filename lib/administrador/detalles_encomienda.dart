import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetalleEncomiendaScreen extends StatefulWidget {
  final String codigo;
  final Map<String, dynamic> data;
  final String estado;

  const DetalleEncomiendaScreen({
    super.key,
    required this.codigo,
    required this.data,
    required this.estado,
  });

  @override
  State<DetalleEncomiendaScreen> createState() =>
      _DetalleEncomiendaScreenState();
}

class _DetalleEncomiendaScreenState extends State<DetalleEncomiendaScreen> {
  static const Color darkGray = Color(0xFF2D3748);
  static const Color lightGray = Color(0xFFF7FAFC);
  static const Color mediumGray = Color(0xFF718096);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningRed = Color(0xFFEF4444);
  static const Color accentOrange = Color(0xFFF59E0B);

  final TextEditingController _precioTipoController = TextEditingController();
  final TextEditingController _pesoController =
      TextEditingController(); // ✅ NUEVO
  XFile? _imagenTransito;
  XFile? _imagenEntregada;
  String? _busSeleccionado;
  List<Map<String, dynamic>> _busesDisponibles = [];
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() {
    final costos = widget.data['costos'] ?? {};
    final envio = widget.data['envio'] ?? {};

    _precioTipoController.text = (costos['precio_tipo'] ?? 0).toString();
    _pesoController.text = envio['rango_peso'] ?? ''; // ✅ Cargar peso existente

    _cargarBuses();
  }

// ✅ MÉTODO AUXILIAR: Normalizar texto para comparación

  Future<void> _cargarBuses() async {
    print('🔍 ====== INICIANDO CARGA DE BUSES ======');
    print('📦 Cargando TODOS los buses de ambas colecciones...');

    try {
      List<Map<String, dynamic>> buses = [];

      // 🔵 CARGAR TODOS LOS BUSES DE COLECCIÓN "buses" (Tulcán)
      print('\n🔵 Cargando colección "buses"...');
      final busesSnapshot = await FirebaseFirestore.instance
          .collection('buses_tulcan_salida')
          .get();

      print('📊 Total en "buses": ${busesSnapshot.docs.length}');

      for (var doc in busesSnapshot.docs) {
        final data = doc.data();

        print('  🚌 Bus agregado:');
        print('     - ID: ${doc.id}');
        print('     - Número: ${data['numero']}');
        print('     - Lugar salida: ${data['lugar_salida']}');
        print('     - Hora: ${data['hora_salida']}');

        buses.add({
          'id': doc.id,
          'coleccion': 'buses_tulcan_salida',
          'numero': data['numero']?.toString() ?? 'S/N',
          'lugar_salida': data['lugar_salida']?.toString() ?? '',
          'fecha_salida': data['fecha_salida'],
          'hora_salida': data['hora_salida']?.toString() ?? '',
          'ruta': data['ruta']?.toString() ?? '',
        });
      }

      // 🟢 CARGAR TODOS LOS BUSES DE COLECCIÓN "buses1" (Otros lugares)
      print('\n🟢 Cargando colección "buses_la_esperanza_salida"...');
      final buses1Snapshot = await FirebaseFirestore.instance
          .collection('buses_la_esperanza_salida')
          .get();

      print(
          '📊 Total en "buses_la_esperanza_salida": ${buses1Snapshot.docs.length}');

      for (var doc in buses1Snapshot.docs) {
        final data = doc.data();

        print('  🚌 Bus agregado:');
        print('     - ID: ${doc.id}');
        print('     - Número: ${data['numero']}');
        print('     - Lugar salida: ${data['lugar_salida']}');
        print('     - Hora: ${data['hora_salida']}');

        buses.add({
          'id': doc.id,
          'coleccion': 'buses_la_esperanza_salida',
          'numero': data['numero']?.toString() ?? 'S/N',
          'lugar_salida': data['lugar_salida']?.toString() ?? '',
          'fecha_salida': data['fecha_salida'],
          'hora_salida': data['hora_salida']?.toString() ?? '',
          'ruta': data['ruta']?.toString() ?? '',
        });
      }

      setState(() {
        _busesDisponibles = buses;
      });

      print('\n✅ ====== RESUMEN ======');
      print('Total buses cargados: ${_busesDisponibles.length}');
      print('\n📋 Buses disponibles:');

      // Agrupar por lugar de salida
      Map<String, int> porLugar = {};
      for (var bus in _busesDisponibles) {
        final lugar = bus['lugar_salida'] ?? 'Sin lugar';
        porLugar[lugar] = (porLugar[lugar] ?? 0) + 1;
        print(
            '  - Bus ${bus['numero']} | ${bus['lugar_salida']} | ${bus['hora_salida']} (${bus['coleccion']})');
      }

      print('\n📊 Resumen por lugar de salida:');
      porLugar.forEach((lugar, cantidad) {
        print('  - $lugar: $cantidad bus(es)');
      });
    } catch (e, stackTrace) {
      print('\n❌ ERROR AL CARGAR BUSES: $e');
      print('Stack trace: $stackTrace');
      _mostrarError('Error al cargar buses: $e');
      setState(() {
        _busesDisponibles = [];
      });
    }
  }

  Future<void> _seleccionarImagen(bool esTransito) async {
    try {
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                esTransito ? 'Foto en Tránsito' : 'Foto de Entrega',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: darkGray,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: accentBlue),
                title: const Text('Cámara'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: successGreen),
                title: const Text('Galería'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        final imagen = await _picker.pickImage(
          source: source,
          imageQuality: 80,
          maxWidth: 1024,
        );

        if (imagen != null) {
          setState(() {
            if (esTransito) {
              _imagenTransito = imagen;
            } else {
              _imagenEntregada = imagen;
            }
          });
        }
      }
    } catch (e) {
      _mostrarError('Error al seleccionar imagen: $e');
    }
  }

  Future<String?> _subirImagenConOffline(XFile imagen, String campo) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final rutaStorage =
        'encomiendas/${widget.codigo}/$campo-${DateTime.now().millisecondsSinceEpoch}.jpg';

    if (connectivityResult == ConnectivityResult.none) {
      final prefs = await SharedPreferences.getInstance();
      final pendientes = prefs.getStringList('imagenes_pendientes') ?? [];

      final imagenPendiente = json.encode({
        'ruta_local': imagen.path,
        'ruta_storage': rutaStorage,
        'codigo_envio': widget.codigo,
        'campo': 'imagenes.$campo',
      });

      pendientes.add(imagenPendiente);
      await prefs.setStringList('imagenes_pendientes', pendientes);

      return 'offline://${imagen.path}';
    } else {
      try {
        final ref = FirebaseStorage.instance.ref().child(rutaStorage);
        await ref.putFile(File(imagen.path));
        return await ref.getDownloadURL();
      } catch (e) {
        _mostrarError('Error al subir imagen: $e');
        return null;
      }
    }
  }

  Future<void> _actualizarEncomienda() async {
    // Validaciones según estado
    if (widget.estado == 'pendiente') {
      if (_precioTipoController.text.trim().isEmpty) {
        _mostrarError('Ingrese el precio del tipo de encomienda');
        return;
      }
      if (_pesoController.text.trim().isEmpty) {
        _mostrarError('Ingrese el peso del paquete');
        return;
      }
      if (_imagenTransito == null) {
        _mostrarError('Agregue la foto en tránsito');
        return;
      }
      if (_busSeleccionado == null) {
        _mostrarError('Seleccione un bus');
        return;
      }
    } else if (widget.estado == 'en_transito') {
      if (_imagenEntregada == null) {
        _mostrarError('Agregue la foto de entrega');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final updateData = <String, dynamic>{};
      String nuevoEstado = '';

      // ✅ Obtener UID del remitente
      final remitenteUid = widget.data['remitente']?['uid'];
      if (remitenteUid == null || remitenteUid.toString().isEmpty) {
        _mostrarError('No se encontró el UID del remitente');
        setState(() => _isLoading = false);
        return;
      }

      // Actualizar desde pendiente a en_transito
      if (widget.estado == 'pendiente') {
        final precioTipo = double.parse(_precioTipoController.text.trim());
        final peso = _pesoController.text.trim();

        // ✅ Subir imagen de tránsito (con soporte offline)
        String? urlTransito =
            await _subirImagenConOffline(_imagenTransito!, 'transito');

        updateData['costos.precio_tipo'] = precioTipo;
        updateData['costos.total'] = precioTipo;
        updateData['envio.rango_peso'] = peso;
        updateData['estado'] = 'en_transito';
        updateData['numero'] = _busesDisponibles
            .firstWhere((b) => b['id'] == _busSeleccionado)['numero'];
        updateData['hora_salida'] = DateTime.now();

        if (urlTransito != null && !urlTransito.startsWith('offline://')) {
          updateData['imagenes.transito'] = urlTransito;
        }

        nuevoEstado = 'en_transito';

        // Asignar a bus
        final busData = _busesDisponibles.firstWhere(
          (b) => b['id'] == _busSeleccionado,
        );

        await FirebaseFirestore.instance
            .collection(busData['coleccion'])
            .doc(_busSeleccionado)
            .set({
          'encomiendas': FieldValue.arrayUnion([widget.codigo])
        }, SetOptions(merge: true));
      }
      // Actualizar desde en_transito a entregado
      else if (widget.estado == 'en_transito') {
        // ✅ Verificar conectividad antes de subir
        final connectivityResult = await Connectivity().checkConnectivity();

        if (connectivityResult == ConnectivityResult.none) {
          // ✅ SIN INTERNET: Guardar imagen localmente
          final prefs = await SharedPreferences.getInstance();
          final pendientes = prefs.getStringList('imagenes_pendientes') ?? [];

          final rutaStorage =
              'encomiendas/${widget.codigo}/entregada-${DateTime.now().millisecondsSinceEpoch}.jpg';

          final imagenPendiente = json.encode({
            'ruta_local': _imagenEntregada!.path,
            'ruta_storage': rutaStorage,
            'codigo_envio': widget.codigo,
            'campo': 'imagenes.entregada',
            'uid_remitente':
                remitenteUid, // ✅ Guardar UID para notificación posterior
          });

          pendientes.add(imagenPendiente);
          await prefs.setStringList('imagenes_pendientes', pendientes);

          // ✅ Actualizar estado a entregado INMEDIATAMENTE (sin imagen)
          updateData['estado'] = 'entregado';
          updateData['fecha_entrega'] = DateTime.now();
          nuevoEstado = 'entregado';

          print(
              '📴 Sin internet: Imagen guardada localmente para subir después');
          print('✅ Proceso completado offline, se sincronizará al conectarse');
        } else {
          // ✅ CON INTERNET: Subir imagen normalmente
          String? urlEntregada =
              await _subirImagenConOffline(_imagenEntregada!, 'entregada');

          updateData['estado'] = 'entregado';
          updateData['fecha_entrega'] = DateTime.now();

          if (urlEntregada != null && !urlEntregada.startsWith('offline://')) {
            updateData['imagenes.entregada'] = urlEntregada;
          }

          nuevoEstado = 'entregado';
        }
      }

      // ✅ Actualizar Firestore
      await FirebaseFirestore.instance
          .collection('encomiendas_registradas')
          .doc(widget.codigo)
          .update(updateData);

      // ✅ CREAR NOTIFICACIÓN
      await _crearNotificacion(remitenteUid, nuevoEstado);

      _mostrarExito('Encomienda actualizada exitosamente');
      Navigator.pop(context);
    } catch (e, stackTrace) {
      print('❌ Error al actualizar: $e');
      print('Stack trace: $stackTrace');
      _mostrarError('Error al actualizar: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _crearNotificacion(
      String uidRemitente, String nuevoEstado) async {
    try {
      // ✅ Obtener correo del remitente
      final remitente = widget.data['remitente'] ?? {};
      final correoRemitente = remitente['correo'] ?? '';
      final nombreRemitente = remitente['nombre'] ?? '';

      // ✅ Textos según el estado
      String titulo = '';
      String mensaje = '';
      String accion = '';

      switch (nuevoEstado) {
        case 'en_transito':
          titulo = 'Encomienda en Tránsito 🚚';
          mensaje =
              'Tu encomienda ${widget.codigo} ha sido cargada en el bus y está en camino.';
          accion = 'transito';
          break;
        case 'entregado':
          titulo = 'Encomienda Entregada ✅';
          mensaje =
              'Tu encomienda ${widget.codigo} ha sido entregada exitosamente.';
          accion = 'entregado';
          break;
        default:
          titulo = 'Actualización de Encomienda';
          mensaje = 'El estado de tu encomienda ${widget.codigo} ha cambiado.';
          accion = 'actualizacion';
      }

      // ✅ Crear notificación en Firestore
      await FirebaseFirestore.instance.collection('notificaciones').add({
        'uid': uidRemitente,
        'correo': correoRemitente, // ✅ NUEVO
        'nombre_remitente': nombreRemitente, // ✅ NUEVO
        'titulo': titulo,
        'mensaje': mensaje,
        'codigo_encomienda': widget.codigo,
        'estado': nuevoEstado,
        'leida': false,
        'fecha': FieldValue.serverTimestamp(),
        'tipo': 'encomienda',
        'accion': accion, // ✅ NUEVO
      });

      print('✅ Notificación creada para usuario: $uidRemitente');
      print('📧 Correo: $correoRemitente');
    } catch (e) {
      print('❌ Error al crear notificación: $e');
      // No detenemos el proceso si falla la notificación
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: warningRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remitente = widget.data['remitente'] ?? {};
    final destinatario = widget.data['destinatario'] ?? {};
    final envio = widget.data['envio'] ?? {};
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.codigo,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: darkGray,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Información básica
            _buildInfoCard(
              'Información del Envío',
              Icons.info_outline,
              successGreen,
              [
                _buildInfoRow('Remitente', remitente['nombre'] ?? 'N/A'),
                _buildInfoRow('Origen', remitente['lugar_salida'] ?? 'N/A'),
                _buildInfoRow('Destinatario', destinatario['nombre'] ?? 'N/A'),
                _buildInfoRow('Destino', destinatario['ciudad'] ?? 'N/A'),
                _buildInfoRow('Tipo', envio['tipo_encomienda'] ?? 'N/A'),
                _buildInfoRow(
                    'Peso Actual', envio['rango_peso'] ?? 'No definido'),
              ],
            ),

            const SizedBox(height: 20),

            // Campos según estado
            if (widget.estado == 'pendiente') ...[
              _buildPrecioCard(),
              const SizedBox(height: 20),
              _buildPesoCard(), // ✅ NUEVO: Campo de peso
              const SizedBox(height: 20),
              _buildBusesCard(),
              const SizedBox(height: 20),
              _buildImagenCard(
                'Foto en Tránsito *',
                _imagenTransito,
                () => _seleccionarImagen(true),
                Icons.local_shipping,
                accentBlue,
              ),
            ] else if (widget.estado == 'en_transito') ...[
              _buildImagenCard(
                'Foto de Entrega *',
                _imagenEntregada,
                () => _seleccionarImagen(false),
                Icons.check_circle,
                successGreen,
              ),
            ],

            const SizedBox(height: 20),

            // Botón actualizar
            if (widget.estado != 'entregado')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _actualizarEncomienda,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                      _isLoading ? 'Actualizando...' : 'Actualizar Estado'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: successGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String titulo,
    IconData icono,
    Color color,
    List<Widget> children,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icono, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: darkGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: lightGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(children: children),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: mediumGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: darkGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrecioCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.attach_money,
                      color: accentOrange, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Precio de la encomienda',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: darkGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _precioTipoController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Precio  *',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.attach_money, color: accentOrange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: accentOrange, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NUEVO: Widget para ingresar peso manualmente
  Widget _buildPesoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.monitor_weight,
                      color: successGreen, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Peso de la encomienda',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: darkGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pesoController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: 'Peso *',
                hintText: ' 5 kg, 2.5 kg, 10 kg',
                prefixIcon:
                    const Icon(Icons.monitor_weight, color: successGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: successGreen, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusesCard() {
    // Agrupar buses por lugar de salida
    Map<String, List<Map<String, dynamic>>> busesPorLugar = {};
    for (var bus in _busesDisponibles) {
      final lugar = bus['lugar_salida']?.toString() ?? 'Sin lugar';
      if (!busesPorLugar.containsKey(lugar)) {
        busesPorLugar[lugar] = [];
      }
      busesPorLugar[lugar]!.add(bus);
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    color: accentBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Asignar a Bus',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: darkGray,
                        ),
                      ),
                      Text(
                        'Selecciona el bus de cualquier origen',
                        style: TextStyle(
                          fontSize: 12,
                          color: mediumGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ───────── INFO BUSES CARGADOS ─────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Buses disponibles: ${_busesDisponibles.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  if (busesPorLugar.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: busesPorLugar.entries.map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${entry.key}: ${entry.value.length}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ───────── DROPDOWN AGRUPADO ─────────
            if (_busesDisponibles.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: lightGray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: mediumGray.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _busSeleccionado,
                    isExpanded: true,
                    hint: const Text('Seleccionar bus'),
                    items: busesPorLugar.entries.expand((entry) {
                      final lugar = entry.key;
                      final busesDelLugar = entry.value;

                      return [
                        // Encabezado del grupo
                        DropdownMenuItem<String>(
                          enabled: false,
                          value: null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              '📍 $lugar',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: accentBlue,
                              ),
                            ),
                          ),
                        ),
                        // Buses del grupo
                        ...busesDelLugar.map((bus) {
                          String fechaTexto = 'Sin fecha';

                          if (bus['fecha_salida'] != null) {
                            try {
                              if (bus['fecha_salida'] is Timestamp) {
                                final fecha =
                                    (bus['fecha_salida'] as Timestamp).toDate();
                                fechaTexto =
                                    '${fecha.day}/${fecha.month}/${fecha.year}';
                              }
                            } catch (e) {
                              print('Error formateando fecha: $e');
                            }
                          }

                          return DropdownMenuItem<String>(
                            value: bus['id'] as String,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: bus['coleccion'] ==
                                                  'buses_tulcan_salida'
                                              ? Colors.blue.shade100
                                              : Colors.green.shade100,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          bus['coleccion'] ==
                                                  'buses_tulcan_salida'
                                              ? 'Tulcán'
                                              : 'Otros',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: bus['coleccion'] ==
                                                    'buses_tulcan_salida'
                                                ? Colors.blue.shade900
                                                : Colors.green.shade900,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Bus ${bus['numero']}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$fechaTexto | ${bus['hora_salida']} | ${bus['ruta'] ?? 'Sin ruta'}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: mediumGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ];
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _busSeleccionado = value);
                      if (value != null) {
                        print('🚌 Bus seleccionado: $value');
                        final busSeleccionado = _busesDisponibles.firstWhere(
                          (b) => b['id'] == value,
                        );
                        print('📋 Detalles: ${busSeleccionado}');
                      }
                    },
                  ),
                ),
              )
            else
              // ───────── SIN BUSES ─────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: warningRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: warningRed.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.warning, color: warningRed, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No hay buses registrados en el sistema',
                            style: TextStyle(
                              fontSize: 13,
                              color: darkGray,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        print('🔄 Recargando buses...');
                        _cargarBuses();
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Recargar buses'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagenCard(
    String titulo,
    XFile? imagen,
    VoidCallback onTap,
    IconData icono,
    Color color,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icono, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: darkGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onTap,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: lightGray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: imagen != null ? color : mediumGray.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: imagen != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(imagen.path),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icono, size: 40, color: color),
                          const SizedBox(height: 8),
                          Text(
                            'Toca para agregar foto',
                            style: TextStyle(
                              fontSize: 13,
                              color: mediumGray,
                              fontWeight: FontWeight.w500,
                            ),
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

  @override
  void dispose() {
    _precioTipoController.dispose();
    _pesoController.dispose(); // ✅ Dispose del nuevo controlador
    super.dispose();
  }
}
