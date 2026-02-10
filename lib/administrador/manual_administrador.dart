import 'package:flutter/material.dart';

// ========================================
// ENUMS Y MODELOS
// ========================================

enum TipoManualAdmin {
  gestionConductores,
  gestionBuses,
  verificarPagos,
  gestionEncomiendas,
  gestionRutas,
  crearNotificaciones,
}

class PasoGuiaAdmin {
  final String titulo;
  final String descripcion;
  final IconData icono;
  final Color color;
  final List<String> detalles;

  PasoGuiaAdmin({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.color,
    required this.detalles,
  });
}

// ========================================
// MANUAL DE ADMINISTRADOR
// ========================================

class ManualAdministradorScreen extends StatefulWidget {
  const ManualAdministradorScreen({Key? key}) : super(key: key);

  @override
  State<ManualAdministradorScreen> createState() =>
      _ManualAdministradorScreenState();
}

class _ManualAdministradorScreenState extends State<ManualAdministradorScreen> {
  TipoManualAdmin? _tipoSeleccionado;
  int _pasoActual = 0;

  // Paleta de colores
  static const Color primaryAdmin = Color(0xFFEA580C);
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color lightBg = Color(0xFFF1F5F9);
  static const Color textGray = Color(0xFF475569);
  static const Color adminBlue = Color(0xFF1E40AF);
  static const Color successGreen = Color(0xFF059669);

