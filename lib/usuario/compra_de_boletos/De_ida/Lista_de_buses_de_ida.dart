import 'package:app2tesis/usuario/compra_de_boletos/De_ida/Selecion_de_parada_desde_Tulcan.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// IMPORTANTE: Asegúrate de importar tu ParadasScreen
// import 'package:app2tesis/usuario/compra_de_boletos/De_ida/Selecion_de_parada_desde_Tulcan.dart';

class ListaBusesScreen extends StatefulWidget {
  const ListaBusesScreen({Key? key}) : super(key: key);

  @override
  _ListaBusesScreenState createState() => _ListaBusesScreenState();
}

class _ListaBusesScreenState extends State<ListaBusesScreen>
    with SingleTickerProviderStateMixin {
  // Paleta empresarial
  final Color primaryNavy = const Color(0xFF1A2332);
  final Color darkGray = const Color(0xFF2D3748);
  final Color lightGray = const Color(0xFFF7FAFC);
  final Color mediumGray = const Color(0xFF718096);
  final Color successGreen = const Color(0xFF10B981);
  final Color warningOrange = const Color(0xFFF59E0B);
  final Color errorRed = const Color(0xFFEF4444);
  final Color accentBlue = const Color(0xFF3B82F6);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  DateTime? _parsearHoraSalida(String horaSalida, DateTime fechaSalida) {
    try {
      horaSalida = horaSalida.trim().toLowerCase();
      RegExp regExp = RegExp(r'(\d{1,2}):(\d{2})\s*(am|pm)?');
      var match = regExp.firstMatch(horaSalida);

      if (match != null) {
        int hora = int.parse(match.group(1)!);
        int minuto = int.parse(match.group(2)!);
        String? periodo = match.group(3);

        if (periodo != null) {
          if (periodo == 'pm' && hora != 12) {
            hora += 12;
          } else if (periodo == 'am' && hora == 12) {
            hora = 0;
          }
        }

        return DateTime(
          fechaSalida.year,
          fechaSalida.month,
          fechaSalida.day,
          hora,
          minuto,
        );
      }

      var partes = horaSalida.split(':');
      if (partes.length == 2) {
        int hora = int.parse(partes[0].trim());
        int minuto = int.parse(partes[1].trim().substring(0, 2));
        return DateTime(
          fechaSalida.year,
          fechaSalida.month,
          fechaSalida.day,
          hora,
          minuto,
        );
      }

      return null;
    } catch (e) {
      print('⚠️ Error al parsear hora "$horaSalida": $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final ahora = DateTime.now();
    final hoyInicio = DateTime(ahora.year, ahora.month, ahora.day);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8FF),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildHeader(isTablet),
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream: db.collection('buses_tulcan_salida').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState(isTablet);
                }

                if (snapshot.hasError) {
                  return _buildErrorState(isTablet);
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(isTablet);
                }

                var buses = snapshot.data!.docs;
                var busesDisponibles = buses.where((busDoc) {
                  var busData = busDoc.data() as Map<String, dynamic>;
                  var fechaSalida = busData['fecha_salida'] != null
                      ? (busData['fecha_salida'] as Timestamp).toDate()
                      : (busData['fechaSalida'] != null
                          ? (busData['fechaSalida'] as Timestamp).toDate()
                          : null);

                  if (fechaSalida == null) return false;

                  String horaSalida =
                      busData['hora_salida'] ?? busData['horaSalida'] ?? '';
                  if (horaSalida.isEmpty) return false;

                  DateTime? fechaHoraSalida =
                      _parsearHoraSalida(horaSalida, fechaSalida);
                  if (fechaHoraSalida == null) {
                    return fechaSalida
                        .isAfter(hoyInicio.subtract(Duration(seconds: 1)));
                  }

                  return fechaHoraSalida.isAfter(ahora);
                }).toList();

                busesDisponibles.sort((a, b) {
                  var dataA = a.data() as Map<String, dynamic>;
                  var dataB = b.data() as Map<String, dynamic>;
                  var fechaA = dataA['fecha_salida'] != null
                      ? (dataA['fecha_salida'] as Timestamp).toDate()
                      : (dataA['fechaSalida'] as Timestamp).toDate();
                  var fechaB = dataB['fecha_salida'] != null
                      ? (dataB['fecha_salida'] as Timestamp).toDate()
                      : (dataB['fechaSalida'] as Timestamp).toDate();

                  int comparacionFecha = fechaA.compareTo(fechaB);
                  if (comparacionFecha != 0) return comparacionFecha;

                  String horaA =
                      dataA['hora_salida'] ?? dataA['horaSalida'] ?? '';
                  String horaB =
                      dataB['hora_salida'] ?? dataB['horaSalida'] ?? '';
                  return horaA.compareTo(horaB);
                });

                if (busesDisponibles.isEmpty) {
                  return _buildEmptyState(isTablet);
                }

                return Column(
                  children: busesDisponibles.map((busDoc) {
                    var busData = busDoc.data() as Map<String, dynamic>;
                    var numero = busData['numero'] ?? 'S/N';
                    var ruta = busData['ruta'] ?? 'Sin ruta';
                    var chofer = busData['chofer'] ?? 'Sin chofer';
                    var horaSalida = busData['hora_salida'] ??
                        busData['horaSalida'] ??
                        'Sin hora';
                    var lugarSalida = busData['lugar_salida'] ?? 'Sin lugar';
                    var capacidad = busData['capacidad'] ?? 0;
                    var fechaSalida = busData['fecha_salida'] != null
                        ? (busData['fecha_salida'] as Timestamp).toDate()
                        : (busData['fechaSalida'] != null
                            ? (busData['fechaSalida'] as Timestamp).toDate()
                            : null);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _BusCardWithReservas(
                        busId: busDoc.id,
                        numero: numero.toString(),
                        ruta: ruta,
                        chofer: chofer,
                        horaSalida: horaSalida,
                        lugarSalida: lugarSalida,
                        fechaSalida: fechaSalida,
                        capacidad: capacidad,
                        isTablet: isTablet,
                        primaryNavy: primaryNavy,
                        darkGray: darkGray,
                        mediumGray: mediumGray,
                        successGreen: successGreen,
                        warningOrange: warningOrange,
                        errorRed: errorRed,
                        fadeAnimation: _fadeAnimation,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isTablet) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF3F8FF), Color(0xFFF5F9FF)],
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
                  // ───────────── HEADER SUPERIOR ─────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // 🔙 BOTÓN REGRESAR
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            },
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
                                size: 22,
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // TÍTULOS
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SELECCIÓN DE BUS',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: darkGray,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                'Elige tu viaje',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: mediumGray,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // PASO
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
                                color: const Color.fromARGB(0, 240, 239, 239)
                                    .withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_bus_rounded,
                            color: Color(0xFF940016),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ───────────── TÍTULO PRINCIPAL ─────────────
                  Text(
                    'Buses Disponibles',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: darkGray,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Text(
                      'Selecciona el bus que mejor se adapte a tu horario',
                      style: TextStyle(
                        fontSize: 14,
                        color: mediumGray,
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

  Widget _buildLoadingState(bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryNavy),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'Cargando buses disponibles...',
              style: TextStyle(
                fontSize: isTablet ? 15 : 14,
                color: mediumGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: errorRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: isTablet ? 80 : 64,
                color: errorRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error al cargar los buses',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                color: darkGray,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Por favor, intenta nuevamente',
              style: TextStyle(
                fontSize: isTablet ? 15 : 14,
                color: mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 32 : 24),
              decoration: BoxDecoration(
                color: mediumGray.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_bus_rounded,
                size: isTablet ? 80 : 64,
                color: mediumGray,
              ),
            ),
            SizedBox(height: isTablet ? 28 : 24),
            Text(
              'No hay buses disponibles',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                color: darkGray,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: isTablet ? 12 : 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'No hay buses programados con salidas futuras',
                style: TextStyle(
                  fontSize: isTablet ? 15 : 14,
                  color: mediumGray,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusCardWithReservas extends StatelessWidget {
  final String busId;
  final String numero;
  final String ruta;
  final String chofer;
  final String horaSalida;
  final String lugarSalida;
  final DateTime? fechaSalida;
  final int capacidad;
  final bool isTablet;
  final Color primaryNavy;
  final Color darkGray;
  final Color mediumGray;
  final Color successGreen;
  final Color warningOrange;
  final Color errorRed;
  final Animation<double> fadeAnimation;

  const _BusCardWithReservas({
    required this.busId,
    required this.numero,
    required this.ruta,
    required this.chofer,
    required this.horaSalida,
    required this.lugarSalida,
    required this.fechaSalida,
    required this.capacidad,
    required this.isTablet,
    required this.primaryNavy,
    required this.darkGray,
    required this.mediumGray,
    required this.successGreen,
    required this.warningOrange,
    required this.errorRed,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return StreamBuilder<DocumentSnapshot>(
      stream: db.collection('buses_tulcan_salida').doc(busId).snapshots(),
      builder: (context, snapshot) {
        int asientosOcupados = 0;

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('asientos')) {
            try {
              List<dynamic> asientosArray = data['asientos'];
              for (var asiento in asientosArray) {
                if (asiento is Map<String, dynamic> &&
                    asiento['estado'] == 'pagado') {
                  asientosOcupados++;
                }
              }
            } catch (e) {
              print('Error al leer asientos: $e');
            }
          }
        }

        int asientosDisponibles = capacidad - asientosOcupados;

        return FadeTransition(
          opacity: fadeAnimation,
          child: _BusCard(
            busId: busId,
            numero: numero,
            ruta: ruta,
            chofer: chofer,
            horaSalida: horaSalida,
            lugarSalida: lugarSalida,
            fechaSalida: fechaSalida,
            capacidad: capacidad,
            asientosOcupados: asientosOcupados,
            asientosDisponibles: asientosDisponibles,
            isTablet: isTablet,
            primaryNavy: primaryNavy,
            darkGray: darkGray,
            mediumGray: mediumGray,
            successGreen: successGreen,
            warningOrange: warningOrange,
            errorRed: errorRed,
          ),
        );
      },
    );
  }
}

class _BusCard extends StatelessWidget {
  final String busId;
  final String numero;
  final String ruta;
  final String chofer;
  final String horaSalida;
  final String lugarSalida;
  final DateTime? fechaSalida;
  final int capacidad;
  final int asientosOcupados;
  final int asientosDisponibles;
  final bool isTablet;
  final Color primaryNavy;
  final Color darkGray;
  final Color mediumGray;
  final Color successGreen;
  final Color warningOrange;
  final Color errorRed;

  const _BusCard({
    required this.busId,
    required this.numero,
    required this.ruta,
    required this.chofer,
    required this.horaSalida,
    required this.lugarSalida,
    required this.fechaSalida,
    required this.capacidad,
    required this.asientosOcupados,
    required this.asientosDisponibles,
    required this.isTablet,
    required this.primaryNavy,
    required this.darkGray,
    required this.mediumGray,
    required this.successGreen,
    required this.warningOrange,
    required this.errorRed,
  });

  @override
  Widget build(BuildContext context) {
    String fechaFormateada = fechaSalida != null
        ? DateFormat('dd/MM/yyyy').format(fechaSalida!)
        : 'Sin fecha';

    double porcentajeOcupado =
        capacidad > 0 ? (asientosOcupados / capacidad) : 0.0;

    Color estadoColor = asientosDisponibles > capacidad * 0.5
        ? successGreen
        : (asientosDisponibles > 0 ? warningOrange : errorRed);

    String estadoTexto = asientosDisponibles > capacidad * 0.5
        ? 'Disponible'
        : (asientosDisponibles > 0 ? 'Pocos asientos' : 'Lleno');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navegar a ParadasScreen con el busId
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ParadasScreen(busId: busId, chofer: chofer),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
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
                        color: primaryNavy.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.directions_bus_rounded,
                        color: primaryNavy,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bus $numero',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: darkGray,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ruta,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: estadoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: estadoColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        estadoTexto,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: estadoColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Disponibilidad',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: darkGray,
                            ),
                          ),
                          Text(
                            '$asientosDisponibles/$capacidad asientos',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: estadoColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: porcentajeOcupado,
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            porcentajeOcupado > 0.8
                                ? errorRed
                                : (porcentajeOcupado > 0.5
                                    ? warningOrange
                                    : successGreen),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Información del viaje',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: darkGray,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.person_outline_rounded,
                        label: 'Chofer',
                        value: chofer,
                        mediumGray: mediumGray,
                        darkGray: darkGray,
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[200]),
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.access_time_rounded,
                        label: 'Hora',
                        value: horaSalida,
                        mediumGray: mediumGray,
                        darkGray: darkGray,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.location_on_outlined,
                        label: 'Salida',
                        value: lugarSalida,
                        mediumGray: mediumGray,
                        darkGray: darkGray,
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[200]),
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.calendar_today_rounded,
                        label: 'Fecha',
                        value: fechaFormateada,
                        mediumGray: mediumGray,
                        darkGray: darkGray,
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
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color mediumGray;
  final Color darkGray;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.mediumGray,
    required this.darkGray,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: mediumGray),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: mediumGray,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: darkGray,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
