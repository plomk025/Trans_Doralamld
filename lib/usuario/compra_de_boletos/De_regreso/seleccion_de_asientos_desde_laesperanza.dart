import 'package:app2tesis/usuario/compra_de_boletos/De_ida/Datos_del_comprador.dart';
import 'package:app2tesis/usuario/compra_de_boletos/De_regreso/Datos_del_comprador_desde_esperanza.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

// ==================== ENUMS Y CONSTANTES ====================
enum EstadoAsiento {
  disponible,
  intentandoReservar,
  reservado,
  pagado,
}

class ColoresAsientos {
  static const Color disponible = Color(0xFFCDD3DD);
  static const Color intentandoReservar = Color(0xFFF4A259);
  static const Color reservado = Color(0xFF1B4965);
  static const Color pagado = Color(0xFF4CAF50);
  static const Color seleccionado = Color(0xFF940016);
}

class LimitesReserva {
  static const int LIMITE_DIARIO_TOTAL =
      4; // Límite combinado de reservas + compras
  static const int MAX_RESERVAS_ACTIVAS =
      4; // Mantener 1 reserva activa a la vez
}

// ==================== PANTALLA PRINCIPAL DE ASIENTOS ====================
class AsientosScreen2 extends StatefulWidget {
  final String busId;
  final String paradaNombre;
  final double paradaPrecio;
  final String userId;

  const AsientosScreen2({
    Key? key,
    required this.busId,
    required this.paradaNombre,
    required this.paradaPrecio,
    required this.userId,
  }) : super(key: key);

  @override
  _AsientosScreen2State createState() => _AsientosScreen2State();
}

