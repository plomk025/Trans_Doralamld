import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

// Modelo de datos para compartir entre pantallas
class EncomiendaData {
  String codigoEnvio;
  String? nombreRemitente;
  String? cedulaRemitente;
  String? telefonoRemitente;
  String? correoRemitente;
  String? lugarSalida;
  String? nombreDestinatario;
  String? telefonoDestinatario;
  String? ciudadDestino;
  String? cedulaDestinatario;
  String? correoDestinatario;
  String? direccionDestinatario;
  String? referenciaDestinatario;
  String? tipoEncomienda;
  String? rangoPeso;
  double? valorDeclarado;
  String? observaciones;
  String? urlImagenAntesSello;
  String? urlImagenEmpacado;
  double? precioPeso;
  double? precioTipo;
  double? total;
  String? uid;

  EncomiendaData({
    required this.codigoEnvio,
    this.uid,
    this.nombreRemitente,
    this.cedulaRemitente,
    this.telefonoRemitente,
    this.correoRemitente,
    this.lugarSalida,
    this.nombreDestinatario,
    this.telefonoDestinatario,
    this.ciudadDestino,
    this.tipoEncomienda,
    this.rangoPeso,
    this.valorDeclarado,
    this.observaciones,
    this.urlImagenAntesSello,
    this.urlImagenEmpacado,
    this.precioPeso,
    this.precioTipo,
    this.total,
  });

  bool isComplete() {
    return nombreRemitente != null &&
        cedulaRemitente != null &&
        telefonoRemitente != null &&
        correoRemitente != null &&
        lugarSalida != null &&
        nombreDestinatario != null &&
        telefonoDestinatario != null &&
        ciudadDestino != null &&
        tipoEncomienda != null &&
        rangoPeso != null &&
        urlImagenAntesSello != null &&
        urlImagenEmpacado != null;
  }

  Map<String, dynamic> toFirebaseMap() {
    return {
      'uid': uid,
      'codigo_envio': codigoEnvio,
      'fecha_creacion': DateTime.now().toIso8601String(),
      'estado': 'pendiente',
      'remitente': {
        'uid': uid,
        'nombre': nombreRemitente,
        'cedula': cedulaRemitente,
        'telefono': telefonoRemitente,
        'correo': correoRemitente,
        'lugar_salida': lugarSalida,
      },
      'destinatario': {
        'nombre': nombreDestinatario,
        'telefono': telefonoDestinatario,
        'ciudad': ciudadDestino,
        'cedula': cedulaDestinatario,
        'correo': correoDestinatario,
        'direccion': direccionDestinatario,
        'referencia': referenciaDestinatario,
      },
      'envio': {
        'tipo_encomienda': tipoEncomienda,
        'rango_peso': rangoPeso,
        'valor_declarado': valorDeclarado ?? 0.0,
        'observaciones': observaciones ?? '',
      },
      'imagenes': {
        'antes_sello': urlImagenAntesSello,
        'empacado': urlImagenEmpacado,
      },
      'costos': {
        'precio_peso': precioPeso ?? 0.0,
        'precio_tipo': precioTipo ?? 0.0,
        'total': total ?? 0.0,
      },
    };
  }
}

class EnvioScreen extends StatefulWidget {
  final EncomiendaData encomiendaData;

  const EnvioScreen({super.key, required this.encomiendaData});

  @override
  State<EnvioScreen> createState() => _EnvioScreenState();
}

class _EnvioScreenState extends State<EnvioScreen> {
  static const Color primaryBusBlue = Color(0xFF940016);
  static const Color accentOrange = Color(0xFF940016);
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color lightBg = Color(0xFFF1F5F9);
  static const Color textGray = Color(0xFF475569);
  static const Color successGreen = Color(0xFF059669);
  static const Color warningRed = Color(0xFFEF4444);

  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _precioTipoController = TextEditingController();
  final TextEditingController _observacionesController =
      TextEditingController();

