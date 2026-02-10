import 'package:flutter/material.dart';

// ========================================
// ENUMS Y MODELOS
// ========================================

enum TipoManualUsuario {
  reservaBoleto,
  enviarEncomienda,
}

class PasoGuiaUsuario {
  final String titulo;
  final String descripcion;
  final IconData icono;
  final Color color;
  final List<String> detalles;

  PasoGuiaUsuario({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.color,
    required this.detalles,
  });
}

// ========================================
// MANUAL DE USUARIO
// ========================================

class ManualUsuarioScreen extends StatefulWidget {
  const ManualUsuarioScreen({Key? key}) : super(key: key);

  @override
  State<ManualUsuarioScreen> createState() => _ManualUsuarioScreenState();
}

class _ManualUsuarioScreenState extends State<ManualUsuarioScreen> {
  TipoManualUsuario? _tipoSeleccionado;
  int _pasoActual = 0;

  // Paleta de colores
  static const Color primaryBusBlue = Color(0xFF1E40AF);
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color lightBg = Color(0xFFF1F5F9);
  static const Color textGray = Color(0xFF475569);
  static const Color successGreen = Color(0xFF059669);

  void _seleccionarManual(TipoManualUsuario tipo) {
    setState(() {
      _tipoSeleccionado = tipo;
      _pasoActual = 0;
    });
  }

  void _volverAlMenu() {
    setState(() {
      _tipoSeleccionado = null;
      _pasoActual = 0;
    });
  }

  void _siguientePaso() {
    if (_pasoActual < _obtenerPasos().length - 1) {
      setState(() => _pasoActual++);
    }
  }

  void _pasoAnterior() {
    if (_pasoActual > 0) {
      setState(() => _pasoActual--);
    }
  }

