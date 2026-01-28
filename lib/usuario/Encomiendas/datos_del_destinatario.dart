import 'package:app2tesis/usuario/Encomiendas/datos_encomienda.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DestinatarioScreen extends StatefulWidget {
  final EncomiendaData encomiendaData;

  const DestinatarioScreen({super.key, required this.encomiendaData});

  @override
  State<DestinatarioScreen> createState() => _DestinatarioScreenState();
}

class _DestinatarioScreenState extends State<DestinatarioScreen> {
  // Paleta de colores igual a las pantallas anteriores
  static const Color primaryBusBlue = Color(0xFF940016);
  static const Color accentOrange = Color(0xFF940016);
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color roadGray = Color(0xFF334155);
  static const Color lightBg = Color(0xFFF1F5F9);
  static const Color textGray = Color(0xFF475569);
  static const Color successGreen = Color(0xFF059669);
  static const Color warningRed = Color(0xFFEF4444);

  // Controladores
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _ciudadController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  final TextEditingController _lugarSalidaController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Cargar datos si ya existen
    _nombreController.text = widget.encomiendaData.nombreDestinatario ?? '';
    _cedulaController.text = widget.encomiendaData.cedulaDestinatario ?? '';
    _telefonoController.text = widget.encomiendaData.telefonoDestinatario ?? '';
    _correoController.text = widget.encomiendaData.correoDestinatario ?? '';
    _ciudadController.text = widget.encomiendaData.ciudadDestino ?? '';
    _direccionController.text =
        widget.encomiendaData.direccionDestinatario ?? '';
    _referenciaController.text =
        widget.encomiendaData.referenciaDestinatario ?? '';

