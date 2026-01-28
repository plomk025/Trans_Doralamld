import 'package:app2tesis/administrador/agregar_ruta.dart';
import 'package:app2tesis/administrador/cambiar_imagenes_de_inicio.dart';
import 'package:app2tesis/administrador/crear_buses.dart';
import 'package:app2tesis/administrador/crear_notificaion.dart';
import 'package:app2tesis/administrador/crear_servicios.dart';
import 'package:app2tesis/administrador/gestion_de_datos.dart';
import 'package:app2tesis/administrador/Gestion_encomiendas.dart';
import 'package:app2tesis/usuario/Encomiendas/encomiendas.dart';
import 'package:app2tesis/usuario/notificaciones.dart';
import 'package:app2tesis/usuario/compra_de_boletos/selecciona_tu_destino.dart';
import 'package:app2tesis/usuario/historial.dart';
import 'package:app2tesis/usuario/perfil.dart';
import 'package:app2tesis/administrador/verificacion_de_pagos.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MenuCuadrosScreen extends StatefulWidget {
  final Function(Color)? actualizarTema;

  const MenuCuadrosScreen({Key? key, this.actualizarTema}) : super(key: key);

  @override
  _MenuCuadrosScreenState createState() => _MenuCuadrosScreenState();
}

class _MenuCuadrosScreenState extends State<MenuCuadrosScreen>
    with SingleTickerProviderStateMixin {
  Widget _selectedScreen = Container();
  User? _usuarioActual;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _nombreUsuario = '';
  bool _isLoadingUserData = true;
  String _appVersion = '';
  String _buildNumber = '';

  // Paleta de colores inspirada en transporte de buses
  final Color primaryBusBlue = const Color.fromARGB(255, 255, 255, 255);
  final Color accentOrange = const Color(0xFF940016);
  final Color darkNavy = const Color(0xFF0F172A);
  final Color roadGray = const Color(0xFF334155);
  final Color lightBg = const Color(0xFFF1F5F9);
  final Color textGray = const Color(0xFF475569);
  final Color successGreen = const Color(0xFF059669);
  final Color warningYellow = const Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _usuarioActual = FirebaseAuth.instance.currentUser;
    _cargarDatosUsuario();
    _cargarVersionApp();

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

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  Future<void> _cargarDatosUsuario() async {
    if (_usuarioActual != null) {
      setState(() => _isLoadingUserData = true);
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_usuarioActual!.uid)
            .get();

        if (doc.exists && mounted) {
          setState(() {
            _nombreUsuario = doc.data()?['nombre'] ??
                _usuarioActual!.email?.split('@')[0] ??
                'Usuario';
            _isLoadingUserData = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _nombreUsuario = _usuarioActual!.email?.split('@')[0] ?? 'Usuario';
            _isLoadingUserData = false;
          });
        }
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> getServicios() {
    if (_usuarioActual != null &&
        _usuarioActual!.email != null &&
        _usuarioActual!.email!.endsWith('@encomiendas.com')) {
      // 👉 SOLO ESTE BOTÓN
      return [
        {
          'titulo': 'Gestionar Encomiendas',
          'subtitulo': 'Peso y Tipo',
          'descripcion': 'Administra tus paquetes y precios',
          'ruta': ConfiguracionEncomiendas(),
          'icon': Icons.local_shipping,
          'color': const Color.fromARGB(255, 56, 5, 150),
        },
        {
          'titulo': 'Encomiendas',
          'subtitulo': 'Envíos seguros',
          'descripcion': 'Administra tus paquetes y envíos',
          'ruta': Encomiendascreen(),
          'icon': Icons.local_shipping,
          'color': const Color(0xFF059669),
        },
      ];
    }
    List<Map<String, dynamic>> serviciosBase = [
      {
        'titulo': 'Comprar Boleto',
        'subtitulo': 'Viaja con nosotros',
        'descripcion': 'Reserva tu asiento de manera rápida y segura',
        'ruta': MenuOpcionesScreen(),
        'icon': Icons.confirmation_number,
        'color': const Color(0xFF1E40AF),
      },
      {
        'titulo': 'Mis Viajes',
        'subtitulo': 'Historial completo',
        'descripcion': 'Revisa tus boletos y transacciones anteriores',
        'ruta': HistorialComprasScreen(),
        'icon': Icons.history,
        'color': const Color(0xFF7C3AED),
      },
      {
        'titulo': 'Encomiendas',
        'subtitulo': 'Envíos seguros',
        'descripcion': 'Administra tus paquetes y envíos',
        'ruta': Encomiendascreen(),
        'icon': Icons.local_shipping,
        'color': const Color(0xFF059669),
      },
    ];

    if (_usuarioActual != null &&
        _usuarioActual!.email == 'admin@dominio.com') {
      serviciosBase.addAll([
        {
          'titulo': 'Rutas',
          'subtitulo': 'Gestión de destinos',
          'descripcion': 'Administra rutas y destinos disponibles',
          'ruta': AgregarNombrePage(),
          'icon': Icons.alt_route,
          'color': const Color(0xFFF59E0B),
        },
        {
          'titulo': 'Gestionar Encomiendas',
          'subtitulo': 'Peso y Tipo',
          'descripcion': 'Administra tus paquetes y precios',
          'ruta': ConfiguracionEncomiendas(),
          'icon': Icons.local_shipping,
          'color': const Color.fromARGB(255, 56, 5, 150),
        },
        {
          'titulo': 'Notificaciones',
          'subtitulo': 'Comunicación',
          'descripcion': 'Envía avisos importantes a usuarios',
          'ruta': CrearNotificacionScreen(),
          'icon': Icons.notifications_active,
          'color': const Color(0xFF06B6D4),
        },
        {
          'titulo': 'Flota',
          'subtitulo': 'Buses disponibles',
          'descripcion': 'Control de unidades y mantenimiento',
          'ruta': CrearBusScreen(),
          'icon': Icons.directions_bus,
          'color': const Color(0xFF6366F1),
        },
        {
          'titulo': 'Multimedia',
          'subtitulo': 'Imágenes',
          'descripcion': 'Gestiona contenido visual de la app',
          'ruta': ImageManagementPage(),
          'icon': Icons.photo_library,
          'color': const Color(0xFFEC4899),
        },
        {
          'titulo': 'Pagos',
          'subtitulo': 'Verificación',
          'descripcion': 'Valida transacciones financieras',
          'ruta': AdminVerificacionPagosScreen(),
          'icon': Icons.payments,
          'color': const Color(0xFFDC2626),
        },
        {
          'titulo': 'Ingresar datos ',
          'subtitulo': 'Análisis',
          'descripcion': 'Gestion de conductores y salidas',
          'ruta': GestionDatosScreen(),
          'icon': Icons.person,
          'color': const Color(0xFF0891B2),
        },
      ]);
    }

    return serviciosBase;
  }

  void _cambiarPantalla(String titulo, Widget pantalla) {
    setState(() {
      _selectedScreen = pantalla;
    });
  }

  Future<bool> _onWillPop() async {
    if (_selectedScreen is Container) {
      return true;
    } else {
      setState(() {
        _selectedScreen = Container();
      });
      return false;
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 243, 248, 255),
        body: _usuarioActual == null
            ? _buildMensajeIniciarSesion()
            : (_selectedScreen is Container
                ? _buildMenuPrincipal()
                : _selectedScreen),
      ),
    );
  }

  Widget _buildMensajeIniciarSesion() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color.fromARGB(255, 243, 248, 255),
            const Color.fromARGB(255, 245, 249, 255)
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: const Color(0xFF940016),
                        shape: BoxShape.circle,
                      ),
                      child: Image(
                        image: AssetImage('assets/icon2.png'),
                        width: 80,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'TRANS DORAMALD',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color.fromARGB(255, 46, 45, 45),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'TRANSPORTE TERRESTRE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color.fromARGB(255, 41, 40, 40)
                          .withOpacity(0.8),
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                        Icon(
                          Icons.lock_outline,
                          size: 48,
                          color: primaryBusBlue,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Acceso Restringido',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color.fromARGB(255, 48, 48, 49),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Inicie sesión para acceder a nuestros servicios de transporte y encomiendas',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: textGray,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 40, 40, 41)
                                .withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: primaryBusBlue, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Use el menú superior para iniciar sesión',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textGray,
                                    fontWeight: FontWeight.w500,
                                  ),
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

  Widget _buildMenuPrincipal() {
    final servicios = getServicios();
    final isAdmin =
        _usuarioActual != null && _usuarioActual!.email == 'admin@dominio.com';

    return RefreshIndicator(
      onRefresh: _refrescarPagina,
      color: Color(0xFFE0E7FF),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color.fromARGB(255, 243, 248, 255),
                    const Color.fromARGB(255, 245, 249, 255)
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
                        if (_isLoadingUserData)
                          Container(
                            height: 16,
                            width: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          )
                        else
                          Text(
                            'Hola, $_nombreUsuario',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: const Color.fromARGB(255, 14, 14, 14)
                                  .withOpacity(0.9),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          isAdmin
                              ? 'Panel de Control'
                              : 'Servicios Disponibles',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color.fromARGB(255, 32, 32, 32),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isAdmin
                              ? 'Administración del sistema de transporte'
                              : 'Tu viaje comienza aquí',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color.fromARGB(255, 29, 28, 28)
                                .withOpacity(0.8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? accentOrange
                                : const Color(0xFF940016),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAdmin
                                    ? Icons.admin_panel_settings
                                    : Icons.verified_user,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isAdmin
                                    ? 'ADMINISTRADOR'
                                    : 'USUARIO REGISTRADO',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 1,
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
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final servicio = servicios[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 500),
                    child: SlideAnimation(
                      verticalOffset: 30.0,
                      child: FadeInAnimation(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildServiceCard(servicio),
                        ),
                      ),
                    ),
                  );
                },
                childCount: servicios.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildVersionInfo(),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> servicio) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => servicio['ruta'],
          ),
        );
      },
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
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: servicio['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  servicio['icon'],
                  color: servicio['color'],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      servicio['titulo'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: darkNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      servicio['subtitulo'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: servicio['color'],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      servicio['descripcion'],
                      style: TextStyle(
                        fontSize: 13,
                        color: textGray,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: lightBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: roadGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                roadGray.withOpacity(0.05),
                textGray.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF940016).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: const Color(0xFF940016),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TRANS DORAMALD',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: darkNavy,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sistema de Transporte',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: textGray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified,
                      color: successGreen,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Versión ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textGray,
                      ),
                    ),
                    Text(
                      _appVersion.isNotEmpty ? _appVersion : '...',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: darkNavy,
                      ),
                    ),
                    if (_buildNumber.isNotEmpty) ...[
                      Text(
                        ' (${_buildNumber})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: textGray,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '© ${DateTime.now().year} Trans Doramald',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: textGray.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