  List<PasoGuiaUsuario> _obtenerPasos() {
    if (_tipoSeleccionado == TipoManualUsuario.reservaBoleto) {
      return _pasosReservaBoleto;
    } else if (_tipoSeleccionado == TipoManualUsuario.enviarEncomienda) {
      return _pasosEnviarEncomienda;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 248, 255),
      body: _tipoSeleccionado == null
          ? _buildMenuSeleccion()
          : _buildGuiaPasoAPaso(),
    );
  }

  // ========================================
  // MENÚ DE SELECCIÓN
  // ========================================

  Widget _buildMenuSeleccion() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildManualCard(
                icon: Icons.directions_bus,
                iconColor: primaryBusBlue,
                title: 'Reservar Boletos',
                subtitle: 'Compra de pasajes',
                description:
                    'Aprende a comprar tus boletos de viaje paso a paso',
                features: [
                  'Selección de destino y fecha',
                  'Elegir asientos disponibles',
                  'Pago seguro y confirmación',
                ],
                onTap: () =>
                    _seleccionarManual(TipoManualUsuario.reservaBoleto),
              ),
              const SizedBox(height: 12),
              _buildManualCard(
                icon: Icons.inventory_2_rounded,
                iconColor: successGreen,
                title: 'Enviar Encomiendas',
                subtitle: 'Envío de paquetes',
                description:
                    'Descubre cómo enviar paquetes de forma segura y rápida',
                features: [
                  'Definir origen y destino',
                  'Información del paquete',
                  'Rastreo en tiempo real',
                ],
                onTap: () =>
                    _seleccionarManual(TipoManualUsuario.enviarEncomienda),
              ),
              const SizedBox(height: 20),
              _buildInfoSection(),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
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
                            'MANUAL DE USUARIO',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color.fromARGB(255, 26, 25, 25),
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Guía paso a paso',
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
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'Aprende a Usar la App',
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
                'Tutoriales interactivos para comprar boletos y enviar encomiendas',
                style: TextStyle(
                  fontSize: 14,
                  color: Color.fromARGB(255, 84, 86, 88),
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String description,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
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
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: darkNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: iconColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: lightBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: textGray,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryBusBlue.withOpacity(0.05),
            successGreen.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryBusBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
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
                  Icons.info_rounded,
                  color: primaryBusBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Consejos útiles',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: darkNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoStep(
            number: '1',
            title: 'Sigue cada paso',
            description: 'Avanza con el botón "Siguiente"',
            icon: Icons.touch_app_rounded,
          ),
          const SizedBox(height: 14),
          _buildInfoStep(
            number: '2',
            title: 'Lee con atención',
            description: 'Cada detalle es importante',
            icon: Icons.visibility_rounded,
          ),
          const SizedBox(height: 14),
          _buildInfoStep(
            number: '3',
            title: 'Practica',
            description: 'La mejor forma de aprender es haciendo',
            icon: Icons.repeat_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStep({
    required String number,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E40AF), Color(0xFF1E3A8A)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: darkNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textGray,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, size: 20, color: primaryBusBlue),
        ],
      ),
    );
  }

  // ========================================
  // GUÍA PASO A PASO
  // ========================================

  Widget _buildGuiaPasoAPaso() {
    final pasos = _obtenerPasos();
    final progreso = (_pasoActual + 1) / pasos.length;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeaderPasoAPaso(progreso, pasos.length),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildPasoContent(pasos[_pasoActual]),
              const SizedBox(height: 20),
              _buildNavegacionPasos(pasos.length),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderPasoAPaso(double progreso, int totalPasos) {
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
                        onTap: _volverAlMenu,
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tipoSeleccionado == TipoManualUsuario.reservaBoleto
                                ? 'RESERVAR BOLETOS'
                                : 'ENVIAR ENCOMIENDAS',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color.fromARGB(255, 26, 25, 25),
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Paso ${_pasoActual + 1} de $totalPasos',
                            style: const TextStyle(
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
                ],
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progreso,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _tipoSeleccionado == TipoManualUsuario.reservaBoleto
                        ? primaryBusBlue
                        : successGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasoContent(PasoGuiaUsuario paso) {
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
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: paso.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(paso.icono, color: paso.color, size: 40),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              paso.titulo,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: darkNavy,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              paso.descripcion,
              style: const TextStyle(
                fontSize: 14,
                color: textGray,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: lightBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.checklist_rounded,
                          size: 20, color: paso.color),
                      const SizedBox(width: 8),
                      const Text(
                        'Instrucciones:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: darkNavy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...paso.detalles.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: paso.color.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: paso.color,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                fontSize: 13,
                                color: textGray,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavegacionPasos(int totalPasos) {
    final color = _tipoSeleccionado == TipoManualUsuario.reservaBoleto
        ? primaryBusBlue
        : successGreen;

    return Row(
      children: [
        if (_pasoActual > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _pasoAnterior,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: color, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back_rounded, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Anterior',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_pasoActual > 0) const SizedBox(width: 12),
        Expanded(
          flex: _pasoActual > 0 ? 1 : 1,
          child: ElevatedButton(
            onPressed:
                _pasoActual < totalPasos - 1 ? _siguientePaso : _volverAlMenu,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _pasoActual < totalPasos - 1 ? 'Siguiente' : 'Finalizar',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _pasoActual < totalPasos - 1
                      ? Icons.arrow_forward_rounded
                      : Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ========================================
  // DATOS: PASOS PARA RESERVAR BOLETO
  // ========================================

  final List<PasoGuiaUsuario> _pasosReservaBoleto = [
    PasoGuiaUsuario(
      titulo: 'Selecciona tu destino',
      descripcion: 'Elige desde dónde viajas y hacia dónde quieres ir',
      icono: Icons.location_on_rounded,
      color: const Color(0xFF2563EB),
      detalles: [
        'Toca en "Comprar Boleto" desde el menú principal',
        'Selecciona tu ciudad de origen en el primer campo',
        'Elige tu ciudad de destino en el segundo campo',
        'Verifica que las ciudades sean correctas antes de continuar',
      ],
    ),
    PasoGuiaUsuario(
      titulo: 'Elige fecha y hora',
      descripcion: 'Selecciona cuándo deseas viajar',
      icono: Icons.calendar_today_rounded,
      color: const Color(0xFF3B82F6),
      detalles: [
        'Selecciona la fecha de tu viaje en el calendario',
        'Elige la hora de salida que más te convenga',
        'Verifica que haya disponibilidad para tu horario',
        'Puedes ver los horarios disponibles para cada ruta',
      ],
    ),
    PasoGuiaUsuario(
      titulo: 'Selecciona tus asientos',
      descripcion: 'Elige dónde quieres sentarte en el bus',
      icono: Icons.event_seat_rounded,
      color: const Color(0xFF60A5FA),
      detalles: [
        'Verás un mapa visual de los asientos del bus',
        'Los asientos en GRIS ya están ocupados',
        'Los asientos en VERDE están disponibles',
        'Toca los asientos que desees reservar',
        'Puedes seleccionar múltiples asientos si viajas acompañado',
      ],
    ),
    PasoGuiaUsuario(
      titulo: 'Ingresa tus datos',
      descripcion: 'Completa tu información personal',
      icono: Icons.person_rounded,
      color: const Color(0xFF93C5FD),
      detalles: [
        'Ingresa tu nombre completo',
        'Escribe tu número de cédula o documento',
        'Proporciona un número de teléfono de contacto',
        'Verifica que toda la información sea correcta',
        'Estos datos aparecerán en tu boleto',
      ],
    ),
    PasoGuiaUsuario(
      titulo: 'Realiza el pago',
      descripcion: 'Completa tu compra de forma segura',
      icono: Icons.payment_rounded,
      color: const Color(0xFF1E40AF),
      detalles: [
        'Revisa el resumen de tu compra (destino, fecha, asientos)',
        'Verifica el monto total a pagar',
        'Selecciona tu método de pago preferido',
        'Completa la transacción de forma segura',
        'Recibirás una confirmación inmediata',
      ],
    ),
    PasoGuiaUsuario(
      titulo: '¡Listo para viajar! 🎉',
      descripcion: 'Tu boleto ha sido confirmado exitosamente',
      icono: Icons.check_circle_rounded,
      color: const Color(0xFF10B981),
      detalles: [
        'Tu boleto se guardó automáticamente en "Mis Viajes"',
        'Recibirás una notificación con los detalles',
        'Puedes descargar o compartir tu boleto',
        'Presenta tu boleto digital el día del viaje',
        'Llega 15 minutos antes de la hora de salida',
      ],
    ),
  ];

  // ========================================
  // DATOS: PASOS PARA ENVIAR ENCOMIENDA
  // ========================================

  final List<PasoGuiaUsuario> _pasosEnviarEncomienda = [
    PasoGuiaUsuario(
      titulo: 'Define origen y destino',
      descripcion: 'Indica desde dónde y hacia dónde envías',
      icono: Icons.location_on_rounded,
      color: const Color(0xFF10B981),
      detalles: [
        'Toca en "Encomiendas" desde el menú principal',
        'Selecciona la ciudad desde donde envías',
        'Elige la ciudad de destino del paquete',
        'Verifica que ambas ciudades estén correctas',
      ],
    ),
    PasoGuiaUsuario(
      titulo: 'Tipo de paquete',
      descripcion: 'Selecciona qué tipo de encomienda enviarás',
      icono: Icons.category_rounded,
      color: const Color(0xFF34D399),
      detalles: [
        'Elige el tipo de contenido: documentos, ropa, electrónicos, etc.',
        'Esto nos ayuda a manejar tu paquete adecuadamente',
        'Algunos artículos tienen restricciones de envío',
        'Si tienes dudas, contacta con soporte',
      ],
    ),
    PasoGuiaUsuario(
      titulo: 'Peso del paquete',
      descripcion: 'Indica cuánto pesa tu encomienda',
      icono: Icons.scale_rounded,
      color: const Color(0xFF059669),
      detalles: [
        'Ingresa el peso aproximado en kilogramos',
        'Si no estás seguro, redondea hacia arriba',
        'El precio varía según el peso',
        'Nuestros rangos de peso: 0-5kg, 5-10kg, 10-20kg, 20kg+',
        'Pesos mayores a 50kg requieren coordinación especial',
      ],
    ),
    PasoGuiaUsuario(
      titulo: 'Datos del remitente',
      descripcion: 'Información de quien envía el paquete',
      icono: Icons.person_outline_rounded,
      color: const Color(0xFF10B981),
      detalles: [
        'Nombre completo del remitente',
        'Número de cédula o documento',
        'Teléfono de contacto',
        'Dirección completa (opcional pero recomendado)',
        'Email para notificaciones (opcional)',
      ],
    ),
    PasoGuiaUsuario(
      titulo: 'Datos del destinatario',
      descripcion: 'Información de quien recibe el paquete',
      icono: Icons.person_rounded,
      color: const Color(0xFF34D399),
      detalles: [
        'Nombre completo del destinatario',
        'Número de cédula o documento',
        'Teléfono de contacto obligatorio',
        'Dirección de entrega completa',
        'El destinatario recibirá una notificación cuando llegue',
      ],
    ),
    PasoGuiaUsuario(
      titulo: 'Confirma y paga',
      descripcion: 'Revisa todo y completa el envío',
      icono: Icons.payment_rounded,
      color: const Color(0xFF059669),
      detalles: [
        'Revisa el resumen completo de tu envío',
        'Verifica origen, destino y datos de contacto',
        'Confirma el peso y tipo de paquete',
        'Revisa el costo total del servicio',
        'Selecciona tu método de pago y completa',
      ],
    ),
    PasoGuiaUsuario(
      titulo: '¡Envío registrado! 📦',
      descripcion: 'Tu encomienda está lista para ser enviada',
      icono: Icons.check_circle_rounded,
      color: const Color(0xFF10B981),
      detalles: [
        'Recibirás un código único de rastreo',
        'Lleva tu paquete a nuestra oficina',
        'Presenta tu código de rastreo al despachar',
        'El destinatario será notificado al llegar',
        'Puedes rastrear tu envío en tiempo real desde la app',
        'El tiempo de entrega varía según la ruta (1-3 días)',
      ],
    ),
  ];
}
