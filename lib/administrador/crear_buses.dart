import 'package:app2tesis/usuario/Pantallas_inicio/iniciarsesion.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class CrearBusScreen extends StatefulWidget {
  @override
  _CrearBusScreenState createState() => _CrearBusScreenState();
}

class _CrearBusScreenState extends State<CrearBusScreen> {
  final _formKey = GlobalKey<FormState>();

  // Variables para los selectores
  String? _numeroSeleccionado;
  String? _placaSeleccionada;
  String? _capacidadSeleccionada;
  String? _choferSeleccionado;
  String? _lugarSeleccionado;
  DateTime? _fechaSalida;
  TimeOfDay? _horaSalida;

  String _normalizarTexto(String texto) {
    return texto
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .trim();
  }

  // Listas para las opciones
  List<Map<String, dynamic>> _buses = [];
  List<String> _lugares = [];

  final db = FirebaseFirestore.instance;

  // Paleta de colores moderna
  static const Color primaryBusBlue = Color(0xFF940016);
  static const Color accentOrange = Color(0xFFEA580C);
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color roadGray = Color(0xFF334155);
  static const Color lightBg = Color(0xFFF1F5F9);
  static const Color textGray = Color(0xFF475569);
  static const Color successGreen = Color(0xFF059669);
  static const Color accentRed = Color(0xFFEF4444);

