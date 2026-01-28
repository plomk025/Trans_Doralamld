import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class PagoScreen extends StatefulWidget {
  final String busId;
  final int asientoSeleccionado;
  final double total;
  final String userId;
  final String paradaNombre;
  final String userEmail;
  final String nombreComprador;
  final String cedulaComprador;
  final String celularComprador;

  const PagoScreen({
    Key? key,
    required this.busId,
    required this.asientoSeleccionado,
    required this.total,
    required this.userId,
    required this.paradaNombre,
    required this.userEmail,
    required this.nombreComprador,
    required this.cedulaComprador,
    required this.celularComprador,
  }) : super(key: key);

  @override
  _PagoScreenState createState() => _PagoScreenState();
}

class _PagoScreenState extends State<PagoScreen>
    with SingleTickerProviderStateMixin {
  String? metodoPagoSeleccionado;
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();
  File? _imagenComprobante;
  bool _procesando = false;
  bool _validandoImagen = false;
  String? _mensajeValidacion;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Paleta de colores
  final Color primaryBusBlue = const Color.fromARGB(255, 243, 248, 255);
  final Color accentOrange = const Color(0xFFEA580C);
  final Color darkNavy = const Color(0xFF0F172A);
  final Color roadGray = const Color(0xFF334155);
  final Color lightBg = const Color(0xFFF1F5F9);
  final Color textGray = const Color(0xFF475569);
  final Color successGreen = const Color(0xFF059669);
  final Color accentBlue = const Color(0xFF1E40AF);
  final Color mainRed = const Color(0xFF940016);
  final Color accentRed = const Color(0xFFEF4444);
  final Color accentYellow = const Color(0xFFF59E0B);

  static const String ADMIN_EMAIL = 'admin@dominio.com';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _textRecognizer.close();
    _fadeController.dispose();
    super.dispose();
  }

  bool _esAdministrador() {
    return widget.userEmail.toLowerCase() == ADMIN_EMAIL.toLowerCase();
  }

  Future<bool> _validarComprobanteTransferencia(File imagen) async {
    setState(() {
      _validandoImagen = true;
      _mensajeValidacion = 'Validando comprobante...';
    });

    try {
      final inputImage = InputImage.fromFile(imagen);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      String texto = recognizedText.text.toLowerCase();

      List<String> palabrasClave = [
        '¡transferencia exitosa!',
        'banco pichincha',
        'cuenta',
        'monto',
        'valor',
        'comprobante',
        'transacción',
        'transaccion',
        'pichincha',
        'guayaquil',
        'pacifico',
        'bolivariano',
        'produbanco',
        'internacional',
        'austro',
        'débito',
        'debito',
        'crédito',
        'credito',
        '\$',
        'usd',
        'transferencia',
        'transferido',
        'fecha',
        'hora',
        'nombre',
      ];

      int coincidencias = 0;
      for (String palabra in palabrasClave) {
        if (texto.contains(palabra)) {
          coincidencias++;
        }
      }

      bool tieneNumeros = RegExp(r'\d+').hasMatch(texto);

      setState(() {
        _validandoImagen = false;
      });

      if (coincidencias >= 2 && tieneNumeros) {
        setState(() {
          _mensajeValidacion = '✓ Comprobante válido';
        });
        return true;
      } else {
        setState(() {
          _mensajeValidacion =
              '⚠ Esta imagen no parece ser un comprobante de transferencia válido';
        });
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error al validar imagen: $e');
      setState(() {
        _validandoImagen = false;
        _mensajeValidacion =
            '⚠ No se pudo validar la imagen. Asegúrate de que sea clara y legible.';
      });
      return false;
    }
  }

  Future<void> _mostrarOpcionesImagen() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Selecciona una opción',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: darkNavy,
              ),
            ),
            const SizedBox(height: 20),
            _buildOpcionImagen(
              icon: Icons.camera_alt_outlined,
              titulo: 'Tomar foto',
              descripcion: 'Usa la cámara para capturar el comprobante',
              onTap: () {
                Navigator.pop(context);
                _tomarFoto();
              },
            ),
            const SizedBox(height: 12),
            _buildOpcionImagen(
              icon: Icons.photo_library_outlined,
              titulo: 'Elegir de galería',
              descripcion: 'Selecciona una imagen existente',
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen();
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: textGray,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcionImagen({
    required IconData icon,
    required String titulo,
    required String descripcion,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: lightBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: mainRed,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: darkNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descripcion,
                    style: TextStyle(
                      fontSize: 12,
                      color: textGray,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Future<void> _tomarFoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        File imagenTemp = File(image.path);
        bool esValida = await _validarComprobanteTransferencia(imagenTemp);

        if (esValida) {
          setState(() {
            _imagenComprobante = imagenTemp;
          });
        } else {
          _mostrarDialogoImagenInvalida();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al tomar la foto: $e'),
          backgroundColor: accentRed,
        ),
      );
    }
  }

  Future<void> _seleccionarImagen() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        File imagenTemp = File(image.path);
        bool esValida = await _validarComprobanteTransferencia(imagenTemp);

        if (esValida) {
          setState(() {
            _imagenComprobante = imagenTemp;
          });
        } else {
          _mostrarDialogoImagenInvalida();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: $e'),
          backgroundColor: accentRed,
        ),
      );
    }
  }

  void _mostrarDialogoImagenInvalida() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: accentYellow, size: 28),
            const SizedBox(width: 12),
            const Text(
              'Imagen no válida',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          'La imagen seleccionada no parece ser un comprobante de transferencia válido.\n\n'
          'Asegúrate de capturar:\n'
          '• Una imagen clara del comprobante\n'
          '• Que incluya el nombre del banco\n'
          '• Que muestre el monto transferido\n'
          '• Que sea legible y sin reflejos',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: textGray, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: mainRed,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _mostrarOpcionesImagen();
            },
            child: const Text('Intentar de nuevo'),
          ),
        ],
      ),
    );
  }

  Future<String?> _subirComprobanteFirebase() async {
    if (_imagenComprobante == null) return null;

    try {
      String fileName =
          'comprobantes/${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = storage.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(_imagenComprobante!);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error al subir comprobante: $e');
      return null;
    }
  }

  Future<void> _crearNotificacionUsuario(
      String tipo, String mensaje, String reservaId, String userIdFinal) async {
    try {
      if (userIdFinal.isEmpty) {
        debugPrint('⚠️ No se puede crear notificación: userId vacío');
        return;
      }

      // Obtener datos del bus - Buscar en ambas colecciones
      String numeroBus = 'N/A';
      String fechaSalida = '';
      String horaSalida = '';
      String lugarSalida = '';

      // Intentar en colección 'buses_tulcan_salida'
      var busDoc =
          await db.collection('buses_tulcan_salida').doc(widget.busId).get();

      // Si no existe, intentar en 'buses_la_esperanza_salida'
      if (!busDoc.exists) {
        busDoc =
            await db.collection('buses_tulcan_salida').doc(widget.busId).get();
      }

      if (busDoc.exists) {
        final busData = busDoc.data();
        if (busData != null) {
          numeroBus = busData['numero']?.toString() ?? 'N/A';
          fechaSalida = busData['fechaSalida']?.toString() ??
              busData['fecha_salida']?.toString() ??
              '';
          horaSalida = busData['horaSalida']?.toString() ??
              busData['hora_salida']?.toString() ??
              '';
          lugarSalida = busData['lugar_salida']?.toString() ?? 'Tulcán';
        }
      }

      // ✅ CREAR NOTIFICACIÓN EN FIRESTORE (sin mostrar nada en pantalla)
      await db.collection('notificaciones').add({
        'userId': userIdFinal,
        'email': widget.userEmail,
        'tipo': tipo,
        'titulo': tipo == 'compra_aprobada'
            ? '✓ Compra Confirmada'
            : tipo == 'compra_pendiente'
                ? '⏳ Compra Pendiente'
                : '📋 Reserva Registrada',
        'mensaje': mensaje,
        'reservaId': reservaId,
        'busId': widget.busId,
        'numeroBus': numeroBus,
        'paradaNombre': widget.paradaNombre,
        'origenNombre': lugarSalida,
        'nombreComprador': widget.nombreComprador,
        'cedulaComprador': widget.cedulaComprador,
        'celularComprador': widget.celularComprador,
        'metodoPago': metodoPagoSeleccionado ?? 'efectivo',
        'estado': metodoPagoSeleccionado == 'transferencia'
            ? 'pendiente_verificacion'
            : (_esAdministrador() ? 'aprobado' : 'pendiente_verificacion'),
        'precio': widget.total,
        'total': widget.total,
        'asiento': widget.asientoSeleccionado,
        'asientos': [widget.asientoSeleccionado],
        'fechaSalida': fechaSalida,
        'horaSalida': horaSalida,
        'leida': false,
        'fecha': FieldValue.serverTimestamp(),
        'fechaCompra': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Notificación creada silenciosamente en Firestore');
    } catch (e) {
      debugPrint('❌ Error al crear notificación: $e');
    }
  }

  Future<void> _procesarPago() async {
    // Validar método de pago seleccionado
    if (metodoPagoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecciona un método de pago'),
          backgroundColor: accentYellow,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // Validar comprobante si es transferencia
    if (metodoPagoSeleccionado == 'transferencia' &&
        _imagenComprobante == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Debes subir el comprobante de pago'),
          backgroundColor: accentYellow,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() {
      _procesando = true;
    });

    try {
      // ==================== PASO 1: Obtener userId de manera robusta ====================
      String userIdFinal = '';

      // Prioridad 1: userId pasado como parámetro
      if (widget.userId.isNotEmpty) {
        userIdFinal = widget.userId;
        debugPrint('✅ userId obtenido del widget: $userIdFinal');
      }
      // Prioridad 2: Usuario actual de Firebase Auth
      else if (FirebaseAuth.instance.currentUser != null) {
        userIdFinal = FirebaseAuth.instance.currentUser!.uid;
        debugPrint('✅ userId obtenido de FirebaseAuth: $userIdFinal');
      }

      // Validación crítica: si aún no tenemos userId
      if (userIdFinal.isEmpty) {
        debugPrint('⚠️ No se pudo obtener userId');

        // Para admin, crear un ID temporal basado en email
        if (_esAdministrador()) {
          userIdFinal = 'admin_${DateTime.now().millisecondsSinceEpoch}';
          debugPrint('⚠️ Admin sin userId - usando temporal: $userIdFinal');
        } else {
          throw Exception(
              'Error: No se pudo identificar al usuario. Por favor, cierra sesión y vuelve a iniciar.');
        }
      }

      // Validar que tenemos email
      if (widget.userEmail.isEmpty) {
        throw Exception('Error: Email de usuario no disponible');
      }

      debugPrint('📝 Procesando pago para:');
      debugPrint('   userId: $userIdFinal');
      debugPrint('   email: ${widget.userEmail}');
      debugPrint('   método: $metodoPagoSeleccionado');
      debugPrint('   asiento: ${widget.asientoSeleccionado}');

      // ==================== PASO 2: Subir comprobante si es transferencia ====================
      String? urlComprobante;
      if (metodoPagoSeleccionado == 'transferencia') {
        debugPrint('📤 Subiendo comprobante...');
        urlComprobante = await _subirComprobanteFirebase();

        if (urlComprobante == null) {
          throw Exception(
              'No se pudo subir el comprobante. Verifica tu conexión a internet.');
        }
        debugPrint('✅ Comprobante subido: $urlComprobante');
      }

      // ==================== PASO 3: Determinar estados según método y rol ====================
      String estadoReserva;
      String estadoAsiento;
      String tipoNotificacion;
      String mensajeNotificacion;

      if (metodoPagoSeleccionado == 'transferencia') {
        estadoReserva = 'pendiente_verificacion';
        estadoAsiento = 'reservado';
        tipoNotificacion = 'reserva_creada';
        mensajeNotificacion =
            'Tu comprobante está en revisión. El asiento ${widget.asientoSeleccionado} quedará reservado hasta la verificación. Te notificaremos cuando sea aprobado.';
      } else if (metodoPagoSeleccionado == 'efectivo') {
        if (_esAdministrador()) {
          estadoReserva = 'aprobado';
          estadoAsiento = 'pagado';
          tipoNotificacion = 'compra_aprobada';
          mensajeNotificacion =
              '¡Pago confirmado! Asiento ${widget.asientoSeleccionado} pagado exitosamente.';
        } else {
          estadoReserva = 'pendiente_verificacion';
          estadoAsiento = 'reservado';
          tipoNotificacion = 'compra_pendiente';
          mensajeNotificacion =
              'Reserva registrada. Asiento ${widget.asientoSeleccionado} reservado. Debes pagar en ventanilla para confirmar tu compra.';
        }
      } else {
        estadoReserva = 'pendiente_confirmacion';
        estadoAsiento = 'reservado';
        tipoNotificacion = 'reserva_creada';
        mensajeNotificacion = 'Reserva registrada exitosamente.';
      }

      debugPrint('📋 Estados determinados:');
      debugPrint('   reserva: $estadoReserva');
      debugPrint('   asiento: $estadoAsiento');

      // ==================== PASO 4: Crear reserva en Firestore ====================
      // ==================== PASO 4: Crear reserva en Firestore ====================
      debugPrint('📝 Creando documento de reserva...');

// Preparar datos base de la reserva
      final reservaData = <String, dynamic>{
        'busId': widget.busId,
        'userId': userIdFinal,
        'email': widget.userEmail,
        'nombreComprador': widget.nombreComprador,
        'cedulaComprador': widget.cedulaComprador,
        'celularComprador': widget.celularComprador,
        'asientos': [widget.asientoSeleccionado],
        'total': widget.total,
        'metodoPago': metodoPagoSeleccionado ?? 'efectivo',
        'estado': estadoReserva,
        'fechaReserva': FieldValue.serverTimestamp(),
        'paradaNombre': widget.paradaNombre,
        'procesadoPor': _esAdministrador() ? 'admin' : 'usuario',
      };

// SOLO agregar comprobanteUrl si existe (transferencia)
      if (urlComprobante != null && urlComprobante.isNotEmpty) {
        reservaData['comprobanteUrl'] = urlComprobante;
        debugPrint('✅ comprobanteUrl agregado: $urlComprobante');
      } else {
        debugPrint('ℹ️ Pago en efectivo - Sin campo comprobanteUrl');
      }

      debugPrint('📋 Datos de reserva: $reservaData');

      final reservaRef = await db.collection('reservas').add(reservaData);
      debugPrint('✅ Reserva creada con ID: ${reservaRef.id}');

// ==================== PASO 5: Crear en "comprados" si es admin con efectivo ====================
      if (estadoReserva == 'aprobado' && _esAdministrador()) {
        debugPrint('📝 Creando documento en comprados (admin)...');

        try {
          // Preparar datos base de comprado
          final compradoData = <String, dynamic>{
            'busId': widget.busId,
            'userId': userIdFinal,
            'email': widget.userEmail,
            'nombreComprador': widget.nombreComprador,
            'cedulaComprador': widget.cedulaComprador,
            'celularComprador': widget.celularComprador,
            'asientos': [widget.asientoSeleccionado],
            'total': widget.total,
            'metodoPago': metodoPagoSeleccionado ?? 'efectivo',
            'estado': 'aprobado',
            'fechaCompra': FieldValue.serverTimestamp(),
            'paradaNombre': widget.paradaNombre,
            'reservaId': reservaRef.id,
            'aprobadoPor': 'admin',
          };

          // SOLO agregar comprobanteUrl si existe (no debería para efectivo admin)
          if (urlComprobante != null && urlComprobante.isNotEmpty) {
            compradoData['comprobanteUrl'] = urlComprobante;
          }

          await db.collection('comprados').add(compradoData);
          debugPrint(
              '✅ Documento de compra creado (sin comprobanteUrl para efectivo)');
        } catch (e) {
          debugPrint('⚠️ Error al crear comprado (no crítico): $e');
        }
      }

      // ==================== PASO 6: Actualizar asiento en el bus ====================
      debugPrint('📝 Actualizando asiento en bus...');

      final busRef = db.collection('buses_tulcan_salida').doc(widget.busId);
      final busDoc = await busRef.get();

      if (!busDoc.exists) {
        throw Exception('Bus no encontrado en la base de datos');
      }

      var data = busDoc.data();
      if (data == null) {
        throw Exception('Datos del bus no disponibles');
      }

      List<Map<String, dynamic>> asientos = [];
      if (data['asientos'] != null) {
        asientos = List<Map<String, dynamic>>.from(data['asientos']);
      } else {
        throw Exception('El bus no tiene asientos configurados');
      }

      final index =
          asientos.indexWhere((a) => a['numero'] == widget.asientoSeleccionado);

      if (index == -1) {
        throw Exception(
            'Asiento ${widget.asientoSeleccionado} no encontrado en el bus');
      }

      // Verificar que el asiento esté en estado válido
      final estadoActualAsiento = asientos[index]['estado'];
      debugPrint('🔍 Estado actual del asiento: $estadoActualAsiento');

      if (estadoActualAsiento != 'intentandoReservar' &&
          estadoActualAsiento != 'disponible') {
        debugPrint('⚠️ Asiento en estado: $estadoActualAsiento');
        // Continuar de todas formas si es el mismo usuario
        if (asientos[index]['email'] != widget.userEmail) {
          throw Exception('El asiento ya no está disponible');
        }
      }

      // Actualizar asiento
      asientos[index] = {
        'numero': widget.asientoSeleccionado,
        'estado': estadoAsiento,
        'email': widget.userEmail,
        'userId': userIdFinal,
        'reservaId': reservaRef.id,
        'timestamp': Timestamp.now(),
        'lastHeartbeat': Timestamp.now(),
        'paradaNombre': widget.paradaNombre,
        'precio': widget.total,
      };

      await busRef.update({'asientos': asientos});
      debugPrint('✅ Asiento actualizado correctamente');

      // ==================== PASO 7: Crear notificación ====================
      // ==================== PASO 7: Crear notificación ====================
// ⚠️ NO crear notificación si es administrador
      if (!_esAdministrador()) {
        debugPrint('📝 Creando notificación...');

        try {
          await _crearNotificacionUsuario(
            tipoNotificacion,
            mensajeNotificacion,
            reservaRef.id,
            userIdFinal,
          );
          debugPrint('✅ Notificación creada');
        } catch (e) {
          debugPrint('⚠️ Error al crear notificación (no crítico): $e');
        }
      } else {
        debugPrint('ℹ️ Usuario administrador - No se crea notificación');
      }

      // ==================== PASO 8: Finalizar y mostrar resultado ====================
      if (!mounted) return;

      setState(() {
        _procesando = false;
      });

      debugPrint('✅ ¡Proceso completado exitosamente!');

      // Mostrar diálogo de éxito
      _mostrarDialogoResultado(estadoReserva, mensajeNotificacion);
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR CRÍTICO en _procesarPago:');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');

      if (!mounted) return;

      setState(() {
        _procesando = false;
      });

      // Mostrar error al usuario con más detalles
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Error al procesar el pago',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                e.toString().replaceAll('Exception: ', ''),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: accentRed,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Cerrar',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  void _mostrarDialogoResultado(String estadoReserva, String mensaje) {
    IconData icono;
    Color color;
    String titulo;

    if (estadoReserva == 'aprobado') {
      icono = Icons.check_circle_outline;
      color = successGreen;
      titulo = '¡Pago Confirmado!';
    } else if (estadoReserva == 'pendiente_verificacion') {
      icono = Icons.hourglass_empty_rounded;
      color = accentYellow;
      titulo = 'En Verificación';
    } else {
      icono = Icons.event_seat_rounded;
      color = mainRed;
      titulo = 'Reserva Registrada';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, color: color, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mensaje,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
              if (estadoReserva == 'aprobado') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: successGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: successGreen, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'El asiento ha sido confirmado como PAGADO.',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true);
              },
              child: const Text(
                'Entendido',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBusBlue,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildHeader(),
          _buildResumenCard(),
          _buildMetodosPagoSection(),
          if (metodoPagoSeleccionado == 'transferencia')
            _buildTransferenciaSection(),
          SliverToBoxAdapter(
            child:
                SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 243, 248, 255),
              Color.fromARGB(255, 245, 249, 255)
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(false),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(0, 255, 255, 255),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        const Color.fromARGB(0, 255, 255, 255)
                                            .withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Color(0xFF940016),
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'MÉTODO DE PAGO',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color.fromARGB(255, 36, 35, 35),
                                  letterSpacing: 1,
                                ),
                              ),
                              Row(
                                children: [
                                  const Text(
                                    'Finaliza tu compra',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Color.fromARGB(255, 38, 38, 39),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  if (_esAdministrador()) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: successGreen,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'ADMIN',
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(0, 255, 255, 255),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color.fromARGB(0, 253, 253, 253)
                                .withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              color: const Color(0xFF940016),
                              size: 25,
                            ),
                            SizedBox(width: 6),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Método de Pago',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Color.fromARGB(255, 36, 35, 35),
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: const Text(
                      'Selecciona cómo deseas realizar el pago de tu boleto',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(255, 71, 74, 76),
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResumenCard() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.receipt_long_outlined,
                          color: accentBlue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Resumen de Compra',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: darkNavy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey[200], height: 1),
                const SizedBox(height: 16),
                _buildDetalleRow('Asiento', '#${widget.asientoSeleccionado}',
                    Icons.event_seat_rounded),
                const SizedBox(height: 12),
                _buildDetalleRow(
                    'Parada', widget.paradaNombre, Icons.location_on_outlined),
                const SizedBox(height: 12),
                _buildDetalleRow('Pasajero', widget.nombreComprador,
                    Icons.person_outline_rounded),
                const SizedBox(height: 16),
                Divider(color: Colors.grey[200], height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total a Pagar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: darkNavy,
                      ),
                    ),
                    Text(
                      '\$${widget.total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: mainRed,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetalleRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: textGray),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: textGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: darkNavy,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildMetodosPagoSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecciona el método de pago',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: darkNavy,
                  ),
                ),
                const SizedBox(height: 16),
                // Solo mostrar transferencia si NO es administrador
                if (!_esAdministrador()) ...[
                  _buildMetodoPago(
                    'transferencia',
                    'Transferencia Bancaria',
                    Icons.account_balance_outlined,
                    'Sube tu comprobante para verificación',
                  ),
                  const SizedBox(height: 12),
                ],
                _buildMetodoPago(
                  'efectivo',
                  'Pago en Efectivo',
                  Icons.payments_outlined,
                  _esAdministrador()
                      ? 'Confirma el pago inmediatamente'
                      : 'Paga en ventanilla - Requiere confirmación',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetodoPago(
      String id, String titulo, IconData icono, String descripcion) {
    bool seleccionado = metodoPagoSeleccionado == id;

    return InkWell(
      onTap: () {
        setState(() {
          metodoPagoSeleccionado = id;
          if (id != 'transferencia') {
            _imagenComprobante = null;
            _mensajeValidacion = null;
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: seleccionado ? mainRed.withOpacity(0.05) : lightBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado ? mainRed : Colors.grey[300]!,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: seleccionado ? mainRed : roadGray,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icono,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: seleccionado ? mainRed : darkNavy,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descripcion,
                    style: TextStyle(
                      fontSize: 12,
                      color: textGray,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (seleccionado)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: mainRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferenciaSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.account_balance,
                          color: accentBlue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Datos Bancarios',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: darkNavy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: lightBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDatoBancario('Banco', 'Banco Pichincha'),
                      const SizedBox(height: 12),
                      _buildDatoBancario('Tipo de Cuenta', 'Ahorros'),
                      const SizedBox(height: 12),
                      _buildDatoBancario('Número de Cuenta', '2100123456'),
                      const SizedBox(height: 12),
                      _buildDatoBancario(
                          'Titular', 'Empresa de Transporte XYZ'),
                      const SizedBox(height: 12),
                      _buildDatoBancario('RUC', '1234567890001'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentYellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentYellow.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: accentYellow, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Realiza la transferencia y sube el comprobante para verificación',
                          style: TextStyle(
                            fontSize: 12,
                            color: darkNavy,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Comprobante de Pago',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: darkNavy,
                  ),
                ),
                const SizedBox(height: 12),
                if (_imagenComprobante == null)
                  InkWell(
                    onTap: _mostrarOpcionesImagen,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: lightBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          style: BorderStyle.solid,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_outlined,
                                size: 40, color: textGray),
                            const SizedBox(height: 8),
                            Text(
                              'Subir Comprobante',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: darkNavy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Toca para seleccionar',
                              style: TextStyle(
                                fontSize: 12,
                                color: textGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _imagenComprobante!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _imagenComprobante = null;
                              _mensajeValidacion = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: accentRed,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (_mensajeValidacion != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _mensajeValidacion!.contains('✓')
                          ? successGreen.withOpacity(0.1)
                          : accentYellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _mensajeValidacion!.contains('✓')
                            ? successGreen.withOpacity(0.3)
                            : accentYellow.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _mensajeValidacion!.contains('✓')
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_rounded,
                          color: _mensajeValidacion!.contains('✓')
                              ? successGreen
                              : accentYellow,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _mensajeValidacion!,
                            style: TextStyle(
                              fontSize: 13,
                              color: darkNavy,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_validandoImagen) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(mainRed),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Validando comprobante...',
                          style: TextStyle(
                            fontSize: 13,
                            color: textGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatoBancario(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: textGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: darkNavy,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final padding = MediaQuery.of(context).padding;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: mainRed,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              shadowColor: mainRed.withOpacity(0.3),
            ),
            onPressed: _procesando ? null : _procesarPago,
            child: _procesando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        metodoPagoSeleccionado == 'transferencia'
                            ? Icons.upload_file
                            : Icons.check_circle_outline,
                        size: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        metodoPagoSeleccionado == 'transferencia'
                            ? 'Enviar Comprobante'
                            : 'Confirmar Pago',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