class _AsientosScreen2State extends State<AsientosScreen2>
    with SingleTickerProviderStateMixin {
  int? asientoSeleccionado;
  int? asientoSeleccionadoUI;
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  Timer? _heartbeatTimer;
  Timer? _limpiezaTimer;
  StreamSubscription? _reservaSubscription;
  String? userEmail;
  String? currentUserId;
  bool _isLoading = false;
  bool _operacionEnProgreso = false;
  bool _liberacionEnProgreso = false;
  bool _inicializado = false;
  bool _pantallaActiva = true;
  bool _yaVerificado = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const String ADMIN_EMAIL = 'admin@dominio.com';
  static const int TIMEOUT_INTENTANDO_RESERVAR = 300;
  static const int HEARTBEAT_INTERVAL = 10;
  static const int HEARTBEAT_TIMEOUT = 300;
  static const int LIMPIEZA_INTERVAL = 60;

  // Paleta de colores inspirada en transporte de buses
  final Color primaryBusBlue = const Color.fromARGB(255, 243, 248, 255);
  final Color accentOrange = const Color(0xFFEA580C);
  final Color darkNavy = const Color(0xFF0F172A);
  final Color roadGray = const Color(0xFF334155);
  final Color lightBg = const Color(0xFFF1F5F9);
  final Color textGray = const Color(0xFF475569);
  final Color successGreen = const Color(0xFF059669);
  final Color accentBlue = const Color(0xFF1E40AF);
  final Color mainRed = const Color(0xFF940016);

  Map<int, Map<String, dynamic>> _asientosCache = {};
  DateTime? _ultimoError;

  @override
  void initState() {
    super.initState();
    userEmail = auth.currentUser?.email;
    currentUserId = auth.currentUser?.uid;

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

    if (currentUserId == null || currentUserId!.isEmpty) {
      debugPrint('❌ ERROR: No hay usuario autenticado');
    } else {
      debugPrint('✅ Usuario autenticado: $currentUserId');
    }

    _inicializar();
  }

  Future<void> _inicializar() async {
    await _limpiarReservasAbandonadas();
    _iniciarHeartbeat();
    _iniciarLimpiezaPeriodica();
    _escucharCambiosReserva();
  }

  @override
  void dispose() {
    _pantallaActiva = false;
    _fadeController.dispose();
    _limpiarRecursos();
    super.dispose();
  }

  void _limpiarRecursos() {
    _heartbeatTimer?.cancel();
    _limpiezaTimer?.cancel();
    _reservaSubscription?.cancel();
  }

  // ==================== LIMPIEZA PERIÓDICA AUTOMÁTICA ====================
  void _iniciarLimpiezaPeriodica() {
    _limpiezaTimer =
        Timer.periodic(Duration(seconds: LIMPIEZA_INTERVAL), (timer) {
      if (_pantallaActiva) {
        _limpiarAsientosPorTimeout();
      }
    });
  }

  Future<void> _limpiarAsientosPorTimeout() async {
    try {
      final busRef =
          db.collection('buses_la_esperanza_salida').doc(widget.busId);
      final busDoc = await busRef.get();

      if (!busDoc.exists || !_pantallaActiva) return;

      var data = busDoc.data() as Map<String, dynamic>?;
      if (data == null) return;

      List<Map<String, dynamic>> asientos =
          List<Map<String, dynamic>>.from(data['asientos'] ?? []);

      bool huboCambios = false;
      final ahora = Timestamp.now();

      for (int i = 0; i < asientos.length; i++) {
        if (asientos[i]['estado'] == 'intentandoReservar') {
          final timestamp = asientos[i]['timestamp'] as Timestamp?;
          final lastHeartbeat = asientos[i]['lastHeartbeat'] as Timestamp?;
          final emailAsiento = asientos[i]['email'];
          final numeroAsiento = asientos[i]['numero'];

          if (timestamp != null) {
            final diferenciaTimestamp = ahora.seconds - timestamp.seconds;

            if (diferenciaTimestamp > TIMEOUT_INTENTANDO_RESERVAR) {
              debugPrint(
                  '🕐 [TIMEOUT 5min] Asiento $numeroAsiento - Tiempo transcurrido: ${diferenciaTimestamp}s (límite: ${TIMEOUT_INTENTANDO_RESERVAR}s)');

              asientos[i] = {
                'numero': numeroAsiento,
                'estado': 'disponible',
                'email': null,
                'userId': null,
                'timestamp': null,
                'lastHeartbeat': null,
              };
              huboCambios = true;
              debugPrint(
                  '✅ Asiento $numeroAsiento liberado por timeout de 5 minutos (era de: $emailAsiento)');
            } else if (lastHeartbeat != null) {
              final diferenciaHeartbeat = ahora.seconds - lastHeartbeat.seconds;

              if (diferenciaHeartbeat > HEARTBEAT_TIMEOUT) {
                debugPrint(
                    '💓 [HEARTBEAT] Asiento $numeroAsiento - Sin heartbeat por ${diferenciaHeartbeat}s (límite: ${HEARTBEAT_TIMEOUT}s)');

                asientos[i] = {
                  'numero': numeroAsiento,
                  'estado': 'disponible',
                  'email': null,
                  'userId': null,
                  'timestamp': null,
                  'lastHeartbeat': null,
                };
                huboCambios = true;
                debugPrint(
                    '✅ Asiento $numeroAsiento liberado por falta de heartbeat (era de: $emailAsiento)');
              } else {
                debugPrint(
                    '✓ Asiento $numeroAsiento OK - Tiempo: ${diferenciaTimestamp}s/${TIMEOUT_INTENTANDO_RESERVAR}s, Heartbeat: ${diferenciaHeartbeat}s/${HEARTBEAT_TIMEOUT}s');
              }
            }
          }
        }
      }

      if (huboCambios) {
        await busRef.update({'asientos': asientos});
        debugPrint('✅ Limpieza periódica completada - Cambios aplicados');
      }
    } catch (e) {
      debugPrint('❌ Error en limpieza periódica: $e');
    }
  }

  // ==================== LIMPIEZA DE RESERVAS ABANDONADAS ====================
  Future<void> _limpiarReservasAbandonadas() async {
    if (userEmail == null) return;

    setState(() => _isLoading = true);

    try {
      final busRef =
          db.collection('buses_la_esperanza_salida').doc(widget.busId);
      final busDoc = await busRef.get();

      if (!busDoc.exists) return;

      var data = busDoc.data() as Map<String, dynamic>?;
      if (data == null) return;

      List<Map<String, dynamic>> asientos =
          List<Map<String, dynamic>>.from(data['asientos'] ?? []);

      bool huboCambios = false;
      final ahora = Timestamp.now();

      for (int i = 0; i < asientos.length; i++) {
        if (asientos[i]['estado'] == 'intentandoReservar') {
          final timestamp = asientos[i]['timestamp'] as Timestamp?;
          final lastHeartbeat = asientos[i]['lastHeartbeat'] as Timestamp?;
          final emailAsiento = asientos[i]['email'];
          final numeroAsiento = asientos[i]['numero'];

          if (timestamp != null) {
            final diferenciaTimestamp = ahora.seconds - timestamp.seconds;

            if (diferenciaTimestamp > TIMEOUT_INTENTANDO_RESERVAR) {
              debugPrint(
                  '🧹 [LIMPIEZA INICIAL] Asiento $numeroAsiento excedió 5 minutos (${diferenciaTimestamp}s)');

              asientos[i] = {
                'numero': numeroAsiento,
                'estado': 'disponible',
                'email': null,
                'userId': null,
                'timestamp': null,
                'lastHeartbeat': null,
              };
              huboCambios = true;
              debugPrint(
                  '✅ Limpiado asiento $numeroAsiento por timeout de 5 minutos (era de: $emailAsiento)');
            } else if (emailAsiento == userEmail && lastHeartbeat != null) {
              final diferenciaHeartbeat = ahora.seconds - lastHeartbeat.seconds;

              if (diferenciaHeartbeat > HEARTBEAT_TIMEOUT) {
                debugPrint(
                    '🧹 [LIMPIEZA INICIAL] Asiento $numeroAsiento del usuario sin heartbeat (${diferenciaHeartbeat}s)');

                asientos[i] = {
                  'numero': numeroAsiento,
                  'estado': 'disponible',
                  'email': null,
                  'userId': null,
                  'timestamp': null,
                  'lastHeartbeat': null,
                };
                huboCambios = true;
                debugPrint(
                    '✅ Limpiado asiento $numeroAsiento del usuario actual (sin heartbeat)');
              }
            }
          }
        }
      }

      if (huboCambios) {
        await busRef.update({'asientos': asientos});
        await Future.delayed(const Duration(milliseconds: 300));
        debugPrint('✅ Limpieza inicial completada');
      }

      if (userEmail != ADMIN_EMAIL) {
        await _verificarLimiteCompras();
      }
    } catch (e) {
      debugPrint('❌ Error al limpiar reservas: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==================== VERIFICACIÓN DE LÍMITES ====================
  Future<Map<String, int>> _contarBoletosUsuario() async {
    if (userEmail == null || userEmail == ADMIN_EMAIL) {
      return {'reservados': 0, 'comprados': 0, 'total': 0};
    }

    try {
      final hoy = DateTime.now();
      final inicioDelDia = DateTime(hoy.year, hoy.month, hoy.day, 0, 0, 0);
      final finDelDia = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59);

      int reservadosHoy = 0;
      int compradosHoy = 0;

      final reservasSnapshot = await db
          .collection('reservas')
          .where('email', isEqualTo: userEmail)
          .get();

      for (var doc in reservasSnapshot.docs) {
        final data = doc.data();
        final fechaReserva = data['fechaReserva'] as Timestamp?;

        if (fechaReserva != null) {
          final fecha = fechaReserva.toDate();
          if (fecha.isAfter(inicioDelDia) && fecha.isBefore(finDelDia)) {
            final asientos = data['asientos'] as List?;
            if (asientos != null) {
              reservadosHoy += asientos.length;
            } else {
              reservadosHoy += 1;
            }
          }
        }
      }

      final compradosSnapshot = await db
          .collection('comprados')
          .where('email', isEqualTo: userEmail)
          .get();

      for (var doc in compradosSnapshot.docs) {
        final data = doc.data();
        final fechaCompra = data['fechaCompra'] as Timestamp?;

        if (fechaCompra != null) {
          final fecha = fechaCompra.toDate();
          if (fecha.isAfter(inicioDelDia) && fecha.isBefore(finDelDia)) {
            final asientos = data['asientos'] as List?;
            if (asientos != null) {
              compradosHoy += asientos.length;
            } else {
              compradosHoy += 1;
            }
          }
        }
      }

      final busDoc = await db
          .collection('buses_la_esperanza_salida')
          .doc(widget.busId)
          .get();
      if (busDoc.exists) {
        var busData = busDoc.data() as Map<String, dynamic>?;
        List<Map<String, dynamic>> asientos =
            List<Map<String, dynamic>>.from(busData?['asientos'] ?? []);

        for (var asiento in asientos) {
          if (asiento['email'] == userEmail &&
              (asiento['estado'] == 'reservado')) {
            final timestamp = asiento['timestamp'] as Timestamp?;
            if (timestamp != null) {
              final fecha = timestamp.toDate();
              if (fecha.isAfter(inicioDelDia) && fecha.isBefore(finDelDia)) {
                bool yaContado = false;
                for (var doc in reservasSnapshot.docs) {
                  final data = doc.data();
                  final asientosReserva = data['asientos'] as List?;
                  if (asientosReserva != null) {
                    for (var a in asientosReserva) {
                      if (a['numero'] == asiento['numero']) {
                        yaContado = true;
                        break;
                      }
                    }
                  }
                  if (yaContado) break;
                }

                if (!yaContado) {
                  reservadosHoy += 1;
                }
              }
            }
          }
        }
      }

      final totalHoy = reservadosHoy + compradosHoy;

      debugPrint(
          '📊 Conteo del día: Reservados=$reservadosHoy, Comprados=$compradosHoy, Total=$totalHoy');

      return {
        'reservados': reservadosHoy,
        'comprados': compradosHoy,
        'total': totalHoy,
      };
    } catch (e) {
      debugPrint('❌ Error al contar boletos: $e');
      return {'reservados': 0, 'comprados': 0, 'total': 0};
    }
  }

  Future<void> _verificarLimiteCompras() async {
    if (userEmail == null || userEmail == ADMIN_EMAIL || _yaVerificado) return;

    _yaVerificado = true;

    try {
      final conteo = await _contarBoletosUsuario();
      final totalHoy = conteo['total'] ?? 0;
      final reservadosHoy = conteo['reservados'] ?? 0;
      final compradosHoy = conteo['comprados'] ?? 0;

      if (totalHoy >= LimitesReserva.LIMITE_DIARIO_TOTAL) {
        String detalle = '';
        if (reservadosHoy > 0 && compradosHoy > 0) {
          detalle =
              'Tienes $reservadosHoy reservado(s) y $compradosHoy pagado(s) hoy.';
        } else if (reservadosHoy > 0) {
          detalle = 'Tienes $reservadosHoy asiento(s) reservado(s) hoy.';
        } else {
          detalle = 'Ya compraste $compradosHoy boleto(s) hoy.';
        }

        _mostrarDialogoLimite(
          'Límite Diario Alcanzado',
          'Ha alcanzado el límite de ${LimitesReserva.LIMITE_DIARIO_TOTAL} boletos por día (reservados + pagados). $detalle\n\nPodrá realizar nuevas reservas/compras mañana a partir de las 00:00.',
        );
      } else if (totalHoy == LimitesReserva.LIMITE_DIARIO_TOTAL - 1) {
        debugPrint(
            '⚠️ Usuario tiene $totalHoy boleto(s) hoy, puede reservar ${LimitesReserva.LIMITE_DIARIO_TOTAL - totalHoy} más');
      }
    } catch (e) {
      debugPrint('❌ Error al verificar límite: $e');
    }
  }

  void _mostrarDialogoLimite(String titulo, String mensaje) {
    if (!mounted || !_pantallaActiva) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info_outline,
                    color: Color(0xFFF59E0B), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: darkNavy),
                ),
              ),
            ],
          ),
          content: Text(
            mensaje,
            style: TextStyle(fontSize: 14, color: textGray, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                backgroundColor: mainRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Entendido',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarError(String mensaje) {
    if (!mounted || !_pantallaActiva) return;

    final ahora = DateTime.now();
    if (_ultimoError != null && ahora.difference(_ultimoError!).inSeconds < 3) {
      return;
    }
    _ultimoError = ahora;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(mensaje, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF59E0B),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ==================== HEARTBEAT ====================
  void _iniciarHeartbeat() {
    _heartbeatTimer =
        Timer.periodic(Duration(seconds: HEARTBEAT_INTERVAL), (timer) {
      if (_pantallaActiva &&
          asientoSeleccionado != null &&
          !_liberacionEnProgreso) {
        _actualizarHeartbeat();
      }
    });
  }

  Future<void> _actualizarHeartbeat() async {
    if (asientoSeleccionado == null ||
        userEmail == null ||
        _liberacionEnProgreso ||
        !_pantallaActiva) {
      return;
    }

    try {
      final busRef =
          db.collection('buses_la_esperanza_salida').doc(widget.busId);
      final busDoc = await busRef.get();

      if (!busDoc.exists || !_pantallaActiva) return;

      var data = busDoc.data() as Map<String, dynamic>?;
      if (data == null) return;

      List<Map<String, dynamic>> asientos =
          List<Map<String, dynamic>>.from(data['asientos'] ?? []);

      final index =
          asientos.indexWhere((a) => a['numero'] == asientoSeleccionado);

      if (index != -1 &&
          asientos[index]['email'] == userEmail &&
          asientos[index]['estado'] == 'intentandoReservar') {
        final timestamp = asientos[index]['timestamp'] as Timestamp?;
        if (timestamp != null) {
          final ahora = Timestamp.now();
          final diferencia = ahora.seconds - timestamp.seconds;

          debugPrint(
              '💓 [HEARTBEAT] Asiento $asientoSeleccionado - Tiempo: ${diferencia}s/${TIMEOUT_INTENTANDO_RESERVAR}s');

          if (diferencia > TIMEOUT_INTENTANDO_RESERVAR) {
            debugPrint(
                '⏰ Asiento $asientoSeleccionado excedió 5 minutos, liberando...');
            if (mounted && _pantallaActiva) {
              setState(() {
                asientoSeleccionado = null;
                asientoSeleccionadoUI = null;
              });
              _mostrarError('Tu reserva expiró después de 5 minutos');
            }
            return;
          }
        }

        asientos[index]['lastHeartbeat'] = Timestamp.now();
        await busRef.update({'asientos': asientos});
        debugPrint('✅ Heartbeat actualizado para asiento $asientoSeleccionado');
      }
    } catch (e) {
      debugPrint('❌ Error en heartbeat: $e');
    }
  }

  void _escucharCambiosReserva() {
    _reservaSubscription = db
        .collection('buses_la_esperanza_salida')
        .doc(widget.busId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted || _operacionEnProgreso || !_pantallaActiva) return;

      var data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return;

      List<Map<String, dynamic>> asientos =
          List<Map<String, dynamic>>.from(data['asientos'] ?? []);

      bool hayaCambios = false;
      for (var asiento in asientos) {
        int numero = asiento['numero'];
        var asientoCached = _asientosCache[numero];

        if (asientoCached == null ||
            asientoCached['estado'] != asiento['estado'] ||
            asientoCached['email'] != asiento['email']) {
          hayaCambios = true;
          _asientosCache[numero] = Map<String, dynamic>.from(asiento);
        }
      }

      if (!hayaCambios && _inicializado) return;

      if (asientoSeleccionado != null && _inicializado) {
        var asiento = asientos.firstWhere(
          (a) => a['numero'] == asientoSeleccionado,
          orElse: () => {},
        );

        if (asiento.isNotEmpty &&
            asiento['email'] != null &&
            asiento['email'] != userEmail) {
          if (mounted && _pantallaActiva) {
            setState(() {
              asientoSeleccionado = null;
              asientoSeleccionadoUI = null;
            });
            _mostrarError('El asiento fue tomado por otro usuario');
          }
        }
      }

      if (mounted && _pantallaActiva && (_inicializado || hayaCambios)) {
        setState(() {});
      }

      _inicializado = true;
    });
  }

  // ==================== GESTIÓN DE ASIENTOS ====================
  Future<void> _liberarAsientoTemporal() async {
    if (asientoSeleccionado == null ||
        userEmail == null ||
        _liberacionEnProgreso) {
      return;
    }

    _liberacionEnProgreso = true;
    debugPrint('🔓 Liberando asiento $asientoSeleccionado...');

    try {
      final busRef =
          db.collection('buses_la_esperanza_salida').doc(widget.busId);
      final busDoc = await busRef.get();

      if (!busDoc.exists) {
        _liberacionEnProgreso = false;
        return;
      }

      var data = busDoc.data() as Map<String, dynamic>?;
      if (data == null) {
        _liberacionEnProgreso = false;
        return;
      }

      List<Map<String, dynamic>> asientos =
          List<Map<String, dynamic>>.from(data['asientos'] ?? []);

      final index =
          asientos.indexWhere((a) => a['numero'] == asientoSeleccionado);

      if (index != -1 &&
          asientos[index]['email'] == userEmail &&
          asientos[index]['estado'] == 'intentandoReservar') {
        asientos[index] = {
          'numero': asientoSeleccionado,
          'estado': 'disponible',
          'email': null,
          'userId': null,
          'timestamp': null,
          'lastHeartbeat': null,
        };

        await busRef.update({'asientos': asientos});
        await Future.delayed(const Duration(milliseconds: 200));
        debugPrint('✅ Asiento $asientoSeleccionado liberado correctamente');
      }
    } catch (e) {
      debugPrint('❌ Error al liberar asiento: $e');
    } finally {
      _liberacionEnProgreso = false;
      if (mounted) {
        setState(() {
          asientoSeleccionado = null;
          asientoSeleccionadoUI = null;
        });
      }
    }
  }

  Future<bool> _verificarPuedeReservar(int numeroAsientoIntentando) async {
    if (userEmail == null) return false;
    if (userEmail == ADMIN_EMAIL) return true;

    try {
      final conteo = await _contarBoletosUsuario();
      final totalHoy = conteo['total'] ?? 0;
      final reservadosHoy = conteo['reservados'] ?? 0;
      final compradosHoy = conteo['comprados'] ?? 0;

      debugPrint(
          '🔍 Verificando si puede reservar asiento $numeroAsientoIntentando');
      debugPrint(
          '   Total hoy: $totalHoy (Reservados: $reservadosHoy, Comprados: $compradosHoy)');

      // Verificar límite diario total
      if (totalHoy >= LimitesReserva.LIMITE_DIARIO_TOTAL) {
        if (_pantallaActiva) {
          String mensaje = '';
          if (reservadosHoy > 0 && compradosHoy > 0) {
            mensaje =
                'Tienes $reservadosHoy reservado(s) y $compradosHoy comprado(s) hoy';
          } else if (reservadosHoy >= LimitesReserva.LIMITE_DIARIO_TOTAL) {
            mensaje =
                'Ya tienes ${LimitesReserva.LIMITE_DIARIO_TOTAL} asientos reservados hoy';
          } else if (compradosHoy >= LimitesReserva.LIMITE_DIARIO_TOTAL) {
            mensaje =
                'Ya compraste ${LimitesReserva.LIMITE_DIARIO_TOTAL} boletos hoy';
          } else {
            mensaje =
                'Límite alcanzado: $reservadosHoy reservado(s) + $compradosHoy comprado(s)';
          }
          _mostrarError(
              '$mensaje (máximo ${LimitesReserva.LIMITE_DIARIO_TOTAL}/día)');
        }
        return false;
      }

      // Verificar límite de reservas activas simultáneas
      final busDoc = await db
          .collection('buses_la_esperanza_salida')
          .doc(widget.busId)
          .get();
      if (busDoc.exists) {
        var data = busDoc.data() as Map<String, dynamic>?;
        List<Map<String, dynamic>> asientos =
            List<Map<String, dynamic>>.from(data?['asientos'] ?? []);

        final reservasActivas = asientos
            .where((a) =>
                a['numero'] != numeroAsientoIntentando &&
                a['email'] == userEmail &&
                (a['estado'] == 'intentandoReservar' ||
                    a['estado'] == 'reservado'))
            .length;

        if (reservasActivas >= LimitesReserva.MAX_RESERVAS_ACTIVAS) {
          if (_pantallaActiva) {
            _mostrarError(
                'Solo puedes tener ${LimitesReserva.MAX_RESERVAS_ACTIVAS} reserva activa a la vez');
          }
          return false;
        }
      }

      debugPrint(
          '✅ Puede reservar: tiene ${LimitesReserva.LIMITE_DIARIO_TOTAL - totalHoy} boleto(s) disponible(s) del límite diario');
      return true;
    } catch (e) {
      debugPrint('❌ Error al verificar si puede reservar: $e');
      return false;
    }
  }

  Future<void> _seleccionarAsiento(int numero) async {
    if (_operacionEnProgreso || userEmail == null || !_pantallaActiva) return;

    setState(() {
      asientoSeleccionadoUI = numero;
      _operacionEnProgreso = true;
    });

    try {
      if (asientoSeleccionado == numero) {
        await _liberarAsientoTemporal();
        if (mounted && _pantallaActiva) {
          setState(() {
            asientoSeleccionado = null;
            asientoSeleccionadoUI = null;
          });
        }
        return;
      }

      if (asientoSeleccionado != null && asientoSeleccionado != numero) {
        await _liberarAsientoTemporal();
        await Future.delayed(const Duration(milliseconds: 250));
      }

      final puedeReservar = await _verificarPuedeReservar(numero);
      if (!puedeReservar) {
        if (mounted && _pantallaActiva) {
          setState(() {
            asientoSeleccionadoUI = null;
            asientoSeleccionado = null;
          });
        }
        return;
      }

      final exito = await _marcarAsientoComoIntentandoReservar(numero);

      if (mounted && _pantallaActiva) {
        if (exito) {
          setState(() {
            asientoSeleccionado = numero;
            asientoSeleccionadoUI = numero;
          });
          debugPrint(
              '✅ Asiento $numero seleccionado - Tienes 5 minutos para completar la compra');
        } else {
          setState(() {
            asientoSeleccionadoUI = null;
            asientoSeleccionado = null;
          });
          _mostrarError('Asiento no disponible, intente otro');
        }
      }
    } catch (e) {
      debugPrint('❌ Error al seleccionar asiento: $e');
      if (mounted && _pantallaActiva) {
        setState(() {
          asientoSeleccionadoUI = null;
          asientoSeleccionado = null;
        });
      }
    } finally {
      if (mounted && _pantallaActiva) {
        setState(() => _operacionEnProgreso = false);
      }
    }
  }

  Future<bool> _marcarAsientoComoIntentandoReservar(int numero) async {
    if (userEmail == null || currentUserId == null) {
      debugPrint('❌ No hay usuario autenticado');
      return false;
    }

    try {
      final busRef =
          db.collection('buses_la_esperanza_salida').doc(widget.busId);
      final busDoc = await busRef.get();

      if (!busDoc.exists) return false;

      var data = busDoc.data() as Map<String, dynamic>?;
      if (data == null) return false;

      List<Map<String, dynamic>> asientos =
          List<Map<String, dynamic>>.from(data['asientos'] ?? []);

      final index = asientos.indexWhere((a) => a['numero'] == numero);
      if (index == -1) return false;

      // CORRECCIÓN: Verificar primero si es tuyo antes de rechazar
      final estadoActual = asientos[index]['estado'];
      final emailActual = asientos[index]['email'];

      debugPrint('🔍 Verificando asiento $numero:');
      debugPrint('   Estado: $estadoActual');
      debugPrint('   Email actual: $emailActual');
      debugPrint('   Tu email: $userEmail');

      // Si NO está disponible Y NO es tuyo, rechazar
      if (estadoActual != 'disponible' && emailActual != userEmail) {
        debugPrint('❌ Asiento no disponible y no es tuyo');
        return false;
      }

      // Verificar límite de reservas activas (solo si no es admin)
      if (userEmail != ADMIN_EMAIL) {
        final otrasReservas = asientos
            .where((a) =>
                a['numero'] != numero &&
                a['email'] == userEmail &&
                (a['estado'] == 'intentandoReservar' ||
                    a['estado'] == 'reservado'))
            .length;

        if (otrasReservas >= LimitesReserva.MAX_RESERVAS_ACTIVAS) {
          debugPrint(
              '❌ Ya tienes ${LimitesReserva.MAX_RESERVAS_ACTIVAS} reserva(s) activa(s)');
          return false;
        }
      }

      final ahora = Timestamp.now();

      asientos[index] = {
        'numero': numero,
        'estado': 'intentandoReservar',
        'email': userEmail,
        'userId': currentUserId,
        'timestamp': ahora,
        'lastHeartbeat': ahora,
        'paradaNombre': widget.paradaNombre,
        'precio': widget.paradaPrecio,
      };

      await busRef.update({'asientos': asientos});
      debugPrint(
          '✅ Asiento $numero marcado como intentandoReservar con userId: $currentUserId');
      debugPrint(
          '⏱️  Timestamp inicial: ${ahora.seconds} - Expira en ${TIMEOUT_INTENTANDO_RESERVAR}s');
      return true;
    } catch (e) {
      debugPrint('❌ Error al marcar asiento: $e');
      return false;
    }
  }

  EstadoAsiento _obtenerEstadoAsiento(Map<String, dynamic> asiento) {
    String estado = asiento['estado'] ?? 'disponible';
    switch (estado) {
      case 'intentandoReservar':
        return EstadoAsiento.intentandoReservar;
      case 'reservado':
        return EstadoAsiento.reservado;
      case 'pagado':
        return EstadoAsiento.pagado;
      default:
        return EstadoAsiento.disponible;
    }
  }

  Color _obtenerColorAsiento(
      EstadoAsiento estado, bool seleccionado, bool esMio) {
    if (seleccionado && esMio) return ColoresAsientos.seleccionado;

    switch (estado) {
      case EstadoAsiento.disponible:
        return ColoresAsientos.disponible;
      case EstadoAsiento.intentandoReservar:
        return esMio
            ? ColoresAsientos.seleccionado
            : ColoresAsientos.intentandoReservar;
      case EstadoAsiento.reservado:
        return ColoresAsientos.reservado;
      case EstadoAsiento.pagado:
        return ColoresAsientos.pagado;
    }
  }

  // ==================== UI ====================
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _pantallaActiva = false;
        ScaffoldMessenger.of(context).clearSnackBars();

        if (asientoSeleccionado != null) {
          await _liberarAsientoTemporal();
        }

        return true;
      },
      child: Scaffold(
        backgroundColor: primaryBusBlue,
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(mainRed),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Cargando asientos disponibles...',
                      style: TextStyle(
                        fontSize: 14,
                        color: textGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            : StreamBuilder<DocumentSnapshot>(
                stream: db
                    .collection('buses_la_esperanza_salida')
                    .doc(widget.busId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !_inicializado) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(mainRed),
                      ),
                    );
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(
                        child: Text('No se encontró información del bus'));
                  }

                  var bus = snapshot.data!;
                  var data = bus.data() as Map<String, dynamic>?;

                  if (data == null || !data.containsKey('asientos')) {
                    return const Center(
                        child: Text('No hay asientos disponibles'));
                  }

                  List<Map<String, dynamic>> asientos = [];
                  try {
                    asientos =
                        List<Map<String, dynamic>>.from(data['asientos']);
                  } catch (e) {
                    return const Center(
                        child: Text('Error al cargar asientos'));
                  }

                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      _buildHeader(),
                      _buildInfoCard(),
                      _buildLeyenda(),
                      _buildAsientosSection(asientos),
                      SliverToBoxAdapter(
                        child: SizedBox(
                            height:
                                MediaQuery.of(context).padding.bottom + 100),
                      ),
                    ],
                  );
                },
              ),
        bottomNavigationBar: _buildBottomBar(),
      ),
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
                          // Reemplaza el botón de retroceso en _buildHeader() con este código:

                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              // Liberar asiento si hay uno seleccionado
                              if (asientoSeleccionado != null) {
                                await _liberarAsientoTemporal();
                              }

                              // Regresar a la pantalla anterior
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(0, 252, 252, 252),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        const Color.fromARGB(0, 247, 244, 244)
                                            .withOpacity(0.1),
                                    blurRadius: 10,
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
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SELECCIÓN DE ASIENTO',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color.fromARGB(255, 36, 35, 35),
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                'Elige tu asiento',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Color.fromARGB(255, 38, 38, 39),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(0, 255, 255, 255),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(0, 226, 226, 226)
                                    .withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.event_seat_rounded,
                            color: Color(0xFF940016),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Selecciona tu Asiento',
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
                      'Toca un asiento disponible para reservarlo',
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

  Widget _buildInfoCard() {
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: accentBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: accentBlue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.paradaNombre,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: darkNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Destino seleccionado',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: accentBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.attach_money_rounded,
                        color: Color(0xFF059669),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.paradaPrecio.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'USD por asiento',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: successGreen.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (userEmail != ADMIN_EMAIL) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFFF59E0B).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 16, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Máximo 1 reserva activa • 4 boletos por día • Válida por 5 minutos',
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFFF59E0B),
                              fontWeight: FontWeight.w600,
                            ),
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

  Widget _buildLeyenda() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leyenda de Estados',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: darkNavy,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLeyendaItem(ColoresAsientos.disponible, 'Disponible',
                        Icons.event_seat_rounded),
                    _buildLeyendaItem(ColoresAsientos.intentandoReservar,
                        'En proceso', Icons.access_time_rounded),
                    _buildLeyendaItem(ColoresAsientos.reservado, 'Reservado',
                        Icons.lock_outline_rounded),
                    _buildLeyendaItem(ColoresAsientos.pagado, 'Pagado',
                        Icons.check_circle_outline_rounded),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeyendaItem(Color color, String texto, IconData icon) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          texto,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textGray,
          ),
        ),
      ],
    );
  }

  Widget _buildAsientosSection(List<Map<String, dynamic>> asientos) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            padding: const EdgeInsets.all(20),
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
            child: Column(
              children: [
                // Indicador del conductor
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: mainRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: mainRed.withOpacity(0.3), width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_bus, color: mainRed, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'Conductor',
                        style: TextStyle(
                          color: mainRed,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                // Grid de asientos
                _buildAsientosLayout(asientos),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAsientosLayout(List<Map<String, dynamic>> asientos) {
    final totalAsientos = asientos.length;

    // Configuración según el total de asientos (común en buses reales)
    int asientosNormales;
    int asientosFilaTrasera;

    if (totalAsientos <= 20) {
      // Bus pequeño: 16 normales + 4 traseros = 20
      asientosNormales = totalAsientos - 4;
      asientosFilaTrasera = 4;
    } else if (totalAsientos <= 30) {
      // Bus mediano: 24-26 normales + 4-5 traseros = 28-30
      // Si es par, 4 traseros; si es impar, 5 traseros
      asientosFilaTrasera = totalAsientos % 2 == 0 ? 4 : 5;
      asientosNormales = totalAsientos - asientosFilaTrasera;
    } else if (totalAsientos <= 40) {
      // Bus grande: 32-36 normales + 4-5 traseros = 36-40
      asientosFilaTrasera = totalAsientos % 2 == 0 ? 4 : 5;
      asientosNormales = totalAsientos - asientosFilaTrasera;
    } else {
      // Bus extra grande: más de 40 asientos
      asientosFilaTrasera = 6;
      asientosNormales = totalAsientos - asientosFilaTrasera;
    }

    // Asegurarse de que no haya números negativos
    if (asientosNormales < 0) {
      asientosNormales = totalAsientos;
      asientosFilaTrasera = 0;
    }

    final asientosEnFilaNormal = 4; // Siempre 2-2 (estándar en buses)
    final filasNormales = (asientosNormales / asientosEnFilaNormal).ceil();
    final tieneFilaTrasera = asientosFilaTrasera > 0;

    return Column(
      children: [
        // Filas normales (4 asientos por fila: 2-2)
        ...List.generate(filasNormales, (rowIndex) {
          final startIndex = rowIndex * 4;
          final endIndex = (startIndex + 4).clamp(0, asientosNormales);
          final asientosEnFila = asientos.sublist(startIndex, endIndex);

          // Si es la última fila y tiene menos de 4 asientos, centrarlos
          final esUltimaFila = rowIndex == filasNormales - 1;
          final asientosFaltantes = 4 - asientosEnFila.length;
          final centrar = esUltimaFila && asientosFaltantes > 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                // Lado izquierdo (2 asientos)
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      if (asientosEnFila.length > 0)
                        Expanded(child: _buildAsiento(asientosEnFila[0]))
                      else if (centrar)
                        Expanded(child: SizedBox()),
                      const SizedBox(width: 8),
                      if (asientosEnFila.length > 1)
                        Expanded(child: _buildAsiento(asientosEnFila[1]))
                      else if (centrar)
                        Expanded(child: SizedBox()),
                    ],
                  ),
                ),
                // Pasillo central
                const SizedBox(width: 60),
                // Lado derecho (2 asientos)
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      if (asientosEnFila.length > 2)
                        Expanded(child: _buildAsiento(asientosEnFila[2]))
                      else if (centrar)
                        Expanded(child: SizedBox()),
                      const SizedBox(width: 8),
                      if (asientosEnFila.length > 3)
                        Expanded(child: _buildAsiento(asientosEnFila[3]))
                      else if (centrar)
                        Expanded(child: SizedBox()),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        // Fila trasera (4 o 5 asientos según corresponda)
        if (tieneFilaTrasera) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  textGray.withOpacity(0.05),
                  textGray.withOpacity(0.08),
                ],
              ),
              border: Border.all(
                color: textGray.withOpacity(0.25),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.airline_seat_recline_normal_rounded,
                      size: 14,
                      color: textGray.withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Fila Trasera',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textGray.withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Mostrar asientos traseros
                Row(
                  children: List.generate(
                    asientosFilaTrasera.clamp(
                        0, totalAsientos - asientosNormales),
                    (index) {
                      final asientoIndex = asientosNormales + index;
                      if (asientoIndex >= totalAsientos) {
                        return Expanded(child: SizedBox());
                      }
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: asientosFilaTrasera == 5 ? 2 : 4,
                          ),
                          child: _buildAsiento(asientos[asientoIndex]),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAsiento(Map<String, dynamic> asiento) {
    final numero = asiento['numero'] ?? 0;
    final estado = _obtenerEstadoAsiento(asiento);
    final email = asiento['email'];
    final esMio = email == userEmail;
    final seleccionado = asientoSeleccionadoUI == numero;
    final puedeSeleccionar = estado == EstadoAsiento.disponible ||
        (estado == EstadoAsiento.intentandoReservar && esMio);

    return GestureDetector(
      onTap: puedeSeleccionar ? () => _seleccionarAsiento(numero) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 60,
        decoration: BoxDecoration(
          color: _obtenerColorAsiento(estado, seleccionado, esMio),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado && esMio ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(seleccionado ? 0.15 : 0.08),
              blurRadius: seleccionado ? 8 : 4,
              offset: Offset(0, seleccionado ? 3 : 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              estado == EstadoAsiento.pagado
                  ? Icons.check_circle_rounded
                  : estado == EstadoAsiento.reservado
                      ? Icons.lock_rounded
                      : Icons.event_seat_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              numero.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final total = asientoSeleccionadoUI != null ? widget.paradaPrecio : 0.0;
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (asientoSeleccionadoUI != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: ColoresAsientos.seleccionado.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ColoresAsientos.seleccionado.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ColoresAsientos.seleccionado,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.event_seat_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Asiento seleccionado',
                            style: TextStyle(
                              fontSize: 11,
                              color: textGray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Número $asientoSeleccionadoUI',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: darkNavy,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF059669),
                      size: 26,
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total a pagar',
                        style: TextStyle(
                          fontSize: 12,
                          color: textGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${widget.paradaPrecio.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: darkNavy,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: asientoSeleccionadoUI == null
                          ? Colors.grey[300]
                          : mainRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: asientoSeleccionadoUI == null ? 0 : 2,
                      shadowColor: mainRed.withOpacity(0.3),
                    ),
                    // Busca esta línea en el método _buildBottomBar() (alrededor de la línea 1070)
                    onPressed: (asientoSeleccionadoUI == null ||
                            _operacionEnProgreso)
                        ? null
                        : () async {
                            final puedeReservar = await _verificarPuedeReservar(
                                asientoSeleccionadoUI!);
                            if (!puedeReservar) {
                              await _liberarAsientoTemporal();
                              return;
                            }

                            if (!mounted || !_pantallaActiva) return;

                            ScaffoldMessenger.of(context).clearSnackBars();

                            _heartbeatTimer?.cancel();
                            _limpiezaTimer?.cancel();
                            _reservaSubscription?.cancel();
                            _pantallaActiva = false;

                            debugPrint(
                                '⏳ Navegando a siguiente pantalla - Asiento $asientoSeleccionadoUI permanece en intentandoReservar');

                            final resultado = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DatosCompradorScreen(
                                  busId: widget.busId,
                                  asientoSeleccionado: asientoSeleccionadoUI!,
                                  total: total,
                                  userId: currentUserId ?? '',
                                  paradaNombre: widget.paradaNombre,
                                  userEmail: userEmail ?? '',
                                ),
                              ),
                            );

                            _pantallaActiva = true;

                            if (mounted) {
                              if (resultado == true) {
                                debugPrint('✅ Compra completada exitosamente');
                                // ✅ LIMPIAR SELECCIÓN DESPUÉS DE COMPRA EXITOSA
                                setState(() {
                                  asientoSeleccionado = null;
                                  asientoSeleccionadoUI = null;
                                });
                              } else {
                                debugPrint(
                                    '⚠️ Usuario regresó sin completar - Asiento expirará en ${TIMEOUT_INTENTANDO_RESERVAR}s desde timestamp');
                              }

                              // Reiniciar listeners en ambos casos
                              _iniciarHeartbeat();
                              _iniciarLimpiezaPeriodica();
                              _escucharCambiosReserva();
                            }
                          },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Continuar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (asientoSeleccionadoUI == null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app_rounded, size: 16, color: textGray),
                    const SizedBox(width: 8),
                    Text(
                      'Selecciona un asiento para continuar',
                      style: TextStyle(
                        fontSize: 12,
                        color: textGray,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
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
}