  bool _mostrandoFormularioCrear = false;
  String? _fechaExpandida;
  bool _cargandoDatos = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null);
    _cargarOpcionesDesdeFirebase();
  }

  // ========================
  // 🔹 CARGAR OPCIONES DESDE FIREBASE
  // ========================
  Future<void> _cargarOpcionesDesdeFirebase() async {
    setState(() {
      _cargandoDatos = true;
    });

    try {
      final busesSnapshot =
          await db.collection('conductores_registrados').get();
      _buses = busesSnapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      final lugaresSnapshot = await db.collection('lugares_salida').get();
      _lugares =
          lugaresSnapshot.docs.map((doc) => doc['lugar'].toString()).toList();

      setState(() {
        _cargandoDatos = false;
      });
    } catch (e) {
      print('Error al cargar opciones: $e');
      setState(() {
        _cargandoDatos = false;
      });

      if (mounted) {
        _mostrarSnackBar('Error al cargar opciones: $e', esError: true);
      }
    }
  }

  void _mostrarSnackBar(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              esError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: esError ? accentRed : successGreen,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ========================
  // 🔹 CARGAR DATOS AL SELECCIONAR NÚMERO
  // ========================
  void _cargarDatosBus(String numero) {
    final busEncontrado = _buses.firstWhere(
      (bus) => bus['numero'] == numero,
      orElse: () => {},
    );

    if (busEncontrado.isNotEmpty) {
      setState(() {
        _numeroSeleccionado = numero;
        _placaSeleccionada = busEncontrado['placa'];
        _capacidadSeleccionada = busEncontrado['capacidad'];
        _choferSeleccionado = busEncontrado['chofer'];
      });
    }
  }

  // ========================
  // 🔹 CREAR BUS
  // ========================
  Future<void> crearBus() async {
    if (_formKey.currentState!.validate()) {
      if (_fechaSalida == null || _horaSalida == null) {
        _mostrarSnackBar('Selecciona fecha y hora de salida', esError: true);
        return;
      }

      int capacidad = int.parse(_capacidadSeleccionada!);

      String lugarNormalizado = _normalizarTexto(_lugarSeleccionado!);
      String coleccion = lugarNormalizado == 'tulcan'
          ? 'buses_tulcan_salida'
          : 'buses_la_esperanza_salida';

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryBusBlue),
                  strokeWidth: 3,
                ),
                SizedBox(height: 20),
                Text(
                  'Creando bus...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: darkNavy,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      try {
        String fechaSalidaFormateada =
            DateFormat('yyyy-MM-dd').format(_fechaSalida!);
        String horaSalidaFormateada =
            "${_horaSalida!.hour.toString().padLeft(2, '0')}:${_horaSalida!.minute.toString().padLeft(2, '0')}";

        await db.collection(coleccion).add({
          'numero': _numeroSeleccionado,
          'ruta': _placaSeleccionada,
          'capacidad': capacidad,
          'chofer': _choferSeleccionado,
          'lugar_salida': _lugarSeleccionado,
          'fechaSalida': fechaSalidaFormateada,
          'horaSalida': horaSalidaFormateada,
          'fecha_salida': _fechaSalida,
          'hora_salida': horaSalidaFormateada,
          'paradas': [],
          'asientos': List.generate(
            capacidad,
            (i) => {
              'numero': i + 1,
              'estado': 'disponible',
              'userId': null,
              'reservaId': null,
              'timestamp': null,
              'lastHeartbeat': null,
            },
          ),
          'fecha_creacion': Timestamp.now(),
          'activo': true,
        });

        if (mounted) {
          Navigator.pop(context);
          _mostrarSnackBar('Bus creado correctamente');

          setState(() {
            _numeroSeleccionado = null;
            _placaSeleccionada = null;
            _capacidadSeleccionada = null;
            _choferSeleccionado = null;
            _lugarSeleccionado = null;
            _fechaSalida = null;
            _horaSalida = null;
            _mostrandoFormularioCrear = false;
          });
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          _mostrarSnackBar('Error al crear bus: $e', esError: true);
        }
      }
    }
  }

  // ========================
  // 🔹 ELIMINAR BUS Y SUS RESERVAS/COMPRAS
  // ========================
  Future<void> eliminarBusCompleto(
      String busId, String numeroBus, String coleccion) async {
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(Icons.warning_amber_rounded, color: accentRed, size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '¿Eliminar Bus?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: darkNavy,
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
              'Estás a punto de eliminar el Bus $numeroBus.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: darkNavy,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentRed.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentRed.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: accentRed, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Esta acción eliminará:',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: darkNavy,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildDeleteItem('El bus y todos sus asientos'),
                  _buildDeleteItem('Todas las reservas asociadas'),
                  _buildDeleteItem('Todos los registros de compra'),
                  SizedBox(height: 12),
                  Text(
                    'Esta acción NO se puede deshacer.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: accentRed,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: textGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentRed,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Eliminar Todo',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(accentRed),
                strokeWidth: 3,
              ),
              SizedBox(height: 20),
              Text(
                'Eliminando...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: darkNavy,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      int totalReservasEliminadas = 0;
      int totalComprasEliminadas = 0;

      String coleccionReal = coleccion;
      DocumentSnapshot? busDoc;
      String? numeroDelBus;

      busDoc = await db.collection(coleccion).doc(busId).get();

      if (!busDoc.exists) {
        String otraColeccion = coleccion == 'buses_tulcan_salida'
            ? 'buses_la_esperanza_salida'
            : 'buses_tulcan_salida';
        busDoc = await db.collection(otraColeccion).doc(busId).get();
        if (busDoc.exists) {
          coleccionReal = otraColeccion;
        }
      }

      if (busDoc.exists) {
        final busData = busDoc.data() as Map<String, dynamic>?;
        numeroDelBus = busData?['numero']?.toString();
      }

      // Eliminar reservas
      final reservasPorBusId = await db
          .collection('reservas')
          .where('busId', isEqualTo: busId)
          .get();
      for (var doc in reservasPorBusId.docs) {
        await doc.reference.delete();
        totalReservasEliminadas++;
      }

      final reservasPorIdBus = await db
          .collection('reservas')
          .where('idBus', isEqualTo: busId)
          .get();
      for (var doc in reservasPorIdBus.docs) {
        await doc.reference.delete();
        totalReservasEliminadas++;
      }

      if (numeroDelBus != null) {
        final reservasPorNumero = await db
            .collection('reservas')
            .where('numeroBus', isEqualTo: numeroDelBus)
            .get();
        for (var doc in reservasPorNumero.docs) {
          await doc.reference.delete();
          totalReservasEliminadas++;
        }
      }

      // Eliminar compras
      final comprasPorBusId = await db
          .collection('comprados')
          .where('busId', isEqualTo: busId)
          .get();
      for (var doc in comprasPorBusId.docs) {
        await doc.reference.delete();
        totalComprasEliminadas++;
      }

      final comprasPorIdBus = await db
          .collection('comprados')
          .where('idBus', isEqualTo: busId)
          .get();
      for (var doc in comprasPorIdBus.docs) {
        await doc.reference.delete();
        totalComprasEliminadas++;
      }

      if (numeroDelBus != null) {
        final comprasPorNumero = await db
            .collection('comprados')
            .where('numeroBus', isEqualTo: numeroDelBus)
            .get();
        for (var doc in comprasPorNumero.docs) {
          await doc.reference.delete();
          totalComprasEliminadas++;
        }
      }

      // Eliminar el bus
      await db.collection(coleccionReal).doc(busId).delete();

      if (mounted) {
        Navigator.pop(context);
        String mensaje = 'Bus $numeroBus eliminado exitosamente';
        if (totalReservasEliminadas > 0 || totalComprasEliminadas > 0) {
          mensaje +=
              '\n✓ $totalReservasEliminadas reservas y $totalComprasEliminadas compras eliminadas';
        }
        _mostrarSnackBar(mensaje);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _mostrarSnackBar('Error al eliminar: $e', esError: true);
      }
    }
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: accentRed,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: textGray),
            ),
          ),
        ],
      ),
    );
  }

  // ========================
  // 🔹 SELECCIÓN DE FECHA Y HORA
  // ========================
  Future<void> seleccionarFecha(BuildContext context) async {
    final now = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryBusBlue,
              onPrimary: Colors.white,
              onSurface: darkNavy,
            ),
          ),
          child: child!,
        );
      },
    );
    if (fecha != null && mounted) {
      setState(() {
        _fechaSalida = fecha;
      });
    }
  }

  Future<void> seleccionarHora(BuildContext context) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryBusBlue,
              onPrimary: Colors.white,
              onSurface: darkNavy,
            ),
          ),
          child: child!,
        );
      },
    );
    if (hora != null && mounted) {
      setState(() {
        _horaSalida = hora;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 248, 255),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(context),
          ),
          SliverToBoxAdapter(
            child: _mostrandoFormularioCrear
                ? _buildFormularioCrear()
                : _buildListaBusesPorFecha(),
          ),
        ],
      ),
    );
  }

  // ========================
  // 📝 HEADER
  // ========================
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
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(0, 255, 255, 255),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(0, 255, 255, 255)
                                    .withOpacity(0.15),
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
                          Text(
                            'GESTIÓN DE BUSES',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: darkNavy,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            _mostrandoFormularioCrear
                                ? 'Crear nuevo bus'
                                : 'Buses por fecha',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: textGray,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        _mostrandoFormularioCrear = !_mostrandoFormularioCrear;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _mostrandoFormularioCrear
                              ? [roadGray, roadGray.withOpacity(0.9)]
                              : [
                                  primaryBusBlue,
                                  primaryBusBlue.withOpacity(0.9)
                                ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (_mostrandoFormularioCrear
                                    ? roadGray
                                    : primaryBusBlue)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _mostrandoFormularioCrear
                                ? Icons.list_rounded
                                : Icons.add_circle_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            _mostrandoFormularioCrear ? 'Ver Buses' : 'Crear',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                _mostrandoFormularioCrear
                    ? 'Crear Nuevo Bus'
                    : 'Buses Registrados',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: darkNavy,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _mostrandoFormularioCrear
                    ? 'Completa los datos para registrar un nuevo bus'
                    : 'Visualiza y administra todos los buses del sistema',
                style: TextStyle(
                  fontSize: 14,
                  color: textGray,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildStatChip(Icons.verified_rounded, 'Seguro'),
                  const SizedBox(width: 10),
                  _buildStatChip(Icons.speed_rounded, 'Rápido'),
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
        color: primaryBusBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryBusBlue.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primaryBusBlue, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryBusBlue,
            ),
          ),
        ],
      ),
    );
  }

  // ========================
  // 📝 FORMULARIO CREAR BUS
  // ========================
  Widget _buildFormularioCrear() {
    if (_cargandoDatos) {
      return Container(
        padding: EdgeInsets.all(60),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryBusBlue),
                strokeWidth: 3,
              ),
              SizedBox(height: 20),
              Text(
                'Cargando opciones...',
                style: TextStyle(
                  color: textGray,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de Número de Bus
            _buildModernDropdown(
              label: 'Número de Bus',
              icon: Icons.numbers,
              value: _numeroSeleccionado,
              items: _buses.map((bus) {
                return DropdownMenuItem<String>(
                  value: bus['numero'],
                  child: Text('Bus #${bus['numero']}'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _cargarDatosBus(value);
                }
              },
              validator: (v) => v == null ? 'Selecciona un número' : null,
            ),
            SizedBox(height: 16),

            // Datos cargados automáticamente
            if (_placaSeleccionada != null) ...[
              _buildInfoCard('Placa', _placaSeleccionada!, Icons.credit_card),
              SizedBox(height: 12),
            ],

            if (_capacidadSeleccionada != null) ...[
              _buildInfoCard('Capacidad', '$_capacidadSeleccionada asientos',
                  Icons.event_seat),
              SizedBox(height: 12),
            ],

            if (_choferSeleccionado != null) ...[
              _buildInfoCard('Conductor', _choferSeleccionado!, Icons.person),
              SizedBox(height: 16),
            ],

            // Selector de Lugar
            _buildModernDropdown(
              label: 'Lugar de Salida',
              icon: Icons.location_on,
              value: _lugarSeleccionado,
              items: _lugares.map((lugar) {
                return DropdownMenuItem<String>(
                  value: lugar,
                  child: Text(lugar),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _lugarSeleccionado = value;
                });
              },
              validator: (v) => v == null ? 'Selecciona un lugar' : null,
            ),
            SizedBox(height: 16),

            // Selector de Fecha
            _buildDateTimePicker(
              label: 'Fecha de Salida',
              icon: Icons.calendar_today,
              value: _fechaSalida == null
                  ? 'Seleccionar fecha'
                  : DateFormat('EEEE, dd MMMM yyyy', 'es')
                      .format(_fechaSalida!),
              onTap: () => seleccionarFecha(context),
            ),
            SizedBox(height: 16),

            // Selector de Hora
            _buildDateTimePicker(
              label: 'Hora de Salida',
              icon: Icons.access_time,
              value: _horaSalida == null
                  ? 'Seleccionar hora'
                  : _horaSalida!.format(context),
              onTap: () => seleccionarHora(context),
            ),
            SizedBox(height: 32),

            // Botón Crear
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: crearBus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBusBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  shadowColor: primaryBusBlue.withOpacity(0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Crear Bus',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: textGray,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryBusBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryBusBlue, size: 20),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryBusBlue, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: items,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            successGreen.withOpacity(0.05),
            successGreen.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: successGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: successGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: successGreen, size: 20),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: textGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: darkNavy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: successGreen, size: 22),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) {
    bool isSelected =
        value != 'Seleccionar fecha' && value != 'Seleccionar hora';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? primaryBusBlue.withOpacity(0.3)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryBusBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: primaryBusBlue, size: 20),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: textGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? darkNavy : textGray,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: textGray,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // El resto del código para la lista de buses permanece igual...
  // (Continuaré con los métodos _buildListaBusesPorFecha, etc.)

  Widget _buildListaBusesPorFecha() {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: _combinarBuses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.all(60),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryBusBlue),
                strokeWidth: 3,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        var buses = snapshot.data ?? [];

        if (buses.isEmpty) {
          return _buildEmptyState();
        }

        // Agrupar buses por fecha
        Map<String, List<Map<String, dynamic>>> busesPorFecha = {};

        for (var bus in buses) {
          var data = bus.data() as Map<String, dynamic>;
          data['id'] = bus.id;

          String coleccion =
              _normalizarTexto(data['lugar_salida']?.toString() ?? '') ==
                      'tulcan'
                  ? 'buses_tulcan_salida'
                  : 'buses_la_esperanza_salida';
          data['coleccion'] = coleccion;

          String fechaKey;
          if (data['fechaSalida'] != null) {
            fechaKey = data['fechaSalida'];
          } else if (data['fecha_salida'] is Timestamp) {
            fechaKey =
                DateFormat('yyyy-MM-dd').format(data['fecha_salida'].toDate());
          } else {
            fechaKey = 'Sin fecha';
          }

          if (!busesPorFecha.containsKey(fechaKey)) {
            busesPorFecha[fechaKey] = [];
          }
          busesPorFecha[fechaKey]!.add(data);
        }

        var fechasOrdenadas = busesPorFecha.keys.toList()
          ..sort((a, b) {
            if (a == 'Sin fecha') return 1;
            if (b == 'Sin fecha') return -1;
            try {
              return DateTime.parse(a).compareTo(DateTime.parse(b));
            } catch (e) {
              return 0;
            }
          });

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          itemCount: fechasOrdenadas.length,
          itemBuilder: (context, index) {
            String fecha = fechasOrdenadas[index];
            List<Map<String, dynamic>> busesDelDia = busesPorFecha[fecha]!;
            return _buildFechaCard(fecha, busesDelDia);
          },
        );
      },
    );
  }

  Widget _buildFechaCard(String fecha, List<Map<String, dynamic>> busesDelDia) {
    int totalAsientos = 0;
    int asientosDisponibles = 0;
    int asientosPagados = 0;
    int asientosReservados = 0;

    for (var bus in busesDelDia) {
      List asientos = bus['asientos'] ?? [];
      totalAsientos += asientos.length;

      for (var asiento in asientos) {
        if (asiento['estado'] == 'disponible') {
          asientosDisponibles++;
        } else if (asiento['estado'] == 'pagado') {
          asientosPagados++;
        } else if (asiento['estado'] == 'reservado' ||
            asiento['estado'] == 'intentandoReservar') {
          asientosReservados++;
        }
      }
    }

    bool estaExpandida = _fechaExpandida == fecha;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: estaExpandida
              ? primaryBusBlue.withOpacity(0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(estaExpandida ? 0.08 : 0.04),
            blurRadius: estaExpandida ? 12 : 8,
            offset: Offset(0, estaExpandida ? 4 : 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _fechaExpandida = estaExpandida ? null : fecha;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: estaExpandida
                    ? LinearGradient(
                        colors: [
                          primaryBusBlue,
                          primaryBusBlue.withOpacity(0.85)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: estaExpandida
                              ? Colors.white.withOpacity(0.2)
                              : primaryBusBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.calendar_month_rounded,
                          color: estaExpandida ? Colors.white : primaryBusBlue,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fecha == 'Sin fecha'
                                  ? 'Sin fecha asignada'
                                  : DateFormat('EEEE', 'es')
                                      .format(DateTime.parse(fecha)),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: estaExpandida
                                    ? Colors.white.withOpacity(0.9)
                                    : textGray,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              fecha == 'Sin fecha'
                                  ? ''
                                  : DateFormat('dd MMMM yyyy', 'es')
                                      .format(DateTime.parse(fecha)),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: estaExpandida ? Colors.white : darkNavy,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: estaExpandida
                              ? Colors.white.withOpacity(0.2)
                              : accentOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: estaExpandida
                                ? Colors.white.withOpacity(0.3)
                                : accentOrange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.directions_bus_rounded,
                              color:
                                  estaExpandida ? Colors.white : accentOrange,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              '${busesDelDia.length}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color:
                                    estaExpandida ? Colors.white : accentOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      AnimatedRotation(
                        turns: estaExpandida ? 0.5 : 0,
                        duration: Duration(milliseconds: 300),
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: estaExpandida
                                ? Colors.white.withOpacity(0.2)
                                : lightBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: estaExpandida ? Colors.white : textGray,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: estaExpandida
                          ? Colors.white.withOpacity(0.15)
                          : lightBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: estaExpandida
                            ? Colors.white.withOpacity(0.2)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildEstadistica(
                          'Disponibles',
                          asientosDisponibles,
                          successGreen,
                          estaExpandida,
                        ),
                        Container(
                          width: 1,
                          height: 35,
                          color: estaExpandida
                              ? Colors.white.withOpacity(0.3)
                              : Colors.grey.shade300,
                        ),
                        _buildEstadistica(
                          'Pagados',
                          asientosPagados,
                          accentRed,
                          estaExpandida,
                        ),
                        Container(
                          width: 1,
                          height: 35,
                          color: estaExpandida
                              ? Colors.white.withOpacity(0.3)
                              : Colors.grey.shade300,
                        ),
                        _buildEstadistica(
                          'Reservados',
                          asientosReservados,
                          accentOrange,
                          estaExpandida,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: SizedBox.shrink(),
            secondChild: Column(
              children: busesDelDia.map((bus) {
                return _buildBusCard(bus);
              }).toList(),
            ),
            crossFadeState: estaExpandida
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadistica(
      String label, int valor, Color color, bool invertido) {
    return Column(
      children: [
        Text(
          valor.toString(),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: invertido ? Colors.white : color,
            letterSpacing: -1,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: invertido ? Colors.white.withOpacity(0.85) : textGray,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildBusCard(Map<String, dynamic> bus) {
    List asientos = bus['asientos'] ?? [];
    int disponibles = asientos.where((a) => a['estado'] == 'disponible').length;
    int pagados = asientos.where((a) => a['estado'] == 'pagado').length;
    int reservados = asientos
        .where((a) =>
            a['estado'] == 'reservado' || a['estado'] == 'intentandoReservar')
        .length;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: lightBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBusBlue, primaryBusBlue.withOpacity(0.85)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBusBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.directions_bus_rounded,
                        color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Bus ${bus['numero'] ?? 'N/A'}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: accentOrange),
                    SizedBox(width: 4),
                    Text(
                      bus['lugar_salida'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: darkNavy,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: accentRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(Icons.delete_outline_rounded,
                      color: accentRed, size: 20),
                  onPressed: () => eliminarBusCompleto(
                    bus['id'],
                    bus['numero'] ?? 'N/A',
                    bus['coleccion'],
                  ),
                  tooltip: 'Eliminar bus',
                  padding: EdgeInsets.all(8),
                  constraints: BoxConstraints(),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        Icons.badge_outlined,
                        'Conductor',
                        bus['chofer'] ?? 'N/A',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        Icons.route_outlined,
                        'Placa',
                        bus['ruta'] ?? 'N/A',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoRow(
                        Icons.access_time_rounded,
                        'Hora',
                        bus['hora_salida'] ?? bus['horaSalida'] ?? 'N/A',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildAsientoStat(
                      'Disponibles', disponibles, successGreen),
                ),
                Expanded(
                  child: _buildAsientoStat('Pagados', pagados, accentRed),
                ),
                Expanded(
                  child:
                      _buildAsientoStat('Reservados', reservados, accentOrange),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryBusBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: primaryBusBlue, size: 14),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: textGray,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: darkNavy,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAsientoStat(String label, int cantidad, Color color) {
    return Column(
      children: [
        Text(
          cantidad.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: textGray,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: lightBg,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.directions_bus_outlined,
                  size: 64, color: textGray),
            ),
            SizedBox(height: 24),
            Text(
              'No hay buses creados',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: darkNavy,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Crea tu primer bus para comenzar',
              style: TextStyle(fontSize: 14, color: textGray),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _mostrandoFormularioCrear = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBusBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Crear tu primer bus',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: accentRed),
            SizedBox(height: 16),
            Text(
              'Error al cargar buses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: darkNavy,
              ),
            ),
            SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 14, color: textGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Stream<List<QueryDocumentSnapshot>> _combinarBuses() async* {
    await for (var _ in Stream.periodic(Duration(milliseconds: 500))) {
      try {
        final buses = await db
            .collection('buses_tulcan_salida')
            .orderBy('fecha_creacion', descending: true)
            .get();

        final buses1 = await db
            .collection('buses_la_esperanza_salida')
            .orderBy('fecha_creacion', descending: true)
            .get();

        List<QueryDocumentSnapshot> todosBuses = [];
        todosBuses.addAll(buses.docs);
        todosBuses.addAll(buses1.docs);

        todosBuses.sort((a, b) {
          var dataA = a.data() as Map<String, dynamic>;
          var dataB = b.data() as Map<String, dynamic>;
          var fechaA = dataA['fecha_creacion'] as Timestamp?;
          var fechaB = dataB['fecha_creacion'] as Timestamp?;
          if (fechaA == null || fechaB == null) return 0;
          return fechaB.compareTo(fechaA);
        });

        yield todosBuses;
      } catch (e) {
        print('Error al combinar buses: $e');
        yield [];
      }
    }
  }
}