    _loadParadasSalida();
  }

  bool _validarFormulario() {
    if (_nombreController.text.trim().isEmpty) {
      _mostrarError('Ingrese el nombre completo del destinatario');
      return false;
    }
    if (_cedulaController.text.trim().isEmpty) {
      _mostrarError('Ingrese la cédula del destinatario');
      return false;
    }
    if (_cedulaController.text.trim().length != 10) {
      _mostrarError('La cédula debe tener 10 dígitos');
      return false;
    }
    if (_telefonoController.text.trim().isEmpty) {
      _mostrarError('Ingrese el teléfono del destinatario');
      return false;
    }
    if (_telefonoController.text.trim().length != 10) {
      _mostrarError('El teléfono debe tener 10 dígitos');
      return false;
    }
    if (_ciudadController.text.trim().isEmpty) {
      _mostrarError('Ingrese la  destino');
      return false;
    }
    if (_direccionController.text.trim().isEmpty) {
      _mostrarError('Ingrese la dirección de entrega');
      return false;
    }
    return true;
  }

  void _guardarYContinuar() {
    if (!_validarFormulario()) return;

    // Guardar datos en el modelo
    widget.encomiendaData.nombreDestinatario = _nombreController.text.trim();
    widget.encomiendaData.cedulaDestinatario = _cedulaController.text.trim();
    widget.encomiendaData.telefonoDestinatario =
        _telefonoController.text.trim();
    widget.encomiendaData.correoDestinatario = _correoController.text.trim();
    widget.encomiendaData.ciudadDestino = _ciudadController.text.trim();
    widget.encomiendaData.direccionDestinatario =
        _direccionController.text.trim();
    widget.encomiendaData.referenciaDestinatario =
        _referenciaController.text.trim();

    // Navegar a la pantalla del envío
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnvioScreen(encomiendaData: widget.encomiendaData),
      ),
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
    _nombreController.dispose();
    _cedulaController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _ciudadController.dispose();
    _direccionController.dispose();
    _referenciaController.dispose();
    _lugarSalidaController.dispose();
    super.dispose();
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
            child: _buildProgressIndicator(),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildFormCard(),
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
                      Icons.markunread_mailbox_rounded,
                      color: Color(0xFF940016),
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'Datos del Destinatario',
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
                'Información completa de quien recibirá el paquete',
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
                  _buildStatChip(Icons.location_on_rounded, 'Destino'),
                  const SizedBox(width: 10),
                  _buildStatChip(Icons.verified_rounded, 'Verificado'),
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
          _buildStepIndicator(2, 'Destinatario', true, false),
          _buildProgressLine(false),
          _buildStepIndicator(3, 'Envío', false, false),
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

            // Sección: Información Personal
            _buildSectionTitle('Información Personal', Icons.person_rounded),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _nombreController,
              label: 'Nombre completo',
              hint: 'Ej: María González López',
              icon: Icons.badge_outlined,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _cedulaController,
              label: 'Cédula',
              hint: 'Ej: 1234567890',
              icon: Icons.credit_card_outlined,
              isRequired: true,
              keyboardType: TextInputType.number,
              maxLength: 10,
            ),

            const SizedBox(height: 24),
            const Divider(thickness: 1),
            const SizedBox(height: 24),

            // Sección: Contacto
            _buildSectionTitle(
                'Información de Contacto', Icons.contact_phone_rounded),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _telefonoController,
              label: 'Teléfono',
              hint: 'Ej: 0999999999',
              icon: Icons.phone_outlined,
              isRequired: true,
              keyboardType: TextInputType.phone,
              maxLength: 10,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _correoController,
              label: 'Correo electrónico',
              hint: 'Ej: correo@ejemplo.com',
              icon: Icons.email_outlined,
              isRequired: false,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 24),
            const Divider(thickness: 1),
            const SizedBox(height: 24),

            // Sección: Ubicación de Entrega
            _buildSectionTitle(
                'Ubicación de Entrega', Icons.location_on_rounded),
            const SizedBox(height: 16),

            _buildParadaSalidaDropdown(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _direccionController,
              label: 'Dirección completa',
              hint: 'Calle principal, número de casa, sector',
              icon: Icons.home_outlined,
              isRequired: true,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

// Al inicio de tu clase State, agrega estas variables
  List<String> _paradasSalida = [];
  String? _selectedParadaSalida;
  bool _isLoadingParadas = true;

// Agrega este método para cargar las paradas desde Firestore
  Future<void> _loadParadasSalida() async {
    try {
      setState(() {
        _isLoadingParadas = true;
      });

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('paradas_salida_tulcan')
          .orderBy('nombre')
          .get();

      setState(() {
        _paradasSalida =
            snapshot.docs.map((doc) => doc['nombre'] as String).toList();
        _isLoadingParadas = false;
      });
    } catch (e) {
      print('Error al cargar destino: $e');
      setState(() {
        _isLoadingParadas = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los destinos')),
      );
    }
  }

// Reemplaza tu _buildTextField por este widget
  Widget _buildParadaSalidaDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on_outlined, color: Colors.blue, size: 20),
            SizedBox(width: 8),
            Text(
              'Lugar de entrega',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            Text(
              ' *',
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          ],
        ),
        SizedBox(height: 8),
        _isLoadingParadas
            ? Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Cargando paradas...'),
                  ],
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedParadaSalida,
                  decoration: InputDecoration(
                    hintText: 'Seleccione el lugar de entrega',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  isExpanded: true,
                  items: _paradasSalida.map((String parada) {
                    return DropdownMenuItem<String>(
                      value: parada,
                      child: Text(parada),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedParadaSalida = newValue;
                      _ciudadController.text = newValue ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor seleccione un lugar de salida';
                    }
                    return null;
                  },
                ),
              ),
      ],
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
              onPressed: () => Navigator.pop(context),
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
                  color: Color(0xFF940016).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _guardarYContinuar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Siguiente',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
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
              Icons.verified_user_rounded,
              color: accentOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verificación de Entrega',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: darkNavy,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'El destinatario deberá presentar su cédula al momento de recibir el paquete para verificar su identidad.',
                  style: TextStyle(
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
