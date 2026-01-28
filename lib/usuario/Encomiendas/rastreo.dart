import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RastreoEncomiendaScreen extends StatefulWidget {
  const RastreoEncomiendaScreen({Key? key}) : super(key: key);

  @override
  State<RastreoEncomiendaScreen> createState() =>
      _RastreoEncomiendaScreenState();
}

class _RastreoEncomiendaScreenState extends State<RastreoEncomiendaScreen> {
  // Paleta de colores
  static const Color primaryBusBlue = Color(0xFF940016);
  static const Color accentOrange = Color(0xFFEA580C);
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color roadGray = Color(0xFF334155);
  static const Color lightBg = Color(0xFFF1F5F9);
  static const Color textGray = Color(0xFF475569);
  static const Color successGreen = Color(0xFF059669);

  final TextEditingController _codigoController = TextEditingController();
  Map<String, dynamic>? _encomiendaData;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _buscarEncomienda() async {
    if (_codigoController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Por favor ingresa un código de envío';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _encomiendaData = null;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('encomiendas_registradas')
          .where('codigo_envio',
              isEqualTo: _codigoController.text.trim().toUpperCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _encomiendaData = querySnapshot.docs.first.data();
          _isLoading = false;
        });

        // Debug: imprimir la estructura de datos
        print('=== DATOS DE ENCOMIENDA ===');
        print('Estado: ${_encomiendaData!['estado']}');
        print('Imagenes: ${_encomiendaData!['imagenes']}');
        print('Transporte: ${_encomiendaData!['transporte']}');
      } else {
        setState(() {
          _errorMessage = 'No se encontró ninguna encomienda con ese código';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al buscar la encomienda: $e';
        _isLoading = false;
      });
      print('Error detallado: $e');
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return accentOrange;
      case 'bus_asignado':
        return primaryBusBlue;
      case 'en_transito':
      case 'en transito':
        return accentOrange;
      case 'entregado':
        return successGreen;
      case 'cancelado':
        return Colors.red.shade600;
      default:
        return roadGray;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Icons.schedule_rounded;
      case 'bus_asignado':
        return Icons.directions_bus_rounded;
      case 'en_transito':
      case 'en transito':
        return Icons.local_shipping_rounded;
      case 'entregado':
        return Icons.check_circle_rounded;
      case 'cancelado':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _getEstadoTexto(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return 'PENDIENTE';
      case 'bus_asignado':
        return 'BUS ASIGNADO';
      case 'en_transito':
      case 'en transito':
        return 'EN TRÁNSITO';
      case 'entregado':
        return 'ENTREGADO';
      case 'cancelado':
        return 'CANCELADO';
      default:
        return estado.toUpperCase();
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
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSearchCard(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorCard(),
                ],
                if (_encomiendaData != null) ...[
                  const SizedBox(height: 20),
                  _buildResultados(),
                ],
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ]),
            ),
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
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
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
                            'RASTREO',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color.fromARGB(255, 26, 25, 25),
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Seguimiento de envíos',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color.fromARGB(255, 76, 77, 78),
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
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: Color(0xFF940016),
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'Rastrea tu Paquete',
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
                'Ingresa tu código de seguimiento para conocer el estado de tu envío',
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
                  _buildStatChip(Icons.visibility_rounded, 'En tiempo real'),
                  const SizedBox(width: 10),
                  _buildStatChip(Icons.verified_rounded, 'Preciso'),
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
        color: const Color.fromARGB(255, 66, 58, 58).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 46, 44, 44),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
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
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: primaryBusBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: primaryBusBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buscar Encomienda',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: darkNavy,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Ingresa el código',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primaryBusBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codigoController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: darkNavy,
              ),
              decoration: InputDecoration(
                labelText: 'Código de Envío',
                hintText: 'ENC-123456',
                hintStyle: TextStyle(
                  color: textGray.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(
                  Icons.confirmation_number_rounded,
                  color: primaryBusBlue,
                ),
                filled: true,
                fillColor: lightBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryBusBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onSubmitted: (_) => _buscarEncomienda(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _buscarEncomienda,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBusBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_rounded, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            _isLoading ? 'Buscando...' : 'Buscar Encomienda',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
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

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: Colors.red.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.shade900,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultados() {
    final estado = _encomiendaData!['estado'] ?? 'pendiente';
    final remitente = _encomiendaData!['remitente'] ?? {};
    final destinatario = _encomiendaData!['destinatario'] ?? {};
    final envio = _encomiendaData!['envio'] ?? {};
    final costos = _encomiendaData!['costos'] ?? {};
    final imagenes = _encomiendaData!['imagenes'] ?? {};
    final transporte = _encomiendaData!['transporte'] ?? {};
    final entrega = _encomiendaData!['entrega'] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Estado del envío
        _buildEstadoCard(estado),
        const SizedBox(height: 16),

        // Línea de tiempo del seguimiento
        _buildTimelineCard(),
        const SizedBox(height: 16),

        // IMÁGENES
        if (imagenes['entregada'] != null &&
            imagenes['entregada'].toString().isNotEmpty) ...[
          _buildImagenCard('Paquete Entregado', imagenes['entregada']),
          const SizedBox(height: 16),
        ],
        if (imagenes['transito'] != null &&
            imagenes['transito'].toString().isNotEmpty) ...[
          _buildImagenCard('Transito', imagenes['transito']),
          const SizedBox(height: 16),
        ],
        if (imagenes['paquete'] != null &&
            imagenes['paquete'].toString().isNotEmpty) ...[
          _buildImagenCard('Paquete', imagenes['paquete']),
          const SizedBox(height: 16),
        ],

        // Información del bus asignado
        if (transporte.isNotEmpty &&
            (transporte['bus_asignado'] != null ||
                transporte['numero_bus'] != null ||
                transporte['placa'] != null)) ...[
          _buildBusAsignadoCard(transporte),
          const SizedBox(height: 16),
        ],

        // Remitente
        _buildInfoCard(
          'Remitente',
          Icons.person_outline_rounded,
          primaryBusBlue,
          [
            _buildInfoRow('Nombre', remitente['nombre'] ?? 'N/A'),
            _buildInfoRow('Cédula', remitente['cedula'] ?? 'N/A'),
            _buildInfoRow('Teléfono', remitente['telefono'] ?? 'N/A'),
            _buildInfoRow('Correo', remitente['correo'] ?? 'N/A'),
            _buildInfoRow('Origen', remitente['lugar_salida'] ?? 'N/A'),
          ],
        ),
        const SizedBox(height: 16),

        // Destinatario
        _buildInfoCard(
          'Destinatario',
          Icons.location_on_outlined,
          successGreen,
          [
            _buildInfoRow('Nombre', destinatario['nombre'] ?? 'N/A'),
            if (destinatario['cedula'] != null)
              _buildInfoRow('Cédula', destinatario['cedula']),
            _buildInfoRow('Teléfono', destinatario['telefono'] ?? 'N/A'),
            if (destinatario['correo'] != null)
              _buildInfoRow('Correo', destinatario['correo']),
            _buildInfoRow('Ciudad', destinatario['ciudad'] ?? 'N/A'),
            if (destinatario['direccion'] != null)
              _buildInfoRow('Dirección', destinatario['direccion']),
          ],
        ),
        const SizedBox(height: 16),

        // Detalles del envío
        _buildInfoCard(
          'Detalles del Envío',
          Icons.inventory_2_outlined,
          accentOrange,
          [
            _buildInfoRow('Tipo', envio['tipo_encomienda'] ?? 'N/A'),
            _buildInfoRow('Peso', '${envio['rango_peso'] ?? 'N/A'} kg'),
            if (envio['observaciones'] != null &&
                envio['observaciones'].toString().isNotEmpty)
              _buildInfoRow('Observaciones', envio['observaciones']),
            _buildInfoRow(
                'Unidad designada', '${_encomiendaData!['numero'] ?? 'N/A'}'),
          ],
        ),
        const SizedBox(height: 16),

        // Costos
        _buildCostosCard(costos, envio),
        const SizedBox(height: 16),

        // Información de entrega (si existe)
        if (entrega.isNotEmpty && entrega['fecha_entrega'] != null) ...[
          _buildEntregaCard(entrega),
          const SizedBox(height: 16),
        ],

        // Imagen de entrega (si existe)
        if (imagenes['entrega'] != null &&
            imagenes['entrega'].toString().isNotEmpty) ...[
          _buildImagenCard('Comprobante de Entrega', imagenes['entrega']),
          const SizedBox(height: 16),
        ],

        // Fecha de creación
        _buildFechaCard(),
      ],
    );
  }

  Widget _buildTimelineCard() {
    final estado =
        (_encomiendaData!['estado'] ?? 'pendiente').toString().toLowerCase();
    final transporte = _encomiendaData!['transporte'] ?? {};
    final entrega = _encomiendaData!['entrega'] ?? {};

    // Determinar qué pasos están completados basándose en el estado
    bool registroCompleto = true; // Siempre está completo
    bool busAsignadoCompleto = false;
    bool enTransitoCompleto = false;
    bool entregadoCompleto = false;

    // Lógica de completado según el estado
    if (estado == 'pendiente') {
      // Solo registro completado
      registroCompleto = true;
    } else if (estado == 'bus_asignado' ||
        estado == 'en_transito' ||
        estado == 'en transito' ||
        estado == 'entregado') {
      // Si tiene bus asignado o más avanzado
      registroCompleto = true;
      busAsignadoCompleto = true;

      if (estado == 'en_transito' ||
          estado == 'en transito' ||
          estado == 'entregado') {
        enTransitoCompleto = true;
      }

      if (estado == 'entregado') {
        entregadoCompleto = true;
      }
    }

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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryBusBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.timeline_rounded,
                    color: primaryBusBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Línea de Tiempo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: darkNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 1. Registro Creado (siempre completado)
            _buildTimelineItem(
              'Registro Creado',
              _formatTimestamp(_encomiendaData!['fecha_creacion']),
              Icons.add_circle_outline_rounded,
              registroCompleto,
              successGreen,
            ),

            // 2. Bus Asignado
            _buildTimelineItem(
              'Bus Asignado',
              busAsignadoCompleto && transporte['fecha_asignacion'] != null
                  ? _formatTimestamp(transporte['fecha_asignacion'])
                  : 'Esperando asignación',
              Icons.directions_bus_rounded,
              busAsignadoCompleto,
              primaryBusBlue,
            ),

            // 3. En Tránsito
            _buildTimelineItem(
              'En Tránsito',
              enTransitoCompleto && transporte['fecha_salida'] != null
                  ? _formatTimestamp(transporte['fecha_salida'])
                  : 'Esperando salida',
              Icons.local_shipping_rounded,
              enTransitoCompleto,
              accentOrange,
            ),

            // 4. Entregado
            _buildTimelineItem(
              'Entregado',
              entregadoCompleto && entrega['fecha_entrega'] != null
                  ? _formatTimestamp(entrega['fecha_entrega'])
                  : 'Pendiente de entrega',
              Icons.check_circle_rounded,
              entregadoCompleto,
              successGreen,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String subtitle,
    IconData icon,
    bool isCompleted,
    Color color, {
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted ? color : Colors.grey.shade300,
                  shape: BoxShape.circle,
                  boxShadow: isCompleted
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isCompleted ? color : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isCompleted ? darkNavy : textGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isCompleted ? textGray : Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusAsignadoCard(Map<String, dynamic> transporte) {
    final numeroBus = transporte['numero'] ??
        transporte['numero'] ??
        transporte['bus'] ??
        'N/A';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryBusBlue.withOpacity(0.1),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBusBlue.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: primaryBusBlue.withOpacity(0.1),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryBusBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_bus_filled_rounded,
                    color: primaryBusBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bus Asignado',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: darkNavy,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Información del transporte',
                        style: TextStyle(
                          fontSize: 12,
                          color: textGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    'Número de Bus',
                    numeroBus.toString(),
                    isBold: true,
                  ),
                  if (transporte['placa'] != null)
                    _buildInfoRow('Placa', transporte['placa']),
                  if (transporte['conductor'] != null)
                    _buildInfoRow('Conductor', transporte['conductor']),
                  if (transporte['ruta'] != null)
                    _buildInfoRow('Ruta', transporte['ruta']),
                  if (transporte['fecha_asignacion'] != null)
                    _buildInfoRow(
                      'Asignado el',
                      _formatTimestamp(transporte['fecha_asignacion']),
                    ),
                  if (transporte['fecha_salida'] != null)
                    _buildInfoRow(
                      'Salida',
                      _formatTimestamp(transporte['fecha_salida']),
                    ),
                  if (transporte['hora_estimada_llegada'] != null)
                    _buildInfoRow(
                      'Llegada Estimada',
                      transporte['hora_estimada_llegada'].toString(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntregaCard(Map<String, dynamic> entrega) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            successGreen.withOpacity(0.1),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: successGreen.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: successGreen.withOpacity(0.1),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: successGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: successGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Entrega Completada',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: darkNavy,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Detalles de la entrega',
                        style: TextStyle(
                          fontSize: 12,
                          color: textGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    'Fecha de Entrega',
                    _formatTimestamp(entrega['fecha_entrega']),
                    isBold: true,
                  ),
                  if (entrega['recibido_por'] != null)
                    _buildInfoRow('Recibido por', entrega['recibido_por']),
                  if (entrega['cedula_receptor'] != null)
                    _buildInfoRow(
                        'Cédula Receptor', entrega['cedula_receptor']),
                  if (entrega['parentesco'] != null)
                    _buildInfoRow('Parentesco', entrega['parentesco']),
                  if (entrega['observaciones'] != null &&
                      entrega['observaciones'].toString().isNotEmpty)
                    _buildInfoRow('Observaciones', entrega['observaciones']),
                  if (entrega['entregado_por'] != null)
                    _buildInfoRow('Entregado por', entrega['entregado_por']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoCard(String estado) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getEstadoColor(estado).withOpacity(0.1),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getEstadoColor(estado).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: _getEstadoColor(estado).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _getEstadoColor(estado).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getEstadoIcon(estado),
                  color: _getEstadoColor(estado),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estado del Envío',
                      style: TextStyle(
                        color: textGray,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getEstadoTexto(estado),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _getEstadoColor(estado),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: lightBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.confirmation_number_rounded,
                  color: darkNavy,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  _encomiendaData!['codigo_envio'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: darkNavy,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagenCard(String titulo, String imageUrl) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryBusBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: primaryBusBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: darkNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 220,
                  color: lightBg,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_rounded,
                        size: 50,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No se pudo cargar la imagen',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 220,
                  color: lightBg,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: primaryBusBlue,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
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
        padding: const EdgeInsets.all(16),
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
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: darkNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: lightBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(children: children),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
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
                color: textGray,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: isBold ? darkNavy : roadGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostosCard(
      Map<String, dynamic> costos, Map<String, dynamic> envio) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade50,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.attach_money_rounded,
                    color: Colors.purple.shade700,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Costos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: darkNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    'Peso',
                    '${envio['rango_peso'] ?? 0} kg',
                  ),
                  _buildInfoRow(
                    'Precio encomienda',
                    '\$${costos['precio_tipo'] ?? 0}',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(thickness: 1),
                  ),
                  _buildInfoRow(
                    'TOTAL',
                    '\$${costos['total'] ?? 0}',
                    isBold: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFechaCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: lightBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: roadGray,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fecha de Registro',
                  style: TextStyle(
                    color: textGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(_encomiendaData!['fecha_creacion']),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: darkNavy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }

      if (timestamp is String) {
        try {
          final date = DateTime.parse(timestamp);
          return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        } catch (e) {
          return timestamp;
        }
      }

      return timestamp.toString();
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }
}
