import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HistorialComprasScreen extends StatefulWidget {
  const HistorialComprasScreen({Key? key}) : super(key: key);

  @override
  _HistorialComprasScreenState createState() => _HistorialComprasScreenState();
}

class _HistorialComprasScreenState extends State<HistorialComprasScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final String userEmail = FirebaseAuth.instance.currentUser?.email ?? '';

  DateTime? fechaSeleccionada;
  List<DateTime> fechasDisponibles = [];
  List<DocumentSnapshot> boletosDelDia = [];
  bool cargando = false;
  bool cargandoFechas = true;

  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  // Paleta profesional moderna
  final Color primaryColor = const Color(0xFF1A2332);
  final Color accentColor = const Color(0xFF4A90E2);
  final Color darkNavy = const Color(0xFF0F172A);
  final Color roadGray = const Color(0xFF64748B);
  final Color lightBg = const Color(0xFFF8FAFC);
  final Color textGray = const Color(0xFF64748B);
  final Color textDark = const Color(0xFF1E293B);
  final Color successGreen = const Color(0xFF10B981);
  final Color borderColor = const Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeOut,
      ),
    );
    _animationController?.forward();
    _cargarFechasDisponibles();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      body: userEmail.isEmpty
          ? _buildError('No se pudo identificar al usuario')
          : CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildModernAppBar(),
                _buildFiltroFechas(),
                _buildContenidoBoletos(),
              ],
            ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 243, 248, 255),
              Color.fromARGB(255, 245, 249, 255),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: FadeTransition(
              opacity: _fadeAnimation ?? AlwaysStoppedAnimation(1.0),
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
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(0, 255, 255, 255),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        const Color.fromARGB(0, 255, 255, 255)
                                            .withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Color(0xFF940016),
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'HISTORIAL DE BOLETOS',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: textDark,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                'Gestión de viajes',
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
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(0, 255, 255, 255),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(0, 250, 250, 250)
                                    .withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.calendar_month_outlined,
                            color: Color(0xFF940016),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Mis Boletos',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: textDark,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Text(
                      'Revisa el historial completo de tus viajes',
                      style: TextStyle(
                        fontSize: 14,
                        color: textGray,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltroFechas() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
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
            // HEADER
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_today_outlined,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seleccionar Fecha',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                      Text(
                        '${fechasDisponibles.length} fechas disponibles',
                        style: TextStyle(
                          fontSize: 12,
                          color: textGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // CONTENIDO
            cargandoFechas
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                  )
                : fechasDisponibles.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'No hay fechas disponibles',
                            style: TextStyle(
                              fontSize: 14,
                              color: textGray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 56, // 🔥 altura justa para chip 44x44
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: fechasDisponibles.length,
                          itemBuilder: (context, index) {
                            final fecha = fechasDisponibles[index];
                            final isSelected = fechaSeleccionada != null &&
                                fecha.year == fechaSeleccionada!.year &&
                                fecha.month == fechaSeleccionada!.month &&
                                fecha.day == fechaSeleccionada!.day;

                            return Center(
                              child: _buildFechaChip(fecha, isSelected),
                            );
                          },
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildFechaChip(DateTime fecha, bool isSelected) {
    final dia = DateFormat('dd', 'es').format(fecha);
    final mes = DateFormat('MMM', 'es').format(fecha).toUpperCase();
    final diaSemana = DateFormat('EEE', 'es').format(fecha).toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _seleccionarFechaDirecta(fecha),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 44,
            height: 44, // 🔥 CUADRADO REAL
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        accentColor,
                        accentColor.withOpacity(0.85),
                      ],
                    )
                  : null,
              color: isSelected ? null : lightBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? accentColor : borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  diaSemana,
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected ? Colors.white.withOpacity(0.8) : textGray,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  dia,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.white : textDark,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  mes,
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected ? Colors.white.withOpacity(0.9) : textGray,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContenidoBoletos() {
    if (cargando) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                'Cargando información...',
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

    if (fechaSeleccionada == null) {
      return SliverFillRemaining(child: _buildEstadoInicial());
    }

    if (boletosDelDia.isEmpty) {
      return SliverFillRemaining(child: _buildEstadoSinBoletos());
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final doc = boletosDelDia[index];
            final dynamic raw = (doc as dynamic).data();
            final Map<String, dynamic> data =
                raw is Map<String, dynamic> ? raw : <String, dynamic>{};
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildBoletoCard(data, index),
            );
          },
          childCount: boletosDelDia.length,
        ),
      ),
    );
  }

  Widget _buildEstadoInicial() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: lightBg,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.touch_app_outlined,
                size: 64,
                color: roadGray,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Selecciona una Fecha',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: textDark,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Elige una fecha de la lista superior\npara visualizar tus boletos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: textGray,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoSinBoletos() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: lightBg,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: roadGray,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Sin Boletos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: textDark,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No se encontraron boletos para\n${DateFormat('dd/MM/yyyy').format(fechaSeleccionada!)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: textGray,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoletoCard(Map<String, dynamic> data, int index) {
    final de = data['origenNombre'] ?? 'Tulcán';
    final a = data['paradaNombre'] ?? 'Destino';
    final nombre = data['nombreComprador'] ?? 'N/A';
    final asiento = data['asiento']?.toString() ??
        (data['asientos'] != null && (data['asientos'] as List).isNotEmpty
            ? (data['asientos'] as List).join(', ')
            : 'N/A');
    final carro = data['numeroBus']?.toString() ?? 'N/A';
    final hora = data['horaSalida'] ?? 'N/A';
    final fecha = data['fechaSalida'] ?? 'N/A';
    final total = (data['precio'] ?? 0.0).toDouble();

    return FadeTransition(
      opacity: _fadeAnimation ?? AlwaysStoppedAnimation(1.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
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
            // Header con gradiente
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryColor, primaryColor.withOpacity(0.85)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
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
                          'Unidad $carro',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Asiento $asiento',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: successGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'CONFIRMADO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Ruta
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lightBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: accentColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ORIGEN',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: textGray,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                de,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: darkNavy,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: roadGray,
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'DESTINO',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: textGray,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: successGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                a,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: darkNavy,
                                  letterSpacing: -0.3,
                                ),
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Detalles
                  _buildDetalleRow(
                      Icons.person_outline_rounded, 'Pasajero', nombre),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetalleRow(
                          Icons.access_time_rounded,
                          'Hora',
                          hora,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDetalleRow(
                          Icons.calendar_today_rounded,
                          'Fecha',
                          fecha,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Total
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [darkNavy, roadGray],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL PAGADO',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _mostrarVistaPrevia(data),
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text(
                            'Ver',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: roadGray,
                            side: BorderSide(color: borderColor, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _generarPDF(data),
                          icon: const Icon(Icons.picture_as_pdf_outlined,
                              size: 18),
                          label: const Text(
                            'PDF',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalleRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lightBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: roadGray),
          const SizedBox(width: 10),
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: darkNavy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cargarFechasDisponibles() async {
    setState(() => cargandoFechas = true);

    try {
      final querySnapshot = await db
          .collection('historial')
          .where('email', isEqualTo: userEmail)
          .get();

      Set<DateTime> fechasUnicas = {};

      for (var doc in querySnapshot.docs) {
        var data = doc.data();
        Timestamp? timestamp = data['fecha'];

        if (timestamp != null) {
          DateTime fechaBoleto = timestamp.toDate();
          DateTime fechaSolo =
              DateTime(fechaBoleto.year, fechaBoleto.month, fechaBoleto.day);
          fechasUnicas.add(fechaSolo);
        }
      }

      setState(() {
        fechasDisponibles = fechasUnicas.toList()
          ..sort((a, b) => b.compareTo(a));
        cargandoFechas = false;
      });
    } catch (e) {
      print('Error al cargar fechas: $e');
      setState(() {
        fechasDisponibles = [];
        cargandoFechas = false;
      });
    }
  }

  Future<void> _seleccionarFechaDirecta(DateTime fecha) async {
    setState(() {
      fechaSeleccionada = fecha;
      cargando = true;
    });

    await _cargarBoletosDelDia(fecha);

    setState(() {
      cargando = false;
    });
  }

  Future<void> _cargarBoletosDelDia(DateTime fecha) async {
    try {
      final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);

      final querySnapshot = await db
          .collection('historial')
          .where('email', isEqualTo: userEmail)
          .get();

      boletosDelDia = querySnapshot.docs.where((doc) {
        var data = doc.data();
        Timestamp? timestamp = data['fecha'];

        if (timestamp != null) {
          DateTime fechaBoleto = timestamp.toDate();
          DateTime fechaBoletoDia =
              DateTime(fechaBoleto.year, fechaBoleto.month, fechaBoleto.day);
          return fechaBoletoDia.isAtSameMomentAs(inicioDia);
        }
        return false;
      }).toList();
    } catch (e) {
      print('Error al cargar boletos: $e');
      boletosDelDia = [];
    }
  }

  void _mostrarVistaPrevia(Map<String, dynamic> data) {
    final de = data['origenNombre'] ?? 'Tulcán';
    final a = data['paradaNombre'] ?? 'Destino';
    final nombre = data['nombreComprador'] ?? 'N/A';
    final asiento = data['asiento']?.toString() ??
        (data['asientos'] != null && (data['asientos'] as List).isNotEmpty
            ? (data['asientos'] as List).join(', ')
            : 'N/A');
    final carro = data['numeroBus']?.toString() ?? 'N/A';
    final hora = data['horaSalida'] ?? 'N/A';
    final fecha = data['fechaSalida'] ?? 'N/A';
    final total = (data['precio'] ?? 0.0).toDouble();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withOpacity(0.85)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Vista Previa del Boleto',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 24),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Contenido
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Logo y título
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border.all(color: primaryColor, width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'DORADO MALDONADO',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: accentColor,
                                letterSpacing: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Resolución Nº 08.Q.I.J.001580',
                              style: TextStyle(
                                fontSize: 10,
                                color: textGray,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'TRANSDORAMALD S.A.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      Divider(color: borderColor, thickness: 2),
                      const SizedBox(height: 24),

                      // Ruta
                      Row(
                        children: [
                          Expanded(child: _buildCampoPreview('De:', de)),
                          Icon(Icons.arrow_forward_rounded,
                              color: roadGray, size: 20),
                          const SizedBox(width: 16),
                          Expanded(child: _buildCampoPreview('A:', a)),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Detalles
                      _buildCampoPreview('Nombre:', nombre),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                              child: _buildCampoPreview('Asiento:', asiento)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildCampoPreview('Carro:', carro)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildCampoPreview('Hora:', hora)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildCampoPreview('Fecha:', fecha)),
                        ],
                      ),

                      const SizedBox(height: 24),
                      Divider(color: borderColor, thickness: 2),
                      const SizedBox(height: 24),

                      // Total
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, darkNavy],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'TOTAL',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '\$${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'Tel: 2969037 • 0987703157',
                        style: TextStyle(
                          fontSize: 12,
                          color: textGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer con botón
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: lightBg,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 22),
                  label: const Text(
                    'Descargar PDF',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _generarPDF(data);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampoPreview(String label, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textGray,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          valor,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textDark,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Future<void> _generarPDF(Map<String, dynamic> data) async {
    try {
      final pdf = pw.Document();

      final de = data['origenNombre'] ?? 'Tulcán';
      final a = data['paradaNombre'] ?? 'Destino';
      final nombre = data['nombreComprador'] ?? 'N/A';
      final asiento = data['asiento']?.toString() ??
          (data['asientos'] != null && (data['asientos'] as List).isNotEmpty
              ? (data['asientos'] as List).join(', ')
              : 'N/A');
      final carro = data['numeroBus']?.toString() ?? 'N/A';
      final hora = data['horaSalida'] ?? 'N/A';
      final fecha = data['fechaSalida'] ?? 'N/A';
      final total = (data['precio'] ?? 0.0).toDouble();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Encabezado
                pw.Container(
                  padding: const pw.EdgeInsets.all(24),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey800, width: 2.5),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'DORADO MALDONADO',
                        style: pw.TextStyle(
                          fontSize: 30,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Resolución de la Superintendencia de Compañías Nº 08.Q.I.J.001580',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'TRANSDORAMALD S.A.',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 40),

                // Título
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 12),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom:
                          pw.BorderSide(color: PdfColors.grey800, width: 2.5),
                    ),
                  ),
                  child: pw.Text(
                    'BOLETO DE VIAJE',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 30),

                // Ruta
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildPDFCampo('De:', de)),
                    pw.SizedBox(width: 40),
                    pw.Expanded(child: _buildPDFCampo('A:', a)),
                  ],
                ),
                pw.SizedBox(height: 24),
                _buildPDFCampo('Nombre(s):', nombre),
                pw.SizedBox(height: 24),
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildPDFCampo('Asiento(s):', asiento)),
                    pw.SizedBox(width: 40),
                    pw.Expanded(child: _buildPDFCampo('Carro Nº:', carro)),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildPDFCampo('Hora:', hora)),
                    pw.SizedBox(width: 40),
                    pw.Expanded(child: _buildPDFCampo('Fecha:', fecha)),
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Container(height: 1.5, color: PdfColors.grey400),
                pw.SizedBox(height: 40),

                // Precio y contacto
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Telf.: Ofic.:',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Maldonado: 2969 037',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Tulcán: 0987703157',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(20),
                      decoration: pw.BoxDecoration(
                        border:
                            pw.Border.all(color: PdfColors.grey800, width: 2.5),
                        borderRadius: pw.BorderRadius.circular(12),
                        color: PdfColors.grey100,
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'Valor \$:',
                            style: const pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey600,
                            ),
                          ),
                          pw.Text(
                            'I.V.A 0%',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey600,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            'TOTAL \$ ${total.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 26,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.Spacer(),

                // Footer
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 20),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.grey400, width: 1.5),
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Gracias por viajar con nosotros',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Conserve este boleto durante todo el viaje',
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Fecha de emisión: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('PDF generado correctamente'),
              ],
            ),
            backgroundColor: successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      print('Error al generar PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error al generar el PDF: $e')),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  pw.Widget _buildPDFCampo(String label, String valor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey600,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          valor,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildError(String mensaje) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: lightBg,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: roadGray,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Error',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: darkNavy,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: textGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