  void _seleccionarManual(TipoManualAdmin tipo) {
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

  List<PasoGuiaAdmin> _obtenerPasos() {
    switch (_tipoSeleccionado) {
      case TipoManualAdmin.gestionConductores:
        return _pasosGestionConductores;
      case TipoManualAdmin.gestionBuses:
        return _pasosGestionBuses;
      case TipoManualAdmin.verificarPagos:
        return _pasosVerificarPagos;
      case TipoManualAdmin.gestionEncomiendas:
        return _pasosGestionEncomiendas;
      case TipoManualAdmin.gestionRutas:
        return _pasosGestionRutas;
      case TipoManualAdmin.crearNotificaciones:
        return _pasosCrearNotificaciones;
      default:
        return [];
    }
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
                icon: Icons.person_add_rounded,
                iconColor: const Color(0xFF4CAF50),
                title: 'Gestión de Conductores',
                subtitle: 'Agregar y editar',
                description:
                    'Registra conductores con sus datos y asigna buses',
                features: [
                  'Registrar nuevos conductores',
                  'Asignar número de bus y placa',
                  'Editar información existente',
                ],
                onTap: () =>
                    _seleccionarManual(TipoManualAdmin.gestionConductores),
              ),
              const SizedBox(height: 12),
              _buildManualCard(
                icon: Icons.directions_bus_rounded,
                iconColor: adminBlue,
                title: 'Gestión de Buses',
                subtitle: 'Crear itinerarios',
                description: 'Configura rutas, horarios y asigna conductores',
                features: [
                  'Crear nuevos viajes',
                  'Asignar conductor y ruta',
                  'Definir fecha y hora de salida',
                ],
                onTap: () => _seleccionarManual(TipoManualAdmin.gestionBuses),
              ),
              const SizedBox(height: 12),
              _buildManualCard(
                icon: Icons.payment_rounded,
                iconColor: primaryAdmin,
                title: 'Verificar Pagos',
                subtitle: 'Confirmar compras',
                description:
                    'Revisa comprobantes y confirma o rechaza reservas',
                features: [
                  'Revisar comprobantes de pago',
                  'Confirmar reservas válidas',
                  'Rechazar pagos incorrectos',
                ],
                onTap: () => _seleccionarManual(TipoManualAdmin.verificarPagos),
              ),
              const SizedBox(height: 12),
              _buildManualCard(
                icon: Icons.inventory_rounded,
                iconColor: const Color(0xFFE91E63),
                title: 'Gestión de Encomiendas',
                subtitle: 'Procesar envíos',
                description:
                    'Administra encomiendas desde el registro hasta la entrega',
                features: [
                  'Registrar peso y valor',
                  'Asignar bus para transporte',
                  'Actualizar estado de entrega',
                ],
                onTap: () =>
                    _seleccionarManual(TipoManualAdmin.gestionEncomiendas),
              ),
              const SizedBox(height: 12),
              _buildManualCard(
                icon: Icons.route_rounded,
                iconColor: const Color(0xFF00BCD4),
                title: 'Gestión de Rutas',
                subtitle: 'Paradas y tarifas',
                description: 'Configura rutas, paradas y precios del servicio',
                features: [
                  'Agregar nuevas paradas',
                  'Definir tarifas por ruta',
                  'Eliminar rutas obsoletas',
                ],
                onTap: () => _seleccionarManual(TipoManualAdmin.gestionRutas),
              ),
              const SizedBox(height: 12),
              _buildManualCard(
                icon: Icons.notifications_active_rounded,
                iconColor: const Color(0xFFFF5722),
                title: 'Crear Notificaciones',
                subtitle: 'Mensajes masivos',
                description:
                    'Envía notificaciones a todos los usuarios de la app',
                features: [
                  'Crear mensaje personalizado',
                  'Enviar a todos los usuarios',
                  'Notificaciones instantáneas',
                ],
                onTap: () =>
                    _seleccionarManual(TipoManualAdmin.crearNotificaciones),
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
                            'MANUAL DE ADMINISTRADOR',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color.fromARGB(255, 26, 25, 25),
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Guía de gestión completa',
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
                'Panel de Administración',
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
                'Gestiona conductores, buses, pagos, encomiendas y más desde el panel administrativo',
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
                  _buildStatChip(Icons.admin_panel_settings, 'Administrador'),
                  const SizedBox(width: 10),
                  _buildStatChip(Icons.verified_user, 'Control Total'),
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
        color: primaryAdmin.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primaryAdmin, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: darkNavy,
            ),
          ),
        ],
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
            primaryAdmin.withOpacity(0.05),
            adminBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryAdmin.withOpacity(0.2),
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
                  color: primaryAdmin.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_rounded,
                  color: primaryAdmin,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Responsabilidades del Admin',
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
            title: 'Gestión diaria',
            description: 'Supervisar operaciones del sistema',
            icon: Icons.task_alt_rounded,
          ),
          const SizedBox(height: 14),
          _buildInfoStep(
            number: '2',
            title: 'Control de calidad',
            description: 'Verificar información ingresada',
            icon: Icons.verified_rounded,
          ),
          const SizedBox(height: 14),
          _buildInfoStep(
            number: '3',
            title: 'Atención al cliente',
            description: 'Resolver problemas rápidamente',
            icon: Icons.support_agent_rounded,
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
                colors: [Color(0xFFEA580C), Color(0xFFDC2626)],
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
          Icon(icon, size: 20, color: primaryAdmin),
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
                            _obtenerTituloManual(),
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
                  valueColor: const AlwaysStoppedAnimation<Color>(primaryAdmin),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _obtenerTituloManual() {
    switch (_tipoSeleccionado) {
      case TipoManualAdmin.gestionConductores:
        return 'GESTIÓN DE CONDUCTORES';
      case TipoManualAdmin.gestionBuses:
        return 'GESTIÓN DE BUSES';
      case TipoManualAdmin.verificarPagos:
        return 'VERIFICAR PAGOS';
      case TipoManualAdmin.gestionEncomiendas:
        return 'GESTIÓN DE ENCOMIENDAS';
      case TipoManualAdmin.gestionRutas:
        return 'GESTIÓN DE RUTAS';
      case TipoManualAdmin.crearNotificaciones:
        return 'CREAR NOTIFICACIONES';
      default:
        return '';
    }
  }

  Widget _buildPasoContent(PasoGuiaAdmin paso) {
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
    return Row(
      children: [
        if (_pasoActual > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _pasoAnterior,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: primaryAdmin, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back_rounded, color: primaryAdmin, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Anterior',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: primaryAdmin,
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
              backgroundColor: primaryAdmin,
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
  // DATOS DE TODOS LOS MANUALES
  // ========================================

  final List<PasoGuiaAdmin> _pasosGestionConductores = [
    PasoGuiaAdmin(
      titulo: 'Accede al módulo',
      descripcion: 'Ingresa a la sección de conductores',
      icono: Icons.login_rounded,
      color: const Color(0xFF4CAF50),
      detalles: [
        'Desde el panel de administración, localiza el menú principal',
        'Haz clic en el botón "Agregar Conductor"',
        'Se abrirá el formulario de registro',
        'Asegúrate de tener los datos del conductor a mano',
      ],
    ),
    PasoGuiaAdmin(
      titulo: 'Ingresa los datos',
      descripcion: 'Completa la información del conductor',
      icono: Icons.edit_document,
      color: const Color(0xFF66BB6A),
      detalles: [
        'Ingresa el nombre completo del conductor',
        'Escribe el número de bus que operará',
        'Registra la placa del vehículo asignado',
        'Verifica que todos los campos estén correctos',
        'Los campos marcados con asterisco (*) son obligatorios',
      ],
    ),
    PasoGuiaAdmin(
      titulo: 'Guarda la información',
      descripcion: 'Confirma el registro del conductor',
      icono: Icons.save_rounded,
      color: const Color(0xFF81C784),
      detalles: [
        'Revisa todos los datos ingresados',
        'Haz clic en el botón "Guardar Conductor"',
        'Espera la confirmación del sistema',
        'El conductor aparecerá en la lista de conductores activos',
        'Podrás editar esta información más adelante si es necesario',
      ],
    ),
  ];

  final List<PasoGuiaAdmin> _pasosGestionBuses = [
    PasoGuiaAdmin(
      titulo: 'Crear nuevo viaje',
      descripcion: 'Inicia la configuración de un bus',
      icono: Icons.add_circle_rounded,
      color: adminBlue,
      detalles: [
        'En el panel de administración, selecciona "Crear Bus"',
        'Verás el formulario para configurar un nuevo viaje',
        'Ten lista la información del conductor y la ruta',
      ],
    ),
    PasoGuiaAdmin(
      titulo: 'Asignar conductor y ruta',
      descripcion: 'Configura los detalles del viaje',
      icono: Icons.settings_rounded,
      color: const Color(0xFF3B82F6),
      detalles: [
        'Selecciona el conductor de la lista desplegable',
        'Elige el lugar de salida del viaje',
        'Define la fecha del viaje usando el calendario',
        'Establece la hora de salida',
        'Verifica que la combinación conductor-bus-horario sea correcta',
      ],
    ),
    PasoGuiaAdmin(
      titulo: 'Confirmar y activar',
      descripcion: 'Guarda el viaje para que esté disponible',
      icono: Icons.check_circle_rounded,
      color: const Color(0xFF60A5FA),
      detalles: [
        'Revisa todos los datos del viaje',
        'Haz clic en "Crear Bus" para guardar',
        'El viaje estará disponible para que los usuarios reserven',
        'Los pasajeros podrán ver este viaje en la app',
      ],
    ),
  ];

  final List<PasoGuiaAdmin> _pasosVerificarPagos = [
    PasoGuiaAdmin(
      titulo: 'Accede a verificación',
      descripcion: 'Revisa los pagos pendientes',
      icono: Icons.pending_actions_rounded,
      color: primaryAdmin,
      detalles: [
        'Ingresa al módulo "Verificar Pagos"',
        'Selecciona el lugar de salida del viaje',
        'Elige el bus específico a revisar',
        'Verás la lista de pagos pendientes de verificación',
      ],
    ),
    PasoGuiaAdmin(
      titulo: 'Revisar comprobantes',
      descripcion: 'Examina los documentos de pago',
      icono: Icons.receipt_long_rounded,
      color: const Color(0xFFFB923C),
      detalles: [
        'Haz clic en "Ver Comprobante" para cada pago',
        'Verifica que el monto sea correcto',
        'Confirma que la información coincida con la reserva',
        'Si es pago en efectivo, verifica con el registro físico',
      ],
    ),
    PasoGuiaAdmin(
      titulo: 'Confirmar o rechazar',
      descripcion: 'Toma una decisión sobre el pago',
      icono: Icons.gavel_rounded,
      color: const Color(0xFFF97316),
      detalles: [
        'Para pagos válidos, haz clic en "Confirmar"',
        'Para pagos incorrectos o falsos, haz clic en "Rechazar"',
        'El sistema notificará al usuario automáticamente',
        'Los pagos confirmados activarán la reserva',
        'Los pagos rechazados cancelarán la reserva',
      ],
    ),
  ];

  final List<PasoGuiaAdmin> _pasosGestionEncomiendas = [
    PasoGuiaAdmin(
      titulo: 'Localizar encomienda',
      descripcion: 'Encuentra el paquete a procesar',
      icono: Icons.search_rounded,
      color: const Color(0xFFE91E63),
      detalles: [
        'Accede al módulo "Gestionar Encomiendas"',
        'Verás todas las encomiendas registradas',
        'Identifica las que están en estado "Registrado"',
        'Selecciona la encomienda que vas a procesar',
      ],
    ),
    PasoGuiaAdmin(
      titulo: 'Agregar información',
      descripcion: 'Registra peso, valor y bus',
      icono: Icons.inventory_rounded,
      color: const Color(0xFFF06292),
      detalles: [
        'Ingresa el peso del paquete en kilogramos',
        'Registra el valor declarado de la encomienda',
        'Selecciona el bus que transportará el paquete',
        'Toma una foto del paquete para el registro',
        'Esta foto servirá como evidencia del estado inicial',
      ],
    ),
    PasoGuiaAdmin(
      titulo: 'Actualizar estado',
      descripcion: 'Cambia el estado según el proceso',
      icono: Icons.update_rounded,
      color: const Color(0xFFEC407A),
      detalles: [
        'Al confirmar, el estado cambia a "En tránsito"',
        'Cuando llegue a destino, marca para entrega',
        'Toma foto con la persona que recibe',
        'Actualiza el estado a "Entregado"',
        'El destinatario recibirá notificación de entrega',
      ],
    ),
  ];

  final List<PasoGuiaAdmin> _pasosGestionRutas = [
    PasoGuiaAdmin(
      titulo: 'Ver rutas existentes',
      descripcion: 'Revisa las rutas activas',
      icono: Icons.list_alt_rounded,
      color: const Color(0xFF00BCD4),
      detalles: [
        'Ingresa a "Gestión de Rutas"',
        'Verás todas las rutas y paradas configuradas',
        'Cada ruta muestra su nombre y precio',
        'Identifica si necesitas agregar o eliminar rutas',
      ],
    ),
    PasoGuiaAdmin(
      titulo: 'Agregar nueva ruta',
      descripcion: 'Crea una parada o ruta nueva',
      icono: Icons.add_location_rounded,
      color: const Color(0xFF26C6DA),
      detalles: [
        'Haz clic en "Agregar Nueva Ruta"',
        'Ingresa el nombre de la parada o ruta',
        'Define el valor o tarifa en dólares',
        'Confirma para guardar la nueva ruta',
        'La ruta estará disponible inmediatamente',
      ],
    ),
    PasoGuiaAdmin(
      titulo: 'Eliminar ruta obsoleta',
      descripcion: 'Remueve rutas que ya no se usan',
      icono: Icons.delete_rounded,
      color: const Color(0xFF00ACC1),
      detalles: [
        'Identifica la ruta que deseas eliminar',
        'Haz clic en el ícono de eliminar (papelera)',
        'Confirma la eliminación cuando el sistema lo solicite',
        'La ruta se eliminará permanentemente',
        'Asegúrate de que no haya viajes activos en esa ruta',
      ],
    ),
  ];

  final List<PasoGuiaAdmin> _pasosCrearNotificaciones = [
    PasoGuiaAdmin(
      titulo: 'Acceder al módulo',
      descripcion: 'Ingresa a la sección de notificaciones',
      icono: Icons.notifications_rounded,
      color: const Color(0xFFFF5722),
      detalles: [
        'Desde el panel de administración, busca "Crear Notificaciones"',
        'Haz clic para abrir el formulario',
        'Este módulo te permite enviar mensajes masivos',
        'Úsalo solo para información importante',
      ],
    ),
    PasoGuiaAdmin(
      titulo: 'Redactar mensaje',
      descripcion: 'Crea el título y contenido',
      icono: Icons.edit_note_rounded,
      color: const Color(0xFFFF6F3C),
      detalles: [
        'Escribe un título claro y conciso (máximo 50 caracteres)',
        'Redacta el mensaje principal en el campo de texto',
        'Sé breve pero informativo',
        'Revisa la ortografía antes de enviar',
        'Evita usar mayúsculas sostenidas (parece que gritas)',
      ],
    ),
    PasoGuiaAdmin(
      titulo: 'Enviar notificación',
      descripcion: 'Confirma y envía a todos los usuarios',
      icono: Icons.send_rounded,
      color: const Color(0xFFFF7849),
      detalles: [
        'Revisa el título y mensaje una última vez',
        'Haz clic en "Enviar Notificación"',
        'Confirma el envío masivo',
        'La notificación llegará instantáneamente a todos los usuarios',
        'Todos los usuarios recibirán una alerta en sus dispositivos',
      ],
    ),
  ];
}
