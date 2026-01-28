import 'dart:math';
import 'package:app2tesis/usuario/Encomiendas/datos_encomienda.dart';
import 'package:app2tesis/usuario/Encomiendas/datos_del_destinatario.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RemitenteScreen extends StatefulWidget {
  final EncomiendaData? encomiendaData;

  const RemitenteScreen({super.key, this.encomiendaData});

  @override
  State<RemitenteScreen> createState() => _RemitenteScreenState();
}

class _RemitenteScreenState extends State<RemitenteScreen> {
  // Paleta de colores igual a EncomiendaScreen
  static const Color primaryBusBlue = Color(0xFF940016);
  static const Color accentOrange = Color(0xFFEA580C);
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color roadGray = Color(0xFF334155);
  static const Color lightBg = Color(0xFFF1F5F9);
  static const Color textGray = Color(0xFF475569);
  static const Color successGreen = Color(0xFF059669);
  static const Color warningRed = Color(0xFFEF4444);
  String? _currentUserUid; // ✅ NUEVO
  // Controladores
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _lugarSalidaController = TextEditingController();

  late EncomiendaData _encomiendaData;
  bool _isLoadingUserData = true;

  @override
  void initState() {
    super.initState();
    // ✅ Capturar UID inmediatamente
    _currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    // Si ya hay datos, los cargamos; si no, creamos uno nuevo
    if (widget.encomiendaData != null) {
      _encomiendaData = widget.encomiendaData!;
      _nombreController.text = _encomiendaData.nombreRemitente ?? '';
      _cedulaController.text = _encomiendaData.cedulaRemitente ?? '';
      _telefonoController.text = _encomiendaData.telefonoRemitente ?? '';
      _correoController.text = _encomiendaData.correoRemitente ?? '';
      _lugarSalidaController.text = _encomiendaData.lugarSalida ?? '';
      _isLoadingUserData = false;
    } else {
      _encomiendaData = EncomiendaData(
        codigoEnvio: _generarCodigoEnvio(),
      );
      _cargarDatosUsuario();
    }

    _loadParadasSalida();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Cargar correo del usuario autenticado
        _correoController.text = user.email ?? '';

        // Intentar cargar datos adicionales desde Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('usuarios_registrados')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null) {
            _nombreController.text = data['nombre'] ?? '';
            _cedulaController.text = data['cedula'] ?? '';
            _telefonoController.text = data['telefono'] ?? '';
            _lugarSalidaController.text = data['direccion'] ?? '';
          }
        }
      }
    } catch (e) {
      print('Error al cargar datos del usuario: $e');
    } finally {
      setState(() {
        _isLoadingUserData = false;
      });
    }
  }

  String _generarCodigoEnvio() {
    final random = Random();
    final numero = random.nextInt(999999).toString().padLeft(6, '0');
    return 'ENC-$numero';
  }

  bool _validarFormulario() {
    if (_nombreController.text.trim().isEmpty) {
      _mostrarError('Ingrese el nombre completo');
      return false;
    }
    if (_cedulaController.text.trim().isEmpty) {
      _mostrarError('Ingrese la cédula');
      return false;
    }
    if (_cedulaController.text.trim().length != 10) {
      _mostrarError('La cédula debe tener 10 dígitos');
      return false;
    }
    if (_telefonoController.text.trim().isEmpty) {
      _mostrarError('Ingrese el teléfono');
      return false;
    }
    if (_telefonoController.text.trim().length != 10) {
      _mostrarError('El teléfono debe tener 10 dígitos');
      return false;
    }
    if (_correoController.text.trim().isEmpty) {
      _mostrarError('Ingrese el correo electrónico');
      return false;
    }
    if (!_correoController.text.contains('@')) {
      _mostrarError('Ingrese un correo válido');
      return false;
    }
    if (_lugarSalidaController.text.trim().isEmpty) {
      _mostrarError('Ingrese el lugar de salida');
      return false;
    }
    return true;
  }

  void _guardarYContinuar() {
    if (!_validarFormulario()) return;
    _encomiendaData.uid = _currentUserUid; // NUEVO
    // Guardar datos en el modelo
    _encomiendaData.nombreRemitente = _nombreController.text.trim();
    _encomiendaData.cedulaRemitente = _cedulaController.text.trim();
    _encomiendaData.telefonoRemitente = _telefonoController.text.trim();
    _encomiendaData.correoRemitente = _correoController.text.trim();
    _encomiendaData.lugarSalida = _lugarSalidaController.text.trim();

    // Navegar a la pantalla del destinatario
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DestinatarioScreen(encomiendaData: _encomiendaData),
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
    _lugarSalidaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 248, 255),
      body: _isLoadingUserData
          ? _buildLoadingScreen()
          : CustomScrollView(
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
                      _buildContinueButton(),
                      const SizedBox(height: 20),
                      _buildInfoNote(),
                      SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 16),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryBusBlue),
          const SizedBox(height: 16),
          Text(
            'Cargando datos del usuario...',
            style: TextStyle(
              fontSize: 14,
              color: textGray,
              fontWeight: FontWeight.w500,
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
                                color: const Color.fromARGB(0, 245, 243, 243)
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
                            'Código: ${_encomiendaData.codigoEnvio}',
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
                      color: const Color.fromARGB(0, 253, 253, 253)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: Color(0xFF940016),
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'Datos del Remitente',
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
                'Información de la persona que envía el paquete',
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
                  _buildStatChip(Icons.verified_user_rounded, 'Seguro'),
                  const SizedBox(width: 10),
                  _buildStatChip(Icons.lock_rounded, 'Privado'),
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
        color: primaryBusBlue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primaryBusBlue, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryBusBlue,
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
          _buildStepIndicator(1, 'Remitente', true, false),
          _buildProgressLine(false),
          _buildStepIndicator(2, 'Destinatario', false, false),
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
                      color: primaryBusBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: primaryBusBlue,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Completa todos los campos marcados con *',
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
            _buildTextField(
              controller: _nombreController,
              label: 'Nombre completo',
              hint: 'Ej: Juan Pérez García',
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
              isRequired: true,
              keyboardType: TextInputType.emailAddress,
              enabled: false, // Deshabilitado porque viene de Firebase Auth
              suffixIcon: const Icon(
                Icons.lock_outline,
                size: 18,
                color: textGray,
              ),
            ),
            const SizedBox(height: 16),
            _buildParadaSalidaDropdown(),
          ],
        ),
      ),
    );
  }

