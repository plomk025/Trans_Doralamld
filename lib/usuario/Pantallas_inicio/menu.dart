import 'package:app2tesis/administrador/agregar_ruta.dart';
import 'package:app2tesis/administrador/cambiar_imagenes_de_inicio.dart';
import 'package:app2tesis/administrador/crear_buses.dart';
import 'package:app2tesis/administrador/crear_notificaion.dart';
import 'package:app2tesis/administrador/gestion_de_datos.dart';
import 'package:app2tesis/administrador/Gestion_encomiendas.dart';
import 'package:app2tesis/administrador/manual_administrador.dart';
import 'package:app2tesis/usuario/Encomiendas/encomiendas.dart';
import 'package:app2tesis/usuario/Pantallas_inicio/manual_usuario.dart';
import 'package:app2tesis/usuario/compra_de_boletos/selecciona_tu_destino.dart';
import 'package:app2tesis/usuario/historial.dart';
import 'package:app2tesis/administrador/verificacion_de_pagos.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:package_info_plus/package_info_plus.dart';

// ========================================
// CONSTANTES Y CONFIGURACIÓN
// ========================================

class AppColors {
  static const Color primaryBusBlue = Color.fromARGB(255, 255, 255, 255);
  static const Color accentOrange = Color(0xFF940016);
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color roadGray = Color(0xFF334155);
  static const Color lightBg = Color(0xFFF1F5F9);
  static const Color textGray = Color(0xFF475569);
  static const Color successGreen = Color(0xFF059669);
  static const Color warningYellow = Color(0xFFF59E0B);
  static const Color backgroundGradientStart =
      Color.fromARGB(255, 243, 248, 255);
  static const Color backgroundGradientEnd = Color.fromARGB(255, 245, 249, 255);
}

class AppConstants {
  static const String appName = 'TRANS DORAMALD';
  static const String appSubtitle = 'TRANSPORTE TERRESTRE';
  static const double cardBorderRadius = 16.0;
  static const double iconContainerSize = 56.0;
  static const Duration animationDuration = Duration(milliseconds: 800);
  static const Duration staggerDuration = Duration(milliseconds: 500);
}

// ========================================
// MODELOS
// ========================================

class ServiceItem {
  final String titulo;
  final String subtitulo;
  final String descripcion;
  final Widget ruta;
  final IconData icon;
  final Color color;

  const ServiceItem({
    required this.titulo,
    required this.subtitulo,
    required this.descripcion,
    required this.ruta,
    required this.icon,
    required this.color,
  });
}

enum UserRole {
  guest,
  usuario,
  administrador,
  conductor,
}

// ========================================
// SCREEN PRINCIPAL
// ========================================

class MenuCuadrosScreen extends StatefulWidget {
  final Function(Color)? actualizarTema;

  const MenuCuadrosScreen({Key? key, this.actualizarTema}) : super(key: key);

  @override
  State<MenuCuadrosScreen> createState() => _MenuCuadrosScreenState();
}

