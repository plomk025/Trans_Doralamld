import 'package:app2tesis/usuario/compra_de_boletos/De_ida/pagos_desde_tulcan.dart';
import 'package:app2tesis/usuario/compra_de_boletos/De_regreso/pagos_desde_esperanza.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ==================== PANTALLA DE DATOS DEL COMPRADOR ====================
class DatosCompradorScreen2 extends StatefulWidget {
  final String busId;
  final int asientoSeleccionado;
  final double total;
  final String userId;
  final String paradaNombre;
  final String userEmail;

  const DatosCompradorScreen2({
    Key? key,
    required this.busId,
    required this.asientoSeleccionado,
    required this.total,
    required this.userId,
    required this.paradaNombre,
    required this.userEmail,
  }) : super(key: key);

  @override
  _DatosCompradorScreen2State createState() => _DatosCompradorScreen2State();
}

class _DatosCompradorScreen2State extends State<DatosCompradorScreen2>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();

  final FocusNode _nombreFocus = FocusNode();
  final FocusNode _cedulaFocus = FocusNode();
  final FocusNode _celularFocus = FocusNode();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;
  String _paisSeleccionado = 'Ecuador'; // País por defecto

  // Lista de países disponibles
  final List<String> _paises = [
    'Ecuador',
    'Colombia',
    'Perú',
    'Venezuela',
    'Otro',
  ];

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
    _nombreController.dispose();
    _cedulaController.dispose();
    _celularController.dispose();
    _nombreFocus.dispose();
    _cedulaFocus.dispose();
    _celularFocus.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _continuar() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      setState(() => _isLoading = true);

      Future.delayed(const Duration(milliseconds: 300), () async {
        if (mounted) {
          setState(() => _isLoading = false);

          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PagoScreen2(
                busId: widget.busId,
                asientoSeleccionado: widget.asientoSeleccionado,
                total: widget.total,
                userId: widget.userId,
                paradaNombre: widget.paradaNombre,
                userEmail: widget.userEmail,
                nombreComprador: _nombreController.text.trim(),
                cedulaComprador: _cedulaController.text.trim(),
                celularComprador: _celularController.text.trim(),
              ),
            ),
          );

          if (mounted && resultado == true) {
            Navigator.of(context).pop(true);
          }
        }
      });
    }
  }

  // Obtener configuración según el país seleccionado
  Map<String, dynamic> _getConfiguracionPais() {
    switch (_paisSeleccionado) {
      case 'Ecuador':
        return {
          'labelDocumento': 'Cédula de Identidad',
          'hintDocumento': '0000000000',
          'maxLengthDocumento': 10,
          'labelTelefono': 'Número de Celular',
          'hintTelefono': '0900000000',
          'maxLengthTelefono': 10,
          'prefijoTelefono': '09',
        };
      case 'Colombia':
        return {
          'labelDocumento': 'Cédula de Ciudadanía',
          'hintDocumento': '1000000000',
          'maxLengthDocumento': 10,
          'labelTelefono': 'Número de Celular',
          'hintTelefono': '3001234567',
          'maxLengthTelefono': 10,
          'prefijoTelefono': '3',
        };
      case 'Perú':
        return {
          'labelDocumento': 'DNI',
          'hintDocumento': '00000000',
          'maxLengthDocumento': 8,
          'labelTelefono': 'Número de Celular',
          'hintTelefono': '900000000',
          'maxLengthTelefono': 9,
          'prefijoTelefono': '9',
        };
      case 'Venezuela':
        return {
          'labelDocumento': 'Cédula de Identidad',
          'hintDocumento': '12345678',
          'maxLengthDocumento': 8,
          'labelTelefono': 'Número de Celular',
          'hintTelefono': '4121234567',
          'maxLengthTelefono': 10,
          'prefijoTelefono': '4',
        };
      default: // Otro
        return {
          'labelDocumento': 'Documento de Identidad',
          'hintDocumento': 'Ingresa tu documento',
          'maxLengthDocumento': 15,
          'labelTelefono': 'Número de Teléfono',
          'hintTelefono': 'Ingresa tu número',
          'maxLengthTelefono': 15,
          'prefijoTelefono': null,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBusBlue,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildHeader(),
          _buildInfoCard(),
          _buildFormSection(),
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
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DATOS DEL PASAJERO',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color.fromARGB(255, 36, 35, 35),
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                'Completa tu información',
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
                                color: const Color.fromARGB(0, 255, 255, 255)
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
                    'Información del Pasajero',
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
                      'Completa tus datos personales para generar tu boleto',
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
                        Icons.event_seat_rounded,
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
                            'Asiento ${widget.asientoSeleccionado}',
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
                        '${widget.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'USD',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: successGreen.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    final config = _getConfiguracionPais();

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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datos Personales',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: darkNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingresa tu información para el boleto',
                    style: TextStyle(
                      fontSize: 13,
                      color: textGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Selector de País
                  _buildPaisSelector(),

                  const SizedBox(height: 20),

                  // Campo Nombre
                  _buildTextField(
                    controller: _nombreController,
                    focusNode: _nombreFocus,
                    label: 'Nombre Completo',
                    hint: 'Ingresa tu nombre completo',
                    icon: Icons.person_outline_rounded,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre es requerido';
                      }
                      if (value.trim().length < 3) {
                        return 'El nombre debe tener al menos 3 caracteres';
                      }
                      if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$')
                          .hasMatch(value)) {
                        return 'El nombre solo puede contener letras';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_cedulaFocus);
                    },
                  ),

                  const SizedBox(height: 20),

                  // Campo Documento (Cédula/DNI/etc.)
                  _buildTextField(
                    controller: _cedulaController,
                    focusNode: _cedulaFocus,
                    label: config['labelDocumento'],
                    hint: config['hintDocumento'],
                    icon: Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                    maxLength: config['maxLengthDocumento'],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El documento es requerido';
                      }

                      // Validación específica por país
                      if (_paisSeleccionado == 'Ecuador') {
                        if (value.trim().length != 10) {
                          return 'La cédula debe tener exactamente 10 dígitos';
                        }
                        if (!_validarCedulaEcuatoriana(value.trim())) {
                          return 'Cédula ecuatoriana inválida';
                        }
                      } else if (_paisSeleccionado == 'Colombia') {
                        if (value.trim().length < 6 ||
                            value.trim().length > 10) {
                          return 'La cédula debe tener entre 6 y 10 dígitos';
                        }
                      } else if (_paisSeleccionado == 'Perú') {
                        if (value.trim().length != 8) {
                          return 'El DNI debe tener exactamente 8 dígitos';
                        }
                      } else if (_paisSeleccionado == 'Venezuela') {
                        if (value.trim().length < 7 ||
                            value.trim().length > 8) {
                          return 'La cédula debe tener entre 7 y 8 dígitos';
                        }
                      } else {
                        // Otro país - validación genérica
                        if (value.trim().length < 5) {
                          return 'El documento debe tener al menos 5 dígitos';
                        }
                      }

                      return null;
                    },
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_celularFocus);
                    },
                  ),

                  const SizedBox(height: 20),

                  // Campo Celular
                  _buildTextField(
                    controller: _celularController,
                    focusNode: _celularFocus,
                    label: config['labelTelefono'],
                    hint: config['hintTelefono'],
                    icon: Icons.phone_android_outlined,
                    keyboardType: TextInputType.phone,
                    maxLength: config['maxLengthTelefono'],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El teléfono es requerido';
                      }

                      // Validación específica por país
                      if (_paisSeleccionado == 'Ecuador') {
                        if (value.trim().length != 10) {
                          return 'El celular debe tener 10 dígitos';
                        }
                        if (!value.startsWith('09')) {
                          return 'El celular debe comenzar con 09';
                        }
                      } else if (_paisSeleccionado == 'Colombia') {
                        if (value.trim().length != 10) {
                          return 'El celular debe tener 10 dígitos';
                        }
                        if (!value.startsWith('3')) {
                          return 'El celular debe comenzar con 3';
                        }
                      } else if (_paisSeleccionado == 'Perú') {
                        if (value.trim().length != 9) {
                          return 'El celular debe tener 9 dígitos';
                        }
                        if (!value.startsWith('9')) {
                          return 'El celular debe comenzar con 9';
                        }
                      } else if (_paisSeleccionado == 'Venezuela') {
                        if (value.trim().length != 10) {
                          return 'El celular debe tener 10 dígitos';
                        }
                        if (!value.startsWith('4')) {
                          return 'El celular debe comenzar con 4';
                        }
                      } else {
                        // Otro país - validación genérica
                        if (value.trim().length < 7) {
                          return 'El teléfono debe tener al menos 7 dígitos';
                        }
                      }

                      return null;
                    },
                    onFieldSubmitted: (_) {
                      _continuar();
                    },
                  ),

                  const SizedBox(height: 24),

                  // Nota informativa
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentBlue.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: accentBlue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: accentBlue,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Información importante',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: darkNavy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tus datos son necesarios para generar tu boleto de viaje y confirmar tu reserva.',
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaisSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'País de Origen',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: darkNavy,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: lightBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _paisSeleccionado,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              borderRadius: BorderRadius.circular(12),
              icon:
                  Icon(Icons.arrow_drop_down_rounded, color: mainRed, size: 28),
              style: TextStyle(
                fontSize: 15,
                color: darkNavy,
                fontWeight: FontWeight.w500,
              ),
              dropdownColor: Colors.white,
              items: _paises.map((String pais) {
                IconData icono;
                switch (pais) {
                  case 'Ecuador':
                    icono = Icons.flag;
                    break;
                  case 'Colombia':
                    icono = Icons.flag_outlined;
                    break;
                  case 'Perú':
                    icono = Icons.outlined_flag;
                    break;
                  case 'Venezuela':
                    icono = Icons.flag_circle_outlined;
                    break;
                  default:
                    icono = Icons.public;
                }

                return DropdownMenuItem<String>(
                  value: pais,
                  child: Row(
                    children: [
                      Icon(icono, color: mainRed, size: 20),
                      const SizedBox(width: 12),
                      Text(pais),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? nuevoPais) {
                if (nuevoPais != null) {
                  setState(() {
                    _paisSeleccionado = nuevoPais;
                    // Limpiar campos cuando cambia el país
                    _cedulaController.clear();
                    _celularController.clear();
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    void Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: darkNavy,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          style: TextStyle(
            fontSize: 15,
            color: darkNavy,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: textGray.withOpacity(0.5),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(
                icon,
                color: mainRed,
                size: 22,
              ),
            ),
            filled: true,
            fillColor: lightBg,
            counterText: maxLength != null ? '' : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: mainRed, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            errorStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Resumen del total
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: lightBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
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
                        '\$${widget.total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: darkNavy,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: successGreen,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            // Botón continuar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: mainRed.withOpacity(0.3),
                ),
                onPressed: _isLoading ? null : _continuar,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Continuar al Pago',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
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

// Validación de cédula ecuatoriana
  bool _validarCedulaEcuatoriana(String cedula) {
    if (cedula.length != 10) return false;
    try {
      int provincia = int.parse(cedula.substring(0, 2));
      if (provincia < 1 || provincia > 24) return false;

      int digitoVerificador = int.parse(cedula[9]);

      int suma = 0;
      for (int i = 0; i < 9; i++) {
        int digito = int.parse(cedula[i]);
        if (i % 2 == 0) {
          digito *= 2;
          if (digito > 9) digito -= 9;
        }
        suma += digito;
      }

      int residuo = suma % 10;
      int verificadorCalculado = residuo == 0 ? 0 : 10 - residuo;

      return verificadorCalculado == digitoVerificador;
    } catch (e) {
      return false;
    }
  }
}
