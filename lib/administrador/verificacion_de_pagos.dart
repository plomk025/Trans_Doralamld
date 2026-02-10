import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AdminVerificacionPagosScreen extends StatefulWidget {
  const AdminVerificacionPagosScreen({Key? key}) : super(key: key);

  @override
  _AdminVerificacionPagosScreenState createState() =>
      _AdminVerificacionPagosScreenState();
}

class _AdminVerificacionPagosScreenState
    extends State<AdminVerificacionPagosScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseFunctions functions = FirebaseFunctions.instance;

  String? cooperativaSeleccionada;
  String? busSeleccionado;
  String filtroEstado = 'pendiente_verificacion';
  String coleccionActual = 'reservas';

  // Paleta de colores moderna
  static const Color primaryBusBlue = Color(0xFF940016);
  static const Color accentOrange = Color(0xFFEA580C);
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color lightBg = Color(0xFFF1F5F9);
  static const Color textGray = Color(0xFF475569);
  static const Color successGreen = Color(0xFF059669);
  static const Color accentRed = Color(0xFF940016);
  static const Color warningYellow = Color(0xFFF59E0B);

  String get coleccionBuses {
    if (cooperativaSeleccionada == 'la_esperanza') {
      return 'buses_la_esperanza_salida';
    } else if (cooperativaSeleccionada == 'tulcan') {
      return 'buses_tulcan_salida';
    }
    return 'buses_tulcan_salida';
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
            child: _buildFiltros(),
          ),
          SliverFillRemaining(
            child: _buildListaReservas(),
          ),
        ],
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
                            'VERIFICACIÓN DE PAGOS',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: darkNavy,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Control financiero',
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
                  if (busSeleccionado != null)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _generarReporte(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accentRed, accentRed.withOpacity(0.9)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: accentRed.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.picture_as_pdf,
                                color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'PDF',
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
                'Gestión de Pagos',
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
                'Verifica y aprueba los comprobantes de transferencia',
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
              const SizedBox(height: 24),

              // Selectores modernos
              _buildModernSelector(
                label: 'Lugar de Salida',
                icon: Icons.location_on,
                value: cooperativaSeleccionada,
                hint: 'Selecciona cooperativa',
                items: const [
                  DropdownMenuItem(
                    value: 'la_esperanza',
                    child: Text('🚌 La Esperanza'),
                  ),
                  DropdownMenuItem(
                    value: 'tulcan',
                    child: Text('🚌 Tulcán'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    cooperativaSeleccionada = value;
                    busSeleccionado = null;
                  });
                },
              ),

              if (cooperativaSeleccionada != null) ...[
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: db.collection(coleccionBuses).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(primaryBusBlue),
                          strokeWidth: 3,
                        ),
                      );
                    }

                    List<DropdownMenuItem<String>> items = [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todos los buses'),
                      ),
                    ];

                    for (var doc in snapshot.data!.docs) {
                      var data = doc.data() as Map<String, dynamic>;
                      items.add(
                        DropdownMenuItem(
                          value: doc.id,
                          child: Text('Bus ${data['numero'] ?? doc.id}'),
                        ),
                      );
                    }

                    return _buildModernSelector(
                      label: 'Seleccionar Bus',
                      icon: Icons.directions_bus_rounded,
                      value: busSeleccionado,
                      hint: 'Todos los buses',
                      items: items,
                      onChanged: (value) {
                        setState(() {
                          busSeleccionado = value;
                        });
                      },
                    );
                  },
                ),
              ],
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

  Widget _buildModernSelector({
    required String label,
    required IconData icon,
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
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
        hint: Text(hint),
        icon: Icon(Icons.arrow_drop_down, color: darkNavy),
        style: TextStyle(
          fontSize: 14,
          color: darkNavy,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: const Color.fromARGB(255, 243, 248, 255),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildModernChip(
              'Pendientes',
              'pendiente_verificacion',
              warningYellow,
              'reservas',
              Icons.pending_outlined,
            ),
            const SizedBox(width: 12),
            _buildModernChip(
              'Aprobados',
              'aprobado',
              successGreen,
              'comprados',
              Icons.check_circle_outline,
            ),
            const SizedBox(width: 12),
            _buildModernChip(
              'Rechazados',
              'rechazado',
              accentRed,
              'rechazados',
              Icons.cancel_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernChip(
    String label,
    String valor,
    Color color,
    String coleccion,
    IconData icon,
  ) {
    bool seleccionado = filtroEstado == valor;
    return InkWell(
      onTap: () {
        setState(() {
          filtroEstado = valor;
          coleccionActual = coleccion;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: seleccionado
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                )
              : null,
          color: seleccionado ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado ? color : Colors.grey.shade200,
            width: seleccionado ? 2 : 1,
          ),
          boxShadow: seleccionado
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: seleccionado ? Colors.white : color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: seleccionado ? Colors.white : darkNavy,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaReservas() {
    if (cooperativaSeleccionada == null || busSeleccionado == null) {
      return _buildEmptyState();
    }

    Query query = db
        .collection(coleccionActual)
        .where('busId', isEqualTo: busSeleccionado);

    if (coleccionActual == 'reservas') {
      query = query.where('estado', isEqualTo: filtroEstado);
    } else if (coleccionActual == 'comprados') {
      query = query.where('estado', isEqualTo: 'aprobado');
    }

    query = query.where('metodoPago', whereIn: ['efectivo', 'transferencia']);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryBusBlue),
              strokeWidth: 3,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildNoDataState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return _buildReservaCard(doc, data);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: lightBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline,
                size: 64,
                color: textGray,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              cooperativaSeleccionada == null
                  ? 'Selecciona una cooperativa'
                  : 'Selecciona un bus',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: darkNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cooperativaSeleccionada == null
                  ? 'Elige entre La Esperanza o Tulcán'
                  : 'Elige el bus para ver las reservas',
              style: TextStyle(fontSize: 14, color: textGray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: lightBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 64,
                color: textGray,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay reservas ${_getEstadoLabel(filtroEstado)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: darkNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Para el bus seleccionado',
              style: TextStyle(fontSize: 14, color: textGray),
            ),
          ],
        ),
      ),
    );
  }

  String _getEstadoLabel(String estado) {
    switch (estado) {
      case 'pendiente_verificacion':
        return 'pendientes';
      case 'aprobado':
        return 'aprobadas';
      case 'rechazado':
        return 'rechazadas';
      default:
        return estado;
    }
  }

  Widget _buildReservaCard(DocumentSnapshot doc, Map<String, dynamic> data) {
    Color estadoColor = filtroEstado == 'pendiente_verificacion'
        ? warningYellow
        : filtroEstado == 'aprobado'
            ? successGreen
            : accentRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estado y precio
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [estadoColor, estadoColor.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: estadoColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        filtroEstado == 'pendiente_verificacion'
                            ? 'PENDIENTE'
                            : filtroEstado == 'aprobado'
                                ? 'APROBADO'
                                : 'RECHAZADO',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: primaryBusBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: primaryBusBlue.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_seat_rounded,
                            size: 16,
                            color: primaryBusBlue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Asiento ${data['asientos'][0]}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: primaryBusBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [successGreen, successGreen.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: successGreen.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '\$${data['total'].toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 16),

            // Información del cliente
            _buildInfoSection(
              'Información del Cliente',
              Icons.person_outline,
              [
                _buildInfoRow(
                    Icons.badge_outlined, 'Nombre', data['nombreComprador']),
                _buildInfoRow(Icons.credit_card_outlined, 'Cédula',
                    data['cedulaComprador']),
                _buildInfoRow(
                    Icons.phone_outlined, 'Celular', data['celularComprador']),
                _buildInfoRow(Icons.email_outlined, 'Email', data['email']),
                _buildInfoRow(Icons.location_on_outlined, 'Parada',
                    data['paradaNombre'] ?? 'N/A'),
              ],
            ),

            if (data['comprobanteUrl'] != null) ...[
              const SizedBox(height: 20),
              _buildComprobanteSection(data['comprobanteUrl']),
            ],

            if (filtroEstado == 'rechazado' &&
                data['motivoRechazo'] != null) ...[
              const SizedBox(height: 20),
              _buildMotivoRechazo(data['motivoRechazo']),
            ],

            if (filtroEstado == 'pendiente_verificacion') ...[
              const SizedBox(height: 24),
              _buildActionButtons(doc, data),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryBusBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: primaryBusBlue, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: darkNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: textGray),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: textGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: TextStyle(
                fontSize: 13,
                color: darkNavy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComprobanteSection(String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.receipt_long, color: accentOrange, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Comprobante de Transferencia',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: darkNavy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _mostrarComprobanteCompleto(url),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Image.network(
                    url,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(primaryBusBlue),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, size: 48),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.zoom_in, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Toca para ampliar',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
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
      ],
    );
  }

  Widget _buildMotivoRechazo(String motivo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentRed.withOpacity(0.05),
            accentRed.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentRed.withOpacity(0.3), width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.info_outline, color: accentRed, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Motivo del rechazo:',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: accentRed,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  motivo,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: darkNavy,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(DocumentSnapshot doc, Map<String, dynamic> data) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: accentRed,
              side: BorderSide(color: accentRed, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () => _rechazarTransferencia(doc, data),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.close_rounded, size: 20),
                SizedBox(width: 8),
                Text(
                  'Rechazar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: successGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              shadowColor: successGreen.withOpacity(0.4),
            ),
            onPressed: () => _aprobarTransferencia(doc, data),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_rounded, size: 20),
                SizedBox(width: 8),
                Text(
                  'Aprobar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarComprobanteCompleto(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentRed, accentRed.withOpacity(0.9)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentRed.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== APROBAR CON CLOUD FUNCTION ====================
  // ==================== AGREGAR ESTA IMPORTACIÓN AL INICIO DEL ARCHIVO ====================

// ==================== APROBAR CON NOTIFICACIÓN PUSH ====================
  Future<void> _aprobarTransferencia(
      DocumentSnapshot reserva, Map<String, dynamic> data) async {
    try {
      bool? confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: successGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Aprobar Transferencia',
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
                '¿Confirmar el pago del asiento ${data['asientos'][0]}?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: darkNavy,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: lightBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Cliente:', style: TextStyle(color: textGray)),
                        Text(
                          data['nombreComprador'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: darkNavy,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total:', style: TextStyle(color: textGray)),
                        Text(
                          '\$${data['total'].toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: successGreen,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
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
                backgroundColor: successGreen,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Aprobar',
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
            padding: const EdgeInsets.all(32),
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
                const SizedBox(height: 20),
                Text(
                  'Procesando aprobación...',
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

      final busDoc =
          await db.collection(coleccionBuses).doc(data['busId']).get();
      var busData = busDoc.data() as Map<String, dynamic>?;

      String numeroBus = busData?['numero']?.toString() ?? 'N/A';
      String horaSalida = busData?['horaSalida']?.toString() ??
          busData?['hora_salida']?.toString() ??
          'N/A';
      String fechaSalida = busData?['fechaSalida']?.toString() ??
          busData?['fecha_salida']?.toString() ??
          'N/A';
      String lugarSalida = busData?['lugar_salida']?.toString() ?? 'N/A';

      await db.collection('comprados').add({
        'busId': data['busId'],
        'userId': data['userId'],
        'email': data['email'],
        'nombreComprador': data['nombreComprador'],
        'cedulaComprador': data['cedulaComprador'],
        'celularComprador': data['celularComprador'],
        'asientos': data['asientos'],
        'total': data['total'],
        'metodoPago': data['metodoPago'] ?? 'transferencia',
        'comprobanteUrl': data['comprobanteUrl'],
        'fechaCompra': FieldValue.serverTimestamp(),
        'paradaNombre': data['paradaNombre'],
        'reservaId': reserva.id,
        'aprobadoPor': 'admin',
        'estado': 'aprobado',
      });

      await reserva.reference.delete();

      if (busData != null) {
        List<Map<String, dynamic>> asientos =
            List<Map<String, dynamic>>.from(busData['asientos'] ?? []);

        final index =
            asientos.indexWhere((a) => a['numero'] == data['asientos'][0]);
        if (index != -1) {
          asientos[index]['estado'] = 'pagado';
        }

        await db.collection(coleccionBuses).doc(data['busId']).update({
          'asientos': asientos,
        });
      }

      final boletoUrl = await _generarYSubirBoleto(
          data, reserva.id, numeroBus, horaSalida, fechaSalida);

      await db.collection('notificaciones').add({
        'userId': data['userId'],
        'email': data['email'],
        'tipo': 'compra_aprobada',
        'titulo': '✅ Pago Aprobado',
        'mensaje':
            'Tu pago ha sido aprobado. Asiento ${data['asientos'][0]} confirmado para el bus $numeroBus.',
        'reservaId': reserva.id,
        'busId': data['busId'],
        'numeroBus': numeroBus,
        'paradaNombre': data['paradaNombre'],
        'origenNombre': lugarSalida,
        'nombreComprador': data['nombreComprador'],
        'cedulaComprador': data['cedulaComprador'],
        'celularComprador': data['celularComprador'],
        'metodoPago': data['metodoPago'] ?? 'transferencia',
        'estado': 'aprobado',
        'precio': data['total'],
        'total': data['total'],
        'asiento': data['asientos'][0],
        'asientos': data['asientos'],
        'fechaSalida': fechaSalida,
        'horaSalida': horaSalida,
        'boletoUrl': boletoUrl,
        'leida': false,
        'fecha': FieldValue.serverTimestamp(),
        'fechaAprobacion': FieldValue.serverTimestamp(),
        'aprobadoPor': 'admin',
      });

      await db.collection('historial').add({
        'userId': data['userId'],
        'email': data['email'],
        'tipo': 'compra_aprobada',
        'titulo': '✅ Pago Aprobado',
        'mensaje':
            'Tu pago ha sido aprobado. Asiento ${data['asientos'][0]} confirmado para el bus $numeroBus.',
        'reservaId': reserva.id,
        'busId': data['busId'],
        'numeroBus': numeroBus,
        'paradaNombre': data['paradaNombre'],
        'origenNombre': lugarSalida,
        'nombreComprador': data['nombreComprador'],
        'cedulaComprador': data['cedulaComprador'],
        'celularComprador': data['celularComprador'],
        'metodoPago': data['metodoPago'] ?? 'transferencia',
        'estado': 'aprobado',
        'precio': data['total'],
        'total': data['total'],
        'asiento': data['asientos'][0],
        'asientos': data['asientos'],
        'fechaSalida': fechaSalida,
        'horaSalida': horaSalida,
        'boletoUrl': boletoUrl,
        'leida': false,
        'fecha': FieldValue.serverTimestamp(),
        'fechaAprobacion': FieldValue.serverTimestamp(),
        'aprobadoPor': 'admin',
      });

      // 🆕 ==================== ENVIAR NOTIFICACIÓN PUSH ====================
      await _enviarNotificacionPush(
        userId: data['userId'],
        titulo: '✅ Pago Aprobado',
        mensaje:
            'Tu pago ha sido aprobado. Asiento ${data['asientos'][0]} confirmado para el bus $numeroBus.',
      );
      // ====================================================================

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Transferencia aprobada y notificación enviada'),
            ],
          ),
          backgroundColor: successGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al aprobar: $e'),
            backgroundColor: accentRed,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

// ==================== RECHAZAR CON NOTIFICACIÓN PUSH ====================
  Future<void> _rechazarTransferencia(
      DocumentSnapshot reserva, Map<String, dynamic> data) async {
    String? motivo = await showDialog<String>(
      context: context,
      builder: (context) {
        TextEditingController motivoController = TextEditingController();
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.cancel_outlined,
                  color: accentRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Rechazar Transferencia',
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
                '¿Por qué se rechaza este comprobante?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: darkNavy,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: motivoController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ej: Comprobante ilegible, monto incorrecto...',
                  filled: true,
                  fillColor: lightBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: primaryBusBlue, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context, motivoController.text),
              child: const Text(
                'Rechazar',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (motivo == null || motivo.isEmpty) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(32),
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
                const SizedBox(height: 20),
                Text(
                  'Procesando rechazo...',
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

      final busDoc =
          await db.collection(coleccionBuses).doc(data['busId']).get();
      var busData = busDoc.data() as Map<String, dynamic>?;

      String numeroBus = busData?['numero']?.toString() ?? 'N/A';
      String lugarSalida = busData?['lugar_salida']?.toString() ?? 'N/A';

      Map<String, dynamic> reservaRechazada = {
        ...data,
        'estado': 'rechazado',
        'motivoRechazo': motivo,
        'fechaRechazo': FieldValue.serverTimestamp(),
        'reservaIdOriginal': reserva.id,
        'rechazadoPor': 'admin',
      };

      await db.collection('rechazados').add(reservaRechazada);
      await reserva.reference.delete();

      if (busData != null) {
        List<Map<String, dynamic>> asientos =
            List<Map<String, dynamic>>.from(busData['asientos'] ?? []);

        final index =
            asientos.indexWhere((a) => a['numero'] == data['asientos'][0]);
        if (index != -1) {
          asientos[index] = {
            'numero': data['asientos'][0],
            'estado': 'disponible',
          };
        }

        await db.collection(coleccionBuses).doc(data['busId']).update({
          'asientos': asientos,
        });
      }

      await db.collection('notificaciones').add({
        'userId': data['userId'],
        'email': data['email'],
        'tipo': 'compra_rechazada',
        'titulo': '❌ Pago Rechazado',
        'mensaje':
            'Tu pago ha sido rechazado. Asiento ${data['asientos'][0]} del bus $numeroBus. Motivo: $motivo',
        'motivoRechazo': motivo,
        'reservaId': reserva.id,
        'busId': data['busId'],
        'numeroBus': numeroBus,
        'paradaNombre': data['paradaNombre'],
        'origenNombre': lugarSalida,
        'nombreComprador': data['nombreComprador'],
        'cedulaComprador': data['cedulaComprador'],
        'celularComprador': data['celularComprador'],
        'metodoPago': data['metodoPago'] ?? 'transferencia',
        'estado': 'rechazado',
        'precio': data['total'],
        'total': data['total'],
        'asiento': data['asientos'][0],
        'asientos': data['asientos'],
        'leida': false,
        'fecha': FieldValue.serverTimestamp(),
        'fechaRechazo': FieldValue.serverTimestamp(),
        'rechazadoPor': 'admin',
      });

      await db.collection('historial').add({
        'userId': data['userId'],
        'email': data['email'],
        'tipo': 'compra_rechazada',
        'titulo': '❌ Pago Rechazado',
        'mensaje':
            'Tu pago ha sido rechazado. Asiento ${data['asientos'][0]} del bus $numeroBus. Motivo: $motivo',
        'motivoRechazo': motivo,
        'reservaId': reserva.id,
        'busId': data['busId'],
        'numeroBus': numeroBus,
        'paradaNombre': data['paradaNombre'],
        'origenNombre': lugarSalida,
        'nombreComprador': data['nombreComprador'],
        'cedulaComprador': data['cedulaComprador'],
        'celularComprador': data['celularComprador'],
        'metodoPago': data['metodoPago'] ?? 'transferencia',
        'estado': 'rechazado',
        'precio': data['total'],
        'total': data['total'],
        'asiento': data['asientos'][0],
        'asientos': data['asientos'],
        'leida': false,
        'fecha': FieldValue.serverTimestamp(),
        'fechaRechazo': FieldValue.serverTimestamp(),
        'rechazadoPor': 'admin',
      });

      // 🆕 ==================== ENVIAR NOTIFICACIÓN PUSH ====================
      await _enviarNotificacionPush(
        userId: data['userId'],
        titulo: '❌ Pago Rechazado',
        mensaje:
            'Tu pago ha sido rechazado. Asiento ${data['asientos'][0]} del bus $numeroBus. Motivo: $motivo',
      );
      // ====================================================================

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Transferencia rechazada y notificación enviada'),
            ],
          ),
          backgroundColor: warningYellow,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al rechazar: $e'),
            backgroundColor: accentRed,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

// 🆕 ==================== FUNCIÓN PARA ENVIAR NOTIFICACIÓN PUSH ====================
  Future<void> _enviarNotificacionPush({
    required String userId,
    required String titulo,
    required String mensaje,
  }) async {
    try {
      // ✅ SOLO el dominio base
      const String baseUrl = 'https://notificaciones-1hoa.onrender.com';

      // ✅ Endpoint correcto (tal como está en Flask)
      final Uri url = Uri.parse(
        '$baseUrl/api/notifications/send-to-user',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'title': titulo,
          'body': mensaje,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Notificación push enviada correctamente');
        print('📱 Respuesta: ${response.body}');
      } else {
        print('⚠️ Error al enviar notificación push: ${response.statusCode}');
        print('📱 Respuesta: ${response.body}');
      }
    } catch (e) {
      print('❌ Error al enviar notificación push: $e');
    }
  }

  // ==================== RECHAZAR CON CLOUD FUNCTION ====================

  // ==================== GENERAR Y SUBIR BOLETO ====================
  Future<String> _generarYSubirBoleto(
    Map<String, dynamic> data,
    String reservaId,
    String numeroBus,
    String horaSalida,
    String fechaSalida,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue900,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'TRANS DORAMALD',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            'Bus $numeroBus',
                            style: const pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Text(
                          'Asiento\n${data['asientos'][0]}',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            color: PdfColors.blue900,
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'INFORMACIÓN DEL PASAJERO',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Divider(height: 20),
                      _buildPdfInfoRow(
                          'Nombre:', data['nombreComprador'] ?? 'N/A'),
                      _buildPdfInfoRow(
                          'Cédula:', data['cedulaComprador'] ?? 'N/A'),
                      _buildPdfInfoRow(
                          'Celular:', data['celularComprador'] ?? 'N/A'),
                      _buildPdfInfoRow('Email:', data['email'] ?? 'N/A'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'DETALLES DEL VIAJE',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Divider(height: 20),
                      _buildPdfInfoRow('Fecha de salida:', fechaSalida),
                      _buildPdfInfoRow('Hora de salida:', horaSalida),
                      _buildPdfInfoRow(
                          'Parada:', data['paradaNombre'] ?? 'N/A'),
                      _buildPdfInfoRow(
                          'Asiento:', data['asientos'][0].toString()),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    border: pw.Border.all(color: PdfColors.green700),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'TOTAL PAGADO:',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        "\${(data['total'] ?? 0).toStringAsFixed(2)}",
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    final storageRef =
        FirebaseStorage.instance.ref().child('boletos').child('$reservaId.pdf');

    await storageRef.putData(pdfBytes);
    final boletoUrl = await storageRef.getDownloadURL();

    return boletoUrl;
  }

  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== GENERAR REPORTE PDF ====================
  Future<void> _generarReporte() async {
    if (busSeleccionado == null) return;

    const int rojoDoramald = 0xFF940016;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: Container(
            padding: const EdgeInsets.all(32),
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
                const SizedBox(height: 20),
                Text(
                  'Generando reporte...',
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

      final busDoc =
          await db.collection(coleccionBuses).doc(busSeleccionado!).get();
      final busData = busDoc.data() as Map<String, dynamic>?;

      final String numeroBus = busData?['numero']?.toString() ?? 'N/A';

      final reservasAprobadas = await db
          .collection('comprados')
          .where('busId', isEqualTo: busSeleccionado)
          .where('estado', isEqualTo: 'aprobado')
          .where('metodoPago', whereIn: ['transferencia', 'efectivo']).get();

      double totalAprobadas = 0;
      for (var doc in reservasAprobadas.docs) {
        totalAprobadas += (doc.data()['total'] ?? 0).toDouble();
      }

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (_) => [
            pw.SizedBox(height: 24),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border(
                  left: pw.BorderSide(
                    color: PdfColor.fromInt(rojoDoramald),
                    width: 4,
                  ),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'LISTADO DE PASAJEROS',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey900,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Unidad: N° $numeroBus'),
                          pw.Text(
                              'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                              'Hora: ${DateFormat('HH:mm').format(DateTime.now())}'),
                          pw.Text(
                              'Total pasajeros: ${reservasAprobadas.docs.length}'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),
            if (reservasAprobadas.docs.isNotEmpty) ...[
              pw.Text(
                'Detalle de Pasajeros',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
              pw.SizedBox(height: 12),
              _buildTablaPasajeros(reservasAprobadas.docs),
              pw.SizedBox(height: 24),
            ],
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                gradient: const pw.LinearGradient(
                  colors: [PdfColors.green700, PdfColors.green600],
                ),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL RECAUDADO:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.Text(
                    '\$${totalAprobadas.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 32),
            pw.Divider(),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Trans Doramald - Comprometidos con tu viaje',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                  pw.Text(
                    'www.transdoramald.com | contacto@transdoramald.com',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      if (mounted) Navigator.pop(context);

      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name:
            'TransDoramald_Unidad${numeroBus}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar reporte: $e'),
            backgroundColor: accentRed,
          ),
        );
      }
    }
  }

  pw.Widget _buildTablaPasajeros(List<QueryDocumentSnapshot> reservas) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(2),
        5: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFF940016)),
          children: [
            _buildTableHeader('#'),
            _buildTableHeader('Nombre'),
            _buildTableHeader('Cédula'),
            _buildTableHeader('Celular'),
            _buildTableHeader('Parada'),
            _buildTableHeader('Precio'),
          ],
        ),
        ...reservas.asMap().entries.map((entry) {
          int index = entry.key;
          var doc = entry.value;
          var data = doc.data() as Map<String, dynamic>;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: index % 2 == 0 ? PdfColors.grey50 : PdfColors.white,
            ),
            children: [
              _buildTableCell('${index + 1}', alignment: pw.Alignment.center),
              _buildTableCell(data['nombreComprador'] ?? 'N/A'),
              _buildTableCell(data['cedulaComprador'] ?? 'N/A'),
              _buildTableCell(data['celularComprador'] ?? 'N/A'),
              _buildTableCell(data['paradaNombre'] ?? 'N/A'),
              _buildTableCell(
                '\$${(data['total'] ?? 0).toStringAsFixed(2)}',
                alignment: pw.Alignment.centerRight,
                bold: true,
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildTableCell(String text,
      {pw.Alignment? alignment, bool bold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      alignment: alignment ?? pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.grey800,
        ),
      ),
    );
  }
}