class _MenuCuadrosScreenState extends State<MenuCuadrosScreen>
    with SingleTickerProviderStateMixin {
  // Estado
  Widget _selectedScreen = Container();
  User? _usuarioActual;
  String _nombreUsuario = '';
  String _rolUsuario = ''; // NUEVO: Campo para almacenar el rol
  bool _isLoadingUserData = true;
  String _appVersion = '';
  String _buildNumber = '';

  // Animaciones
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _inicializarPantalla();
    _configurarAnimaciones();
    _configurarListenerAuth();
  }

  void _inicializarPantalla() {
    _usuarioActual = FirebaseAuth.instance.currentUser;
    _cargarDatosUsuario();
    _cargarVersionApp();
  }

  void _configurarAnimaciones() {
    _animationController = AnimationController(
      vsync: this,
      duration: AppConstants.animationDuration,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  void _configurarListenerAuth() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _usuarioActual = user;
          if (user != null) {
            _cargarDatosUsuario();
            _animationController.reset();
            _animationController.forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ========================================
  // LÓGICA DE NEGOCIO
  // ========================================

  Future<void> _cargarDatosUsuario() async {
    if (_usuarioActual == null) return;

    setState(() => _isLoadingUserData = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios_registrados')
          .doc(_usuarioActual!.uid)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _nombreUsuario = doc.data()?['nombre'] ??
              _usuarioActual!.email?.split('@')[0] ??
              'Usuario';
          // NUEVO: Leer el campo 'rol' desde Firebase
          _rolUsuario =
              doc.data()?['rol']?.toString().toLowerCase() ?? 'usuario';
          _isLoadingUserData = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar datos de usuario: $e');
      if (mounted) {
        setState(() {
          _nombreUsuario = _usuarioActual!.email?.split('@')[0] ?? 'Usuario';
          _rolUsuario = 'usuario'; // Rol por defecto en caso de error
          _isLoadingUserData = false;
        });
      }
    }
  }

  Future<void> _cargarVersionApp() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = info.version;
          _buildNumber = info.buildNumber;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar versión: $e');
    }
  }

  Future<void> _refrescarPagina() async {
    setState(() {
      _usuarioActual = FirebaseAuth.instance.currentUser;
      _animationController.reset();
      _animationController.forward();
    });
    await _cargarDatosUsuario();
    return Future.delayed(const Duration(milliseconds: 500));
  }

  // MODIFICADO: Ahora obtiene el rol desde Firebase
  UserRole _obtenerRolUsuario() {
    if (_usuarioActual == null) return UserRole.guest;

    // Normalizar el rol a minúsculas para evitar problemas de case-sensitivity
    final rol = _rolUsuario.toLowerCase();

    switch (rol) {
      case 'administrador':
        return UserRole.administrador;
      case 'conductor':
        return UserRole.conductor;
      case 'usuario':
        return UserRole.usuario;
      default:
        return UserRole.usuario; // Por defecto es usuario
    }
  }

  List<ServiceItem> _obtenerServicios() {
    final role = _obtenerRolUsuario();
    print('ROL ACTUAL: $role');

    switch (role) {
      case UserRole.conductor:
        return _serviciosConductor();
      case UserRole.administrador:
        return [..._serviciosUsuario(), ..._serviciosAdmin()];
      case UserRole.usuario:
        return _serviciosUsuario();
      default:
        return [];
    }
  }

  // NUEVO: Servicios para el rol Conductor
  List<ServiceItem> _serviciosConductor() {
    return [
      ServiceItem(
        titulo: '⚙️ Panel de Control',
        subtitulo: 'Gestión completa',
        descripcion: 'Configura precios, pesos y tipos de paquetes',
        ruta: ConfiguracionEncomiendas(),
        icon: Icons.settings_applications_rounded,
        color: const Color(0xFF7C3AED),
      ),
      ServiceItem(
        titulo: '📦 Mis Encomiendas',
        subtitulo: 'Envíos activos',
        descripcion: 'Revisa y administra todos tus envíos en tiempo real',
        ruta: Encomiendascreen(),
        icon: Icons.local_shipping_rounded,
        color: const Color(0xFF10B981),
      ),
    ];
  }

  List<ServiceItem> _serviciosUsuario() {
    return [
      ServiceItem(
        titulo: '🎫 Comprar Boleto',
        subtitulo: '¡Viaja ya!',
        descripcion: 'Elige tu destino y reserva en segundos',
        ruta: MenuOpcionesScreen(),
        icon: Icons.directions_bus,
        color: const Color(0xFF2563EB),
      ),
      ServiceItem(
        titulo: '📋 Mis Viajes',
        subtitulo: 'Tu historial',
        descripcion: 'Consulta tus boletos y viajes realizados',
        ruta: HistorialComprasScreen(),
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFF9333EA),
      ),
      ServiceItem(
        titulo: '📦 Encomiendas',
        subtitulo: 'Envíos rápidos',
        descripcion: 'Envía paquetes de forma segura a cualquier destino',
        ruta: Encomiendascreen(),
        icon: Icons.inventory_2_rounded,
        color: const Color(0xFF10B981),
      ),
      ServiceItem(
        titulo: '📖 Guía Rápida',
        subtitulo: 'Aprende a usar la app',
        descripcion: 'Tutorial completo para comprar boletos y enviar paquetes',
        ruta: ManualUsuarioScreen(),
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF0EA5E9),
      ),
    ];
  }

  List<ServiceItem> _serviciosAdmin() {
    return [
      ServiceItem(
        titulo: '🗺️ Gestión de Rutas',
        subtitulo: 'Destinos activos',
        descripcion: 'Crea, edita y elimina rutas de transporte',
        ruta: AgregarNombrePage(),
        icon: Icons.route_rounded,
        color: const Color(0xFFEF4444),
      ),
      ServiceItem(
        titulo: '📦 Config. Encomiendas',
        subtitulo: 'Precios y tarifas',
        descripcion: 'Define pesos, tipos y costos de envíos',
        ruta: ConfiguracionEncomiendas(),
        icon: Icons.tune_rounded,
        color: const Color(0xFF8B5CF6),
      ),
      ServiceItem(
        titulo: '🔔 Notificaciones',
        subtitulo: 'Comunica novedades',
        descripcion: 'Envía alertas y mensajes a todos los usuarios',
        ruta: CrearNotificacionScreen(),
        icon: Icons.campaign_rounded,
        color: const Color(0xFF06B6D4),
      ),
      ServiceItem(
        titulo: '🚌 Gestión de Flota',
        subtitulo: 'Buses y unidades',
        descripcion: 'Administra vehículos, capacidad y disponibilidad',
        ruta: CrearBusScreen(),
        icon: Icons.directions_bus_rounded,
        color: const Color(0xFF6366F1),
      ),
      ServiceItem(
        titulo: '🎨 Galería Multimedia',
        subtitulo: 'Imágenes de la app',
        descripcion: 'Actualiza banners, logos y contenido visual',
        ruta: ImageManagementPage(),
        icon: Icons.collections_rounded,
        color: const Color(0xFFEC4899),
      ),
      ServiceItem(
        titulo: '💳 Verificar Pagos',
        subtitulo: 'Transacciones',
        descripcion: 'Valida y confirma pagos de usuarios',
        ruta: AdminVerificacionPagosScreen(),
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFFF59E0B),
      ),
      ServiceItem(
        titulo: '👥 Gestión Operativa',
        subtitulo: 'Personal y horarios',
        descripcion: 'Administra conductores, turnos y salidas',
        ruta: GestionDatosScreen(),
        icon: Icons.badge_rounded,
        color: const Color(0xFF0891B2),
      ),
      ServiceItem(
        titulo: '📘 Manual Admin',
        subtitulo: 'Guía completa',
        descripcion: 'Documentación del panel de administración',
        ruta: ManualAdministradorScreen(),
        icon: Icons.admin_panel_settings_rounded,
        color: const Color(0xFF059669),
      ),
    ];
  }

  Future<bool> _onWillPop() async {
    if (_selectedScreen is Container) {
      return true;
    } else {
      setState(() => _selectedScreen = Container());
      return false;
    }
  }

  // ========================================
  // INTERFAZ DE USUARIO
  // ========================================

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.backgroundGradientStart,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_usuarioActual == null) {
      return _MensajeIniciarSesion(fadeAnimation: _fadeAnimation);
    }

    if (_selectedScreen is Container) {
      return _buildMenuPrincipal();
    }

    return _selectedScreen;
  }

  Widget _buildMenuPrincipal() {
    final servicios = _obtenerServicios();
    final role = _obtenerRolUsuario();

    return RefreshIndicator(
      onRefresh: _refrescarPagina,
      color: const Color(0xFFE0E7FF),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildHeader(role),
          _buildServicesList(servicios),
          _buildVersionInfo(),
          _buildBottomPadding(),
        ],
      ),
    );
  }

  Widget _buildHeader(UserRole role) {
    final isAdmin = role == UserRole.administrador;
    final isConductor = role == UserRole.conductor;

    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundGradientStart,
              AppColors.backgroundGradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserGreeting(),
                  const SizedBox(height: 8),
                  _buildHeaderTitle(isAdmin, isConductor),
                  const SizedBox(height: 8),
                  _buildHeaderSubtitle(isAdmin, isConductor),
                  const SizedBox(height: 16),
                  _buildRoleBadge(role),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserGreeting() {
    if (_isLoadingUserData) {
      return Container(
        height: 16,
        width: 120,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    return Text(
      'Hola, $_nombreUsuario',
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: const Color.fromARGB(255, 14, 14, 14).withOpacity(0.9),
      ),
    );
  }

  Widget _buildHeaderTitle(bool isAdmin, bool isConductor) {
    String title;
    if (isAdmin) {
      title = '🎛️ Panel de Administración';
    } else if (isConductor) {
      title = '🚗 Panel de Conductor';
    } else {
      title = '🚀 ¿Qué deseas hacer hoy?';
    }

    return Text(
      title,
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: Color.fromARGB(255, 32, 32, 32),
        height: 1.2,
      ),
    );
  }

  Widget _buildHeaderSubtitle(bool isAdmin, bool isConductor) {
    String subtitle;
    if (isAdmin) {
      subtitle = 'Control total del sistema de transporte';
    } else if (isConductor) {
      subtitle = 'Gestiona tus viajes y encomiendas';
    } else {
      subtitle = '¡Elige una opción y empieza tu viaje!';
    }

    return Text(
      subtitle,
      style: TextStyle(
        fontSize: 14,
        color: const Color.fromARGB(255, 29, 28, 28).withOpacity(0.8),
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    String badgeText;
    IconData badgeIcon;
    List<Color> gradientColors;

    switch (role) {
      case UserRole.administrador:
        badgeText = '👑 ADMINISTRADOR';
        badgeIcon = Icons.admin_panel_settings_rounded;
        gradientColors = [AppColors.accentOrange, AppColors.accentOrange];
        break;
      case UserRole.conductor:
        badgeText = '🚗 CONDUCTOR';
        badgeIcon = Icons.local_shipping_rounded;
        gradientColors = [const Color(0xFF7C3AED), const Color(0xFF7C3AED)];
        break;
      case UserRole.usuario:
        badgeText = '✓ USUARIO VERIFICADO';
        badgeIcon = Icons.verified_user_rounded;
        gradientColors = [const Color(0xFF2563EB), const Color(0xFF2563EB)];
        break;
      default:
        badgeText = '👤 INVITADO';
        badgeIcon = Icons.person_outline_rounded;
        gradientColors = [Colors.grey, Colors.grey];
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            badgeText,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList(List<ServiceItem> servicios) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final servicio = servicios[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: AppConstants.staggerDuration,
              child: SlideAnimation(
                verticalOffset: 30.0,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ServiceCard(servicio: servicio),
                  ),
                ),
              ),
            );
          },
          childCount: servicios.length,
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _VersionInfoCard(
            appVersion: _appVersion,
            buildNumber: _buildNumber,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPadding() {
    return SliverToBoxAdapter(
      child: SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
    );
  }
}

// ========================================
// COMPONENTES REUTILIZABLES
// ========================================

class _MensajeIniciarSesion extends StatelessWidget {
  final Animation<double> fadeAnimation;

  const _MensajeIniciarSesion({
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.backgroundGradientStart,
            AppColors.backgroundGradientEnd,
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 20),
                  _buildAppTitle(),
                  const SizedBox(height: 12),
                  _buildAppSubtitle(),
                  const SizedBox(height: 48),
                  _buildLoginCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.accentOrange,
          shape: BoxShape.circle,
        ),
        child: const Image(
          image: AssetImage('assets/icon2.png'),
          width: 80,
        ),
      ),
    );
  }

  Widget _buildAppTitle() {
    return const Text(
      '🚌 ' + AppConstants.appName,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: Color.fromARGB(255, 46, 45, 45),
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildAppSubtitle() {
    return Text(
      '✨ TU COMPAÑERO DE VIAJE CONFIABLE ✨',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color.fromARGB(255, 41, 40, 40).withOpacity(0.8),
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.login_rounded,
              size: 48,
              color: AppColors.accentOrange,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '¡Hola! 👋',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color.fromARGB(255, 48, 48, 49),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Inicia sesión para continuar',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Accede a todos nuestros servicios: compra boletos, envía encomiendas y mucho más',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accentOrange.withOpacity(0.1),
                  const Color(0xFF2563EB).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accentOrange.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.arrow_upward_rounded,
                  color: AppColors.accentOrange,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Toca el menú superior para iniciar sesión',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textGray,
                      fontWeight: FontWeight.w600,
                    ),
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

class _ServiceCard extends StatelessWidget {
  final ServiceItem servicio;

  const _ServiceCard({required this.servicio});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _navigateToService(context),
      borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
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
          child: Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 16),
              Expanded(child: _buildContent()),
              const SizedBox(width: 8),
              _buildArrow(),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToService(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => servicio.ruta),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: AppConstants.iconContainerSize,
      height: AppConstants.iconContainerSize,
      decoration: BoxDecoration(
        color: servicio.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        servicio.icon,
        color: servicio.color,
        size: 28,
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          servicio.titulo,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.darkNavy,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          servicio.subtitulo,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: servicio.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          servicio.descripcion,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textGray,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildArrow() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.lightBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.roadGray,
      ),
    );
  }
}

class _VersionInfoCard extends StatelessWidget {
  final String appVersion;
  final String buildNumber;

  const _VersionInfoCard({
    required this.appVersion,
    required this.buildNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.roadGray.withOpacity(0.05),
            AppColors.textGray.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildVersionBadge(),
          const SizedBox(height: 12),
          _buildCopyright(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accentOrange.withOpacity(0.2),
                const Color(0xFF2563EB).withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.info_rounded,
            color: AppColors.accentOrange,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🚌 ' + AppConstants.appName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.darkNavy,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Sistema Inteligente de Transporte',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textGray,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVersionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            AppColors.successGreen.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.successGreen.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_rounded,
              color: AppColors.successGreen, size: 16),
          const SizedBox(width: 8),
          const Text(
            'v. ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textGray,
            ),
          ),
          Text(
            appVersion.isNotEmpty ? appVersion : '...',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.darkNavy,
            ),
          ),
          if (buildNumber.isNotEmpty) ...[
            Text(
              ' • Build $buildNumber',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textGray,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCopyright() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.copyright_rounded,
          size: 12,
          color: AppColors.textGray,
        ),
        const SizedBox(width: 4),
        Text(
          '${DateTime.now().year} Trans Doramald • Todos los derechos reservados',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textGray.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