// Variables para las paradas de salida
  List<String> _paradasSalida = [];
  String? _selectedParadaSalida;
  bool _isLoadingParadas = true;

// Método para cargar las paradas desde Firestore
  Future<void> _loadParadasSalida() async {
    try {
      setState(() {
        _isLoadingParadas = true;
      });

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('lugares_salida')
          .orderBy('lugar')
          .get();

      setState(() {
        _paradasSalida =
            snapshot.docs.map((doc) => doc['lugar'] as String).toList();
        _isLoadingParadas = false;
      });
    } catch (e) {
      print('Error al cargar paradas: $e');
      setState(() {
        _isLoadingParadas = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar las paradas de salida')),
      );
    }
  }

// Widget para el dropdown de paradas de salida
  Widget _buildParadaSalidaDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on_outlined, color: Colors.blue, size: 20),
            SizedBox(width: 8),
            Text(
              'Lugar de salida',
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
                    hintText: 'Seleccione el lugar de salida',
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
                      _lugarSalidaController.text = newValue ?? '';
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    bool enabled = true,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: primaryBusBlue),
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
          enabled: enabled,
          style: TextStyle(
            fontSize: 14,
            color: enabled ? darkNavy : textGray,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: textGray.withOpacity(0.5),
              fontSize: 13,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled ? lightBg : Colors.grey.shade100,
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
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryBusBlue, width: 2),
            ),
            counterText: '',
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF940016), Color(0xFF940016)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryBusBlue.withOpacity(0.3),
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
              'Continuar al Destinatario',
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
            successGreen.withOpacity(0.05),
            primaryBusBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryBusBlue.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: successGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.security_rounded,
              color: successGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Información Segura',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: darkNavy,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tus datos están protegidos y solo se usarán para el seguimiento de tu encomienda.',
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