  bool _isLoading = false;
  bool _isAdmin = false; // ✅ Ahora se determina desde Firebase
  bool _encomiendaGuardada = false;
  List<Map<String, dynamic>> _tiposEncomienda = [];
  String? _tipoEncomiendaSeleccionado;
  XFile? _imagenPaquete;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _verificarUsuario(); // ✅ MODIFICADO: Ahora verifica el rol desde Firebase
    _cargarTiposEncomienda();

    _tipoEncomiendaSeleccionado = widget.encomiendaData.tipoEncomienda;
    _pesoController.text = widget.encomiendaData.rangoPeso ?? '';
    if (widget.encomiendaData.precioTipo != null) {
      _precioTipoController.text = widget.encomiendaData.precioTipo.toString();
    }
    _observacionesController.text = widget.encomiendaData.observaciones ?? '';
  }

  // ✅ MODIFICADO: Verifica el rol desde Firebase en lugar del correo
  Future<void> _verificarUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios_registrados ')
            .doc(user.uid)
            .get();

        if (doc.exists && mounted) {
          final rol = doc.data()?['rol']?.toString().toLowerCase() ?? '';
          setState(() {
            _isAdmin = rol == 'administrador';
          });
          print('🔐 Rol del usuario: $rol');
          print('👤 Es administrador: $_isAdmin');
        } else {
          setState(() {
            _isAdmin = false;
          });
          print('⚠️ No se encontró el documento del usuario');
        }
      } catch (e) {
        print('❌ Error al verificar usuario: $e');
        setState(() {
          _isAdmin = false;
        });
      }
    }
  }

  Future<void> _cargarTiposEncomienda() async {
    setState(() => _isLoading = true);

    try {
      final tiposSnapshot = await FirebaseFirestore.instance
          .collection('Tipo_encomienda')
          .where('activo', isEqualTo: true)
          .get();

      _tiposEncomienda = tiposSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'tipo': data['Tipo'] ?? data['tipo'] ?? 'Sin nombre',
          'descripcion': data['descripcion'] ?? '',
          'precio_adicional': 0.0,
        };
      }).toList();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError('Error al cargar datos: $e');
    }
  }

  Future<void> _seleccionarImagen() async {
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
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Seleccionar foto del paquete',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: darkNavy,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: accentOrange),
                ),
                title: const Text('Tomar foto'),
                subtitle: const Text('Usar la cámara'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library, color: successGreen),
                ),
                title: const Text('Elegir de galería'),
                subtitle: const Text('Seleccionar foto existente'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? imagen = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
      );

      if (imagen != null) {
        setState(() {
          _imagenPaquete = imagen;
        });
      }
    } catch (e) {
      _mostrarError('Error al seleccionar imagen: $e');
    }
  }

  Future<String?> _subirImagen(XFile imagen) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
          'encomiendas/${widget.encomiendaData.codigoEnvio}/paquete-${DateTime.now().millisecondsSinceEpoch}.jpg');

      await ref.putFile(File(imagen.path));
      return await ref.getDownloadURL();
    } catch (e) {
      _mostrarError('Error al subir imagen: $e');
      return null;
    }
  }

  bool _validarFormulario() {
    if (_tipoEncomiendaSeleccionado == null) {
      _mostrarError('Seleccione el tipo de encomienda');
      return false;
    }

    if (_isAdmin) {
      if (_pesoController.text.trim().isEmpty) {
        _mostrarError('Ingrese el peso del paquete');
        return false;
      }
      if (_precioTipoController.text.trim().isEmpty) {
        _mostrarError('Ingrese el precio del tipo de encomienda');
        return false;
      }
    }

    if (_imagenPaquete == null) {
      _mostrarError('Debe agregar la foto del paquete');
      return false;
    }
    return true;
  }

  Future<void> _guardarYContinuar() async {
    // ✅ PREVENIR DOBLE GUARDADO
    if (_encomiendaGuardada) {
      _mostrarError('La encomienda ya ha sido registrada');
      return;
    }

    if (!_validarFormulario()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final String? currentUserUid = user?.uid;

      print('🔐 UID del usuario actual: $currentUserUid');

      if (currentUserUid == null) {
        _mostrarError(
            'No se pudo identificar al usuario. Por favor inicia sesión nuevamente.');
        setState(() => _isLoading = false);
        return;
      }

      String? urlImagenPaquete;

      if (_imagenPaquete != null) {
        urlImagenPaquete = await _subirImagen(_imagenPaquete!);
      }

      final tipoData = _tiposEncomienda.firstWhere(
        (t) => t['tipo'] == _tipoEncomiendaSeleccionado,
        orElse: () => {'precio_adicional': 0.0},
      );

      double precioPeso = 0.0;
      double precioTipo = 0.0;
      double total = 0.0;
      String pesoTexto = '';

      if (_isAdmin) {
        final pesoIngresado =
            double.tryParse(_pesoController.text.trim()) ?? 0.0;
        precioPeso = pesoIngresado;
        precioTipo = double.tryParse(_precioTipoController.text.trim()) ?? 0.0;
        pesoTexto = _pesoController.text.trim();
        total = precioTipo;
      } else {
        precioPeso = 0.0;
        precioTipo = 0.0;
        total = 0.0;
        pesoTexto = '0';
      }

      widget.encomiendaData.tipoEncomienda = _tipoEncomiendaSeleccionado;
      widget.encomiendaData.rangoPeso = pesoTexto;
      widget.encomiendaData.valorDeclarado = 0.0;
      widget.encomiendaData.observaciones =
          _observacionesController.text.trim();
      widget.encomiendaData.urlImagenEmpacado = urlImagenPaquete;
      widget.encomiendaData.precioPeso = precioPeso;
      widget.encomiendaData.precioTipo = precioTipo;
      widget.encomiendaData.total = total;
      widget.encomiendaData.uid = currentUserUid;

      final docData = {
        'uid': currentUserUid,
        'codigo_envio': widget.encomiendaData.codigoEnvio,
        'fecha_creacion': FieldValue.serverTimestamp(),
        'estado': 'pendiente',
        'remitente': {
          'uid': currentUserUid,
          'nombre': widget.encomiendaData.nombreRemitente,
          'cedula': widget.encomiendaData.cedulaRemitente,
          'telefono': widget.encomiendaData.telefonoRemitente,
          'correo': widget.encomiendaData.correoRemitente,
          'lugar_salida': widget.encomiendaData.lugarSalida,
        },
        'destinatario': {
          'nombre': widget.encomiendaData.nombreDestinatario,
          'telefono': widget.encomiendaData.telefonoDestinatario,
          'ciudad': widget.encomiendaData.ciudadDestino,
          'cedula': widget.encomiendaData.cedulaDestinatario,
          'correo': widget.encomiendaData.correoDestinatario,
          'direccion': widget.encomiendaData.direccionDestinatario,
          'referencia': widget.encomiendaData.referenciaDestinatario,
        },
        'envio': {
          'tipo_encomienda': _tipoEncomiendaSeleccionado,
          'rango_peso': pesoTexto,
          'valor_declarado': 0.0,
          'observaciones': widget.encomiendaData.observaciones ?? '',
        },
        'imagenes': {
          'paquete': urlImagenPaquete,
          'transito': null,
          'entregada': null,
        },
        'costos': {
          'precio_peso': precioPeso,
          'precio_tipo': precioTipo,
          'total': total,
        },
      };

      print('💾 Guardando encomienda con UID: $currentUserUid');
      print('📋 Datos a guardar: $docData');

      await FirebaseFirestore.instance
          .collection('encomiendas_registradas')
          .doc(widget.encomiendaData.codigoEnvio)
          .set(docData);

      print('✅ Encomienda guardada exitosamente');

      // ✅ MARCAR COMO GUARDADA
      _encomiendaGuardada = true;

      await _crearNotificacionRegistro(
        currentUserUid,
        widget.encomiendaData.codigoEnvio,
        widget.encomiendaData.correoRemitente ?? '',
        widget.encomiendaData.nombreRemitente ?? '',
      );

      setState(() => _isLoading = false);

      if (mounted) {
        _mostrarDialogoFinalizacion();
      }
    } catch (e, stackTrace) {
      setState(() => _isLoading = false);
      print('❌ Error al guardar encomienda: $e');
      print('Stack trace: $stackTrace');
      _mostrarError('Error al guardar encomienda: $e');
    }
  }

  Future<void> _crearNotificacionRegistro(
    String uid,
    String codigoEnvio,
    String correoRemitente,
    String nombreRemitente,
  ) async {
    try {
      print('📧 Creando notificación de registro...');
      print('   UID: $uid');
      print('   Código: $codigoEnvio');
      print('   Correo: $correoRemitente');
      print('   Nombre: $nombreRemitente');

      await FirebaseFirestore.instance.collection('notificaciones').add({
        'uid': uid,
        'correo': correoRemitente,
        'nombre_remitente': nombreRemitente,
        'titulo': 'Encomienda Registrada 📦',
        'mensaje': _isAdmin
            ? 'La encomienda $codigoEnvio ha sido registrada exitosamente por el administrador.'
            : 'Tu solicitud de encomienda $codigoEnvio ha sido registrada. Debes llevar tu paquete a nuestras oficinas para completar el proceso.',
        'codigo_encomienda': codigoEnvio,
        'estado': 'pendiente',
        'leida': false,
        'fecha': FieldValue.serverTimestamp(),
        'tipo': 'encomienda',
        'accion': 'registro',
      });

      print('✅ Notificación creada exitosamente');
    } catch (e) {
      print('❌ Error al crear notificación: $e');
    }
  }

  void _copiarCodigo() {
    Clipboard.setData(ClipboardData(text: widget.encomiendaData.codigoEnvio));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child:
                  Text('Código ${widget.encomiendaData.codigoEnvio} copiado'),
            ),
          ],
        ),
        backgroundColor: successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _compartirCodigo() {
    Share.share(
      '📦 Mi código de encomienda es: ${widget.encomiendaData.codigoEnvio}\n\n'
      '✅ Puedes hacer seguimiento de tu envío con este código en nuestra aplicación.',
      subject: 'Código de Encomienda - ${widget.encomiendaData.codigoEnvio}',
    );
  }

  // ✅ DIÁLOGO CON BLOQUEO DE RETROCESO
  void _mostrarDialogoFinalizacion() {
    showDialog(
      context: context,
      barrierDismissible: false, // ✅ No se puede cerrar tocando fuera
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // ✅ BLOQUEA EL BOTÓN DE RETROCESO
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(
                      MediaQuery.of(context).size.width < 360 ? 16 : 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: successGreen.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            color: successGreen,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isAdmin
                              ? '¡Registro Completado!'
                              : '¡Solicitud Registrada!',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width < 360
                                ? 18
                                : 20,
                            fontWeight: FontWeight.w700,
                            color: darkNavy,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: accentOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: accentOrange.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Código de Envío',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: textGray,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  widget.encomiendaData.codigoEnvio,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: accentOrange,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _copiarCodigo,
                                      icon: const Icon(Icons.copy_rounded,
                                          size: 14),
                                      label: const Text(
                                        'Copiar',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: accentOrange,
                                        side: BorderSide(
                                          color: accentOrange.withOpacity(0.5),
                                          width: 1.5,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _compartirCodigo,
                                      icon: const Icon(Icons.share_rounded,
                                          size: 14),
                                      label: const Text(
                                        'Compartir',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: successGreen,
                                        side: BorderSide(
                                          color: successGreen.withOpacity(0.5),
                                          width: 1.5,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_isAdmin) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: lightBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: accentOrange,
                                  size: 20,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'El registro ha sido completado exitosamente',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: darkNavy,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.scale_outlined,
                                  color: Colors.orange,
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Próximos Pasos',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: darkNavy,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Debes llevar tu paquete a nuestras oficinas para:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textGray,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                _buildPasoItemCompacto(
                                  icon: Icons.scale,
                                  texto: 'Pesaje oficial del paquete',
                                ),
                                const SizedBox(height: 6),
                                _buildPasoItemCompacto(
                                  icon: Icons.attach_money,
                                  texto: 'Cálculo del valor final',
                                ),
                                const SizedBox(height: 6),
                                _buildPasoItemCompacto(
                                  icon: Icons.payment,
                                  texto: 'Realizar el pago correspondiente',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accentOrange.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.info,
                                  color: accentOrange,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Guarda este código para tu seguimiento',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: accentOrange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    MediaQuery.of(context).size.width < 360 ? 16 : 20,
                    0,
                    MediaQuery.of(context).size.width < 360 ? 16 : 20,
                    MediaQuery.of(context).size.width < 360 ? 16 : 20,
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      // ✅ Cerrar diálogo y volver al inicio
                      Navigator.of(context).pop(); // Cierra el diálogo
                      Navigator.of(context)
                          .popUntil((route) => route.isFirst); // Va al inicio
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentOrange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Finalizar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasoItemCompacto(
      {required IconData icon, required String texto}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: Colors.orange.shade700,
            size: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              fontSize: 11,
              color: darkNavy,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: warningRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _pesoController.dispose();
    _precioTipoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  // ✅ PROTECCIÓN CONTRA RETROCESO - SI REGRESA, VA AL INICIO
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // ⚠️ SIEMPRE ir al inicio si presiona retroceso
        Navigator.of(context).popUntil((route) => route.isFirst);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 243, 248, 255),
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(context),
            ),
            SliverToBoxAdapter(
              child: _buildProgressIndicator(),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildFormCard(),
                  const SizedBox(height: 20),
                  _buildImagenSection(),
                  const SizedBox(height: 20),
                  _buildNavigationButtons(),
                  const SizedBox(height: 20),
                  _buildInfoNote(),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          // ✅ SIEMPRE ir al inicio
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(0, 255, 255, 255),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(0, 255, 255, 255)
                                    .withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF940016),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NUEVA ENCOMIENDA',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color.fromARGB(255, 26, 25, 25),
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Código: ${widget.encomiendaData.codigoEnvio}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: primaryBusBlue,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(0, 255, 255, 255)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: Color(0xFF940016),
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'Detalles del Envío',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color.fromARGB(255, 32, 31, 31),
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Información del paquete y fotografía',
                style: TextStyle(
                  fontSize: 14,
                  color: Color.fromARGB(255, 84, 86, 88),
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildStatChip(Icons.inventory_2_rounded, 'Paquete'),
                  const SizedBox(width: 10),
                  _buildStatChip(Icons.camera_alt_rounded, 'Foto Requerida'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accentOrange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accentOrange, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accentOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          _buildStepIndicator(1, 'Remitente', false, true),
          _buildProgressLine(true),
          _buildStepIndicator(2, 'Destinatario', false, true),
          _buildProgressLine(true),
          _buildStepIndicator(3, 'Envío', true, false),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(
      int step, String label, bool isActive, bool isCompleted) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isActive
                  ? primaryBusBlue
                  : isCompleted
                      ? successGreen
                      : Colors.grey.shade300,
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: primaryBusBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(
                      '$step',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? darkNavy : textGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 28),
        color: isCompleted ? successGreen : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: lightBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: accentOrange,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Completa todos los campos requeridos (*)',
                      style: TextStyle(
                        fontSize: 12,
                        color: textGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(
                'Detalles del Paquete', Icons.inventory_2_rounded),
            const SizedBox(height: 16),
            _buildFirebaseDropdown(
              label: 'Tipo de encomienda',
              value: _tipoEncomiendaSeleccionado,
              items: _tiposEncomienda.map((e) => e['tipo'] as String).toList(),
              icon: Icons.category_outlined,
              isRequired: true,
              onChanged: (value) =>
                  setState(() => _tipoEncomiendaSeleccionado = value),
            ),
            if (_isAdmin) ...[
              const SizedBox(height: 16),
              _buildTextField(
                controller: _pesoController,
                label: 'Peso del paquete (kg)',
                hint: 'Ej: 5.5',
                icon: Icons.monitor_weight_outlined,
                isRequired: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _precioTipoController,
                label: 'Precio del tipo de encomienda',
                hint: 'Ej: 25.00',
                icon: Icons.attach_money_outlined,
                isRequired: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
            const SizedBox(height: 16),
            _buildTextField(
              controller: _observacionesController,
              label: 'Observaciones',
              hint: 'Ej: Frágil, no voltear, manejar con cuidado',
              icon: Icons.note_outlined,
              isRequired: false,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagenSection() {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
                'Fotografía del Paquete', Icons.camera_alt_rounded),
            const SizedBox(height: 16),
            _buildImageSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentOrange.withOpacity(0.2),
                accentOrange.withOpacity(0.1)
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: accentOrange, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: darkNavy,
          ),
        ),
      ],
    );
  }

  Widget _buildImageSelector() {
    return GestureDetector(
      onTap: _seleccionarImagen,
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: lightBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _imagenPaquete != null ? successGreen : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: _imagenPaquete != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(_imagenPaquete!.path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: successGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Cambiar foto',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: accentOrange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 48,
                      color: accentOrange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Agregar foto del paquete',
                    style: TextStyle(
                      fontSize: 15,
                      color: darkNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Toca aquí para seleccionar',
                    style: TextStyle(
                      fontSize: 13,
                      color: textGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: accentOrange,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Cámara',
                        style: TextStyle(
                          fontSize: 12,
                          color: accentOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 16),
                      Icon(
                        Icons.photo_library,
                        size: 16,
                        color: successGreen,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Galería',
                        style: TextStyle(
                          fontSize: 12,
                          color: successGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: accentOrange),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: darkNavy,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: warningRed,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          style: const TextStyle(
            fontSize: 14,
            color: darkNavy,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: textGray.withOpacity(0.5),
              fontSize: 13,
            ),
            filled: true,
            fillColor: lightBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: accentOrange, width: 2),
            ),
            counterText: '',
          ),
        ),
      ],
    );
  }

  Widget _buildFirebaseDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    bool isRequired = false,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: accentOrange),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: darkNavy,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: warningRed,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: lightBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(
                'Seleccione una opción',
                style: TextStyle(
                  color: textGray.withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
              icon: const Icon(Icons.arrow_drop_down, color: accentOrange),
              style: const TextStyle(fontSize: 14, color: darkNavy),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF940016), width: 2),
            ),
            child: OutlinedButton(
              onPressed: () {
                // ✅ SIEMPRE ir al inicio
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF940016),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Anterior',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF940016),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF940016), Color(0xFF940016)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF940016).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _guardarYContinuar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Guardar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.save_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentOrange.withOpacity(0.05),
            primaryBusBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentOrange.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.info_rounded,
              color: accentOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Información Importante',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: darkNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isAdmin
                      ? 'Asegúrate de ingresar correctamente el peso y el precio del tipo de encomienda. Estos datos se guardarán en el sistema.'
                      : 'El peso del paquete será determinado en nuestras oficinas. Por favor lleva tu paquete para completar el proceso.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: textGray,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
