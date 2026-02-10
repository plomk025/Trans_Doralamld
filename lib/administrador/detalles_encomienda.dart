import 'dart:convert';
import 'dart:io';
import 'package:app2tesis/administrador/coneccion.dart';
import 'package:app2tesis/administrador/offline_services.dart';
import 'package:http/http.dart' as http;
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
  final TextEditingController _pesoController = TextEditingController();

  XFile? _imagenTransito;
  XFile? _imagenEntregada;
  String? _busSeleccionado;
  List<Map<String, dynamic>> _busesDisponibles = [];
  bool _isLoading = false;
  bool _isOnline = true;
  int _pendingOperations = 0;

  final ImagePicker _picker = ImagePicker();
  final OfflineSyncService _syncService = OfflineSyncService();
  final ConnectivitySyncManager _connectivityManager =
      ConnectivitySyncManager();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _inicializarConectividad();
  }

  /// Inicializa el monitoreo de conectividad
  Future<void> _inicializarConectividad() async {
    // Configurar callbacks
    _connectivityManager.onConnectivityChange = (isOnline) {
      if (mounted) {
        setState(() => _isOnline = isOnline);
        if (isOnline) {
          _mostrarExito('Conexión restablecida. Sincronizando...');
        } else {
          _mostrarInfo('Modo offline activado');
        }
      }
    };

    _connectivityManager.onSyncComplete = (result) {
      if (mounted) {
        if (result.success) {
          _mostrarExito(
              'Sincronización completada: ${result.sincronizadas} operaciones');
        } else {
          _mostrarAdvertencia('Error en sincronización: ${result.message}');
        }
      }
    };

    _connectivityManager.onPendingCountChange = (count) {
      if (mounted) {
        setState(() => _pendingOperations = count);
      }
    };

    // Inicializar
    await _connectivityManager.initialize();

    // Verificar estado actual
    _isOnline = await _connectivityManager.isOnline();
    final pending = await _connectivityManager.getPendingOperations();

    if (mounted) {
      setState(() => _pendingOperations = pending.total);
    }
  }

  void _cargarDatos() {
    final costos = widget.data['costos'] ?? {};
    final envio = widget.data['envio'] ?? {};

    _precioTipoController.text = (costos['precio_tipo'] ?? 0).toString();
    _pesoController.text = envio['rango_peso'] ?? '';

    _cargarBuses();
  }

  Future<void> _cargarBuses() async {
    print('🔍 ====== INICIANDO CARGA DE BUSES ======');

    try {
      List<Map<String, dynamic>> buses = [];

      // Cargar buses de Tulcán
      final busesSnapshot = await FirebaseFirestore.instance
          .collection('buses_tulcan_salida')
          .get();

      for (var doc in busesSnapshot.docs) {
        final data = doc.data();
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

      // Cargar buses de La Esperanza
      final buses1Snapshot = await FirebaseFirestore.instance
          .collection('buses_la_esperanza_salida')
          .get();

      for (var doc in buses1Snapshot.docs) {
        final data = doc.data();
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

      setState(() => _busesDisponibles = buses);
      print('✅ Total buses cargados: ${_busesDisponibles.length}');
    } catch (e) {
      print('❌ ERROR AL CARGAR BUSES: $e');
      _mostrarError('Error al cargar buses: $e');
      setState(() => _busesDisponibles = []);
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
      // Obtener UID del remitente
      final remitenteUid = widget.data['remitente']?['uid'];
      if (remitenteUid == null || remitenteUid.toString().isEmpty) {
        _mostrarError('No se encontró el UID del remitente');
        setState(() => _isLoading = false);
        return;
      }

      // Verificar conectividad
      final hasConnection = await _syncService.hasConnection();

      if (widget.estado == 'pendiente') {
        await _procesarEstadoPendiente(remitenteUid, hasConnection);
      } else if (widget.estado == 'en_transito') {
        await _procesarEstadoEnTransito(remitenteUid, hasConnection);
      }

      // Mostrar mensaje según conectividad
      if (hasConnection) {
        _mostrarExito('✅ Encomienda actualizada exitosamente');
      } else {
        _mostrarExito(
            '📴 Actualización guardada. Se sincronizará al conectarse');
      }

      // Actualizar contador de pendientes
      final pending = await _connectivityManager.getPendingOperations();
      setState(() => _pendingOperations = pending.total);

      Navigator.pop(context);
    } catch (e) {
      print('❌ Error al actualizar: $e');
      _mostrarError('Error al actualizar: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Procesa actualización desde estado pendiente
  Future<void> _procesarEstadoPendiente(
      String remitenteUid, bool hasConnection) async {
    final precioTipo = double.parse(_precioTipoController.text.trim());
    final peso = _pesoController.text.trim();
    final busData =
        _busesDisponibles.firstWhere((b) => b['id'] == _busSeleccionado);

    final updateData = <String, dynamic>{
      'costos.precio_tipo': precioTipo,
      'costos.total': precioTipo,
      'envio.rango_peso': peso,
      'estado': 'en_transito',
      'numero': busData['numero'],
      'hora_salida': DateTime.now(),
    };

    if (hasConnection) {
      // ✅ CON INTERNET: Proceso normal
      try {
        // Subir imagen
        final rutaStorage =
            'encomiendas/${widget.codigo}/transito-${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref().child(rutaStorage);
        await ref.putFile(File(_imagenTransito!.path));
        final urlImagen = await ref.getDownloadURL();

        updateData['imagenes.transito'] = urlImagen;

        // Actualizar Firestore
        await FirebaseFirestore.instance
            .collection('encomiendas_registradas')
            .doc(widget.codigo)
            .update(updateData);

        // Asignar a bus
        await FirebaseFirestore.instance
            .collection(busData['coleccion'])
            .doc(_busSeleccionado)
            .set({
          'encomiendas': FieldValue.arrayUnion([widget.codigo])
        }, SetOptions(merge: true));

        // Crear notificación
        await _crearNotificacionOnline(remitenteUid, 'en_transito');
      } catch (e) {
        print('❌ Error en proceso online: $e');
        rethrow;
      }
    } else {
      // 📴 SIN INTERNET: Guardar para sincronización
      print(
          '📴 Modo offline: Guardando actualización para sincronizar después');

      // Actualizar Firestore localmente (se sincronizará con Firebase)
      await FirebaseFirestore.instance
          .collection('encomiendas_registradas')
          .doc(widget.codigo)
          .update(updateData);

      // Guardar actualización pendiente con imagen
      await _syncService.guardarActualizacionPendiente(
        codigoEncomienda: widget.codigo,
        updateData: updateData,
        coleccionBus: busData['coleccion'],
        idBus: _busSeleccionado!,
        rutaImagenLocal: _imagenTransito!.path,
        campoImagen: 'imagenes.transito',
      );

      // Guardar notificación pendiente
      await _guardarNotificacionPendiente(remitenteUid, 'en_transito');
    }
  }

  /// Procesa actualización desde estado en tránsito
  Future<void> _procesarEstadoEnTransito(
      String remitenteUid, bool hasConnection) async {
    final updateData = <String, dynamic>{
      'estado': 'entregado',
      'fecha_entrega': DateTime.now(),
    };

    if (hasConnection) {
      // ✅ CON INTERNET: Proceso normal
      try {
        // Subir imagen
        final rutaStorage =
            'encomiendas/${widget.codigo}/entregada-${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref().child(rutaStorage);
        await ref.putFile(File(_imagenEntregada!.path));
        final urlImagen = await ref.getDownloadURL();

        updateData['imagenes.entregada'] = urlImagen;

        // Actualizar Firestore
        await FirebaseFirestore.instance
            .collection('encomiendas_registradas')
            .doc(widget.codigo)
            .update(updateData);

        // Crear notificación
        await _crearNotificacionOnline(remitenteUid, 'entregado');
      } catch (e) {
        print('❌ Error en proceso online: $e');
        rethrow;
      }
    } else {
      // 📴 SIN INTERNET: Guardar para sincronización
      print(
          '📴 Modo offline: Guardando actualización para sincronizar después');

      // Actualizar Firestore localmente
      await FirebaseFirestore.instance
          .collection('encomiendas_registradas')
          .doc(widget.codigo)
          .update(updateData);

      // Guardar actualización pendiente con imagen
      await _syncService.guardarActualizacionPendiente(
        codigoEncomienda: widget.codigo,
        updateData: updateData,
        coleccionBus: '',
        idBus: '',
        rutaImagenLocal: _imagenEntregada!.path,
        campoImagen: 'imagenes.entregada',
      );

      // Guardar notificación pendiente
      await _guardarNotificacionPendiente(remitenteUid, 'entregado');
    }
  }

  /// Crea notificación cuando hay conexión
  Future<void> _crearNotificacionOnline(
      String uidRemitente, String nuevoEstado) async {
    try {
      final remitente = widget.data['remitente'] ?? {};
      final destinatario = widget.data['destinatario'] ?? {};
      final correoRemitente = remitente['correo'] ?? '';
      final nombreRemitente = remitente['nombre'] ?? '';
      final destinoCiudad = destinatario['ciudad'] ?? '';

      String titulo = '';
      String mensaje = '';
      String accion = '';

      switch (nuevoEstado) {
        case 'en_transito':
          titulo = 'Encomienda en Tránsito 🚚';
          mensaje = destinoCiudad.isNotEmpty
              ? 'Tu encomienda ${widget.codigo} está en camino hacia $destinoCiudad.'
              : 'Tu encomienda ${widget.codigo} ha sido cargada en el bus y está en camino.';
          accion = 'transito';
          break;
        case 'entregado':
          titulo = 'Encomienda Entregada ✅';
          mensaje =
              'Tu encomienda ${widget.codigo} ha sido entregada exitosamente.';
          accion = 'entregado';
          break;
        default:
          titulo = 'Actualización de Encomienda 📬';
          mensaje = 'El estado de tu encomienda ${widget.codigo} ha cambiado.';
          accion = 'actualizacion';
      }

      // Crear notificación en Firestore
      await FirebaseFirestore.instance.collection('notificaciones').add({
        'uid': uidRemitente,
        'correo': correoRemitente,
        'nombre_remitente': nombreRemitente,
        'titulo': titulo,
        'mensaje': mensaje,
        'codigo_encomienda': widget.codigo,
        'estado': nuevoEstado,
        'leida': false,
        'fecha': FieldValue.serverTimestamp(),
        'tipo': 'encomienda',
        'accion': accion,
      });

      // Enviar push notification
      await _enviarNotificacionPush(
        uidRemitente: uidRemitente,
        titulo: titulo,
        mensaje: mensaje,
        codigoEncomienda: widget.codigo,
        estado: nuevoEstado,
      );

      print('✅ Notificación creada y enviada');
    } catch (e) {
      print('❌ Error al crear notificación: $e');
    }
  }

  /// Guarda notificación para enviar después (offline)
  Future<void> _guardarNotificacionPendiente(
      String uidRemitente, String nuevoEstado) async {
    final remitente = widget.data['remitente'] ?? {};
    final destinatario = widget.data['destinatario'] ?? {};
    final correoRemitente = remitente['correo'] ?? '';
    final nombreRemitente = remitente['nombre'] ?? '';
    final destinoCiudad = destinatario['ciudad'] ?? '';

    String titulo = '';
    String mensaje = '';
    String accion = '';

    switch (nuevoEstado) {
      case 'en_transito':
        titulo = 'Encomienda en Tránsito 🚚';
        mensaje = destinoCiudad.isNotEmpty
            ? 'Tu encomienda ${widget.codigo} está en camino hacia $destinoCiudad.'
            : 'Tu encomienda ${widget.codigo} ha sido cargada en el bus y está en camino.';
        accion = 'transito';
        break;
      case 'entregado':
        titulo = 'Encomienda Entregada ✅';
        mensaje =
            'Tu encomienda ${widget.codigo} ha sido entregada exitosamente.';
        accion = 'entregado';
        break;
      default:
        titulo = 'Actualización de Encomienda 📬';
        mensaje = 'El estado de tu encomienda ${widget.codigo} ha cambiado.';
        accion = 'actualizacion';
    }

    await _syncService.guardarNotificacionPendiente(
      uidRemitente: uidRemitente,
      correoRemitente: correoRemitente,
      nombreRemitente: nombreRemitente,
      titulo: titulo,
      mensaje: mensaje,
      codigoEncomienda: widget.codigo,
      estado: nuevoEstado,
      accion: accion,
    );

    print('✅ Notificación guardada para enviar después');
  }

  Future<void> _enviarNotificacionPush({
    required String uidRemitente,
    required String titulo,
    required String mensaje,
    required String codigoEncomienda,
    required String estado,
  }) async {
    try {
      const String baseUrl = 'https://notificaciones-1hoa.onrender.com';
      final Uri url = Uri.parse('$baseUrl/api/notifications/send-to-user');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'userId': uidRemitente,
              'title': titulo,
              'body': mensaje,
              'data': {
                'tipo': 'encomienda',
                'codigo': codigoEncomienda,
                'estado': estado,
                'accion': 'cambio_estado',
                'timestamp': DateTime.now().toIso8601String(),
              },
              'channelId': 'encomiendas_channel',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ Push notification enviada exitosamente');
      } else {
        print('⚠️ Error al enviar push notification: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en _enviarPushNotification: $e');
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

  void _mostrarInfo(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: accentBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarAdvertencia(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: accentOrange,
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.codigo,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: darkGray,
              ),
            ),
            // Indicador de estado de conexión
            Row(
              children: [
                Icon(
                  _isOnline ? Icons.cloud_done : Icons.cloud_off,
                  size: 12,
                  color: _isOnline ? successGreen : warningRed,
                ),
                const SizedBox(width: 4),
                Text(
                  _isOnline ? 'Conectado' : 'Sin conexión',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _isOnline ? successGreen : warningRed,
                  ),
                ),
                if (_pendingOperations > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentOrange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_pendingOperations pendientes',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        actions: [
          // Botón de sincronización manual
          if (_pendingOperations > 0 && _isOnline)
            IconButton(
              icon: const Icon(Icons.sync, color: accentBlue),
              tooltip: 'Sincronizar ahora',
              onPressed: () async {
                final result =
                    await _connectivityManager.sincronizarManualmente();
                if (result.success) {
                  _mostrarExito('Sincronización exitosa');
                } else {
                  _mostrarError(result.message);
                }
              },
            ),
        ],
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
              _buildPesoCard(),
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
                      : Icon(_isOnline ? Icons.check_circle : Icons.save),
                  label: Text(
                    _isLoading
                        ? 'Procesando...'
                        : _isOnline
                            ? 'Actualizar Estado'
                            : 'Guardar (se sincronizará)',
                  ),
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
                labelText: 'Precio *',
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
                hintText: '5 kg, 2.5 kg, 10 kg',
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
                  child: const Icon(Icons.directions_bus,
                      color: accentBlue, size: 24),
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
                        DropdownMenuItem<String>(
                          enabled: false,
                          value: null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              '📍 $lugar',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: accentBlue,
                              ),
                            ),
                          ),
                        ),
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
                                            horizontal: 6, vertical: 2),
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
                                    style: const TextStyle(
                                        fontSize: 11, color: mediumGray),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ];
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _busSeleccionado = value),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: warningRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: warningRed.withOpacity(0.3)),
                ),
                child: const Text('No hay buses disponibles'),
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
                              child: const Icon(Icons.check,
                                  color: Colors.white, size: 16),
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
    _pesoController.dispose();
    super.dispose();
  }
}
