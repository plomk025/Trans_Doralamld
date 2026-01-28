import 'dart:ui';
import 'package:app2tesis/usuario/Pantallas_inicio/informacion.dart';
import 'package:app2tesis/usuario/Pantallas_inicio/menu.dart';
import 'package:app2tesis/usuario/notificaciones.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentPageIndex = 0;
  late PageController _pageController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔔 Stream para escuchar notificaciones en tiempo real
  Stream<int>? _unreadNotificationsStream;

  // Paleta empresarial
  final Color primaryNavy = const Color(0xFF1A2332);
  final Color darkGray = const Color(0xFF2D3748);
  final Color lightGray = const Color(0xFFF7FAFC);
  final Color mediumGray = const Color(0xFF718096);
  final Color accentBlue = const Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPageIndex);
    _setupNotificationsStream();

    // Escuchar cambios en el estado de autenticación
    _auth.authStateChanges().listen((User? user) {
      if (mounted) {
        _setupNotificationsStream();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // 🔔 ==================== CONFIGURAR STREAM DE NOTIFICACIONES ====================
  // 🔔 ==================== CONFIGURAR STREAM DE NOTIFICACIONES ====================
// 🔔 ==================== MÉTODO ACTUALIZADO PARA HOMEPAGE ====================
// Reemplaza el método _setupNotificationsStream() en tu HomePage

  void _setupNotificationsStream() {
    final User? user = _auth.currentUser;

    if (user != null && user.email != null) {
      print('📧 Usuario logueado: ${user.email}');

      _unreadNotificationsStream =
          _firestore.collection('notificaciones').snapshots().map((snapshot) {
        int count = 0;

        for (var doc in snapshot.docs) {
          final data = doc.data();

          // Solo contar notificaciones del usuario O con mensaje3
          bool esDelUsuario = data['email'] == user.email;
          bool tieneMensaje3 = data['mensaje3'] != null &&
              data['mensaje3'].toString().isNotEmpty;

          if (!esDelUsuario && !tieneMensaje3) {
            continue; // Saltar esta notificación
          }

          // Contar mensaje principal si no está leído y es del usuario
          if (esDelUsuario &&
              (data['leida'] ?? false) == false &&
              data['mensaje'] != null &&
              data['mensaje'].toString().isNotEmpty) {
            count++;
          }

          // Contar mensaje2 si existe, no está leído y es del usuario
          if (esDelUsuario &&
              (data['leida2'] ?? false) == false &&
              data['mensaje2'] != null &&
              data['mensaje2'].toString().isNotEmpty) {
            count++;
          }

          // 🆕 VERIFICAR mensaje3 con el MAPA de usuarios
          if (tieneMensaje3 && !_esMensaje3Leido(data, user.email!)) {
            count++;
          }
        }

        print('🔔 Notificaciones no leídas totales: $count');
        return count;
      });

      setState(() {});
    } else {
      print('⚠️ No hay usuario logueado');
      _unreadNotificationsStream = Stream.value(0);
      setState(() {});
    }
  }

// 🆕 ==================== AGREGAR ESTE MÉTODO NUEVO ====================
// Agrega este método en tu clase _HomePageState

  String _sanitizeEmail(String email) {
    return email.replaceAll('.', '_').replaceAll('@', '_at_');
  }

  bool _esMensaje3Leido(Map<String, dynamic> data, String userEmail) {
    if (data['leida3'] == null) return false;

    // Si leida3 es un mapa (nueva estructura)
    if (data['leida3'] is Map) {
      final leida3Map = data['leida3'] as Map<String, dynamic>;
      final sanitizedEmail = _sanitizeEmail(userEmail);
      return leida3Map[sanitizedEmail] == true;
    }

    // Si leida3 es un booleano (compatibilidad con estructura antigua)
    if (data['leida3'] is bool) {
      return data['leida3'] as bool;
    }

    return false;
  }

  // Obtener dimensiones responsivas
  double _getResponsiveSize(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return mobile;
    if (width < 1200) return tablet;
    return desktop;
  }

  // 📱 ==================== GUARDAR FCM TOKEN ====================
  Future<void> _saveFCMTokenAfterLogin() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print('⚠️ No hay usuario logueado');
        return;
      }

      String? token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        await _firestore.collection('usuarios_registrados').doc(user.uid).set({
          'email': user.email,
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        print('✅ FCM Token guardado correctamente');
        print('📱 Token: ${token.substring(0, 30)}...');
      } else {
        print('⚠️ No se pudo obtener el FCM token');
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _firestore.collection('usuarios_registrados').doc(user.uid).update({
          'fcmToken': newToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        print('🔄 FCM Token actualizado');
      });
    } catch (e) {
      print('❌ Error al guardar FCM token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final isTablet =
            constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
        final isDesktop = constraints.maxWidth >= 1200;

        return WillPopScope(
          onWillPop: () async {
            if (_currentPageIndex == 0) {
              return true;
            } else {
              _pageController.jumpToPage(0);
              return false;
            }
          },
          child: Scaffold(
            appBar: _buildAppBar(context, isSmallScreen, isTablet, isDesktop),
            body: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              children: [
                TransDoramaldHomeScreen(),
                MenuCuadrosScreen(),
                NotificacionesScreen(
                  userEmail: FirebaseAuth.instance.currentUser?.email ?? "",
                )
              ],
            ),
            bottomNavigationBar:
                _buildBottomNavigationBar(context, isSmallScreen, isTablet),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, bool isSmall, bool isTablet, bool isDesktop) {
    final iconSize = _getResponsiveSize(
      context,
      mobile: 18,
      tablet: 20,
      desktop: 22,
    );

    final titleSize = _getResponsiveSize(
      context,
      mobile: 15,
      tablet: 17,
      desktop: 19,
    );

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmall ? 4 : 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              _currentPageIndex == 0
                  ? 'assets/icon2.png' // Imagen para información
                  : _currentPageIndex == 1
                      ? 'assets/icon2.png' // Imagen para menú
                      : 'assets/icon2.png', // Imagen para notificaciones
              width: 30,
              height: 30,
            ),
          ),
          SizedBox(width: isSmall ? 10 : 12),
          Flexible(
            child: Text(
              _getPageTitle(_currentPageIndex),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: titleSize,
                color: darkGray,
                letterSpacing: -0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      centerTitle: false,
      automaticallyImplyLeading: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.grey[200],
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'login') {
              _showLoginModal(context);
            } else if (value == 'logout') {
              _logout();
            } else if (value == 'register') {
              _showRegisterModal(context);
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              if (_auth.currentUser == null)
                PopupMenuItem<String>(
                  value: 'login',
                  child: Row(
                    children: [
                      Icon(Icons.login_rounded, color: primaryNavy, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Iniciar sesión',
                        style: TextStyle(
                          color: darkGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_auth.currentUser == null)
                PopupMenuItem<String>(
                  value: 'register',
                  child: Row(
                    children: [
                      Icon(Icons.person_add_rounded,
                          color: primaryNavy, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Registrarse',
                        style: TextStyle(
                          color: darkGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_auth.currentUser != null)
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded,
                          color: const Color(0xFFEF4444), size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Cerrar sesión',
                        style: TextStyle(
                          color: const Color(0xFFEF4444),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ];
          },
          icon: Container(
            padding: EdgeInsets.all(isSmall ? 6 : 8),
            decoration: BoxDecoration(
              color: lightGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.more_vert_rounded, color: darkGray, size: 20),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          offset: const Offset(0, 10),
        ),
        SizedBox(width: isSmall ? 8 : 12),
      ],
    );
  }

  // 🔔 ==================== WIDGET DE BADGE PROFESIONAL ====================
  Widget _buildNotificationBadge({
    required Widget child,
    required int count,
    required bool isSelected,
  }) {
    if (count == 0) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: count > 9 ? 5 : 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFEF4444),
                  const Color(0xFFDC2626),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(
              minWidth: 18,
              minHeight: 18,
            ),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar(
      BuildContext context, bool isSmall, bool isTablet) {
    final iconSize = _getResponsiveSize(
      context,
      mobile: 22,
      tablet: 24,
      desktop: 26,
    );

    final labelSize = _getResponsiveSize(
      context,
      mobile: 11,
      tablet: 12,
      desktop: 13,
    );

    return Container(
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
        child: BottomNavigationBar(
          currentIndex: _currentPageIndex,
          onTap: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          items: [
            // INFORMACIÓN
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(isSmall ? 6 : 8),
                decoration: BoxDecoration(
                  color: _currentPageIndex == 0
                      ? primaryNavy.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(
                  'assets/informacion.png',
                  width: iconSize,
                  height: iconSize,
                  color: _currentPageIndex == 0 ? primaryNavy : mediumGray,
                ),
              ),
              label: 'Información',
            ),

            // MENÚ
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(isSmall ? 6 : 8),
                decoration: BoxDecoration(
                  color: _currentPageIndex == 1
                      ? primaryNavy.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(
                  'assets/menu.png',
                  width: iconSize,
                  height: iconSize,
                  color: _currentPageIndex == 1 ? primaryNavy : mediumGray,
                ),
              ),
              label: 'Menú',
            ),

            // 🔔 NOTIFICACIONES CON BADGE
            BottomNavigationBarItem(
              icon: StreamBuilder<int>(
                stream: _unreadNotificationsStream,
                initialData: 0,
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;

                  return _buildNotificationBadge(
                    count: count,
                    isSelected: _currentPageIndex == 2,
                    child: Container(
                      padding: EdgeInsets.all(isSmall ? 6 : 8),
                      decoration: BoxDecoration(
                        color: _currentPageIndex == 2
                            ? primaryNavy.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.asset(
                        'assets/notificacion.png',
                        width: iconSize,
                        height: iconSize,
                        color:
                            _currentPageIndex == 2 ? primaryNavy : mediumGray,
                      ),
                    ),
                  );
                },
              ),
              label: 'Notificaciones',
            ),
          ],
          selectedItemColor: primaryNavy,
          unselectedItemColor: mediumGray,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: labelSize,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: labelSize,
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }

  void _showLoginModal(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final maxWidth = width < 600 ? width * 0.9 : 400.0;
    final horizontalPadding = width < 600 ? 16.0 : 20.0;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(width < 600 ? 20 : 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(width < 600 ? 8 : 10),
                          decoration: BoxDecoration(
                            color: primaryNavy.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.asset(
                            'assets/icon2.png',
                            width: 26,
                            height: 26,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Flexible(
                          child: Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              color: darkGray,
                              fontSize: width < 600 ? 18 : 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: width < 600 ? 20 : 24),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Correo electrónico',
                      hint: 'tu@email.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: width < 600 ? 14 : 16),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Contraseña',
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      obscureText: true,
                    ),
                    SizedBox(height: width < 600 ? 20 : 24),
                    SizedBox(
                      width: double.infinity,
                      height: width < 600 ? 48 : 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_emailController.text == 'admin@dominio.com' &&
                              _passwordController.text == 'adminpassword') {
                            _showVerificationCodeField(context);
                          } else if (_emailController.text !=
                              'admin@dominio.com') {
                            _signInWithEmail(context);
                          }
                        },
                        icon: Icon(Icons.login_rounded,
                            size: width < 600 ? 18 : 20),
                        label: Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                            fontSize: width < 600 ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF940016),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: primaryNavy.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: width < 600 ? 14 : 16),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'o continúa con',
                            style: TextStyle(
                              color: mediumGray,
                              fontSize: width < 600 ? 12 : 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),
                    SizedBox(height: width < 600 ? 14 : 16),
                    SizedBox(
                      width: double.infinity,
                      height: width < 600 ? 48 : 52,
                      child: OutlinedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: Image.asset(
                          'assets/google_icon.png',
                          height: width < 600 ? 18 : 20,
                          width: width < 600 ? 18 : 20,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.login,
                              color: Colors.red,
                              size: width < 600 ? 18 : 20,
                            );
                          },
                        ),
                        label: Text(
                          'Continuar con Google',
                          style: TextStyle(
                            fontSize: width < 600 ? 13 : 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: darkGray,
                          side:
                              BorderSide(color: Colors.grey[300]!, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: width < 600 ? 16 : 20),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color: mediumGray,
                            fontWeight: FontWeight.w600,
                            fontSize: width < 600 ? 14 : 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showVerificationCodeField(BuildContext context) {
    Navigator.pop(context);
    final width = MediaQuery.of(context).size.width;
    final maxWidth = width < 600 ? width * 0.9 : 400.0;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        TextEditingController codeController = TextEditingController();

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: width < 600 ? 16 : 20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                decoration: BoxDecoration(
                  color: primaryNavy,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(width < 600 ? 20 : 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(width < 600 ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.verified_user_rounded,
                        color: Colors.white,
                        size: width < 600 ? 28 : 32,
                      ),
                    ),
                    SizedBox(height: width < 600 ? 16 : 20),
                    Text(
                      'Verificación de Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width < 600 ? 18 : 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: width < 600 ? 6 : 8),
                    Text(
                      'Ingresa el código de seguridad',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: width < 600 ? 13 : 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: width < 600 ? 20 : 24),
                    TextField(
                      controller: codeController,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width < 600 ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.15),
                        hintText: '••••',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: width < 600 ? 18 : 20,
                        ),
                        counterText: '',
                        prefixIcon: const Icon(Icons.password_rounded,
                            color: Colors.white),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: width < 600 ? 20 : 24),
                    SizedBox(
                      width: double.infinity,
                      height: width < 600 ? 48 : 52,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (codeController.text == '1234') {
                            try {
                              final String email = _emailController.text.trim();
                              final String password =
                                  _passwordController.text.trim();

                              UserCredential userCredential = await FirebaseAuth
                                  .instance
                                  .signInWithEmailAndPassword(
                                email: email,
                                password: password,
                              );

                              await _firestore
                                  .collection('usuarios_registrados')
                                  .doc(userCredential.user!.uid)
                                  .set({
                                'email': email,
                                'role': 'admin',
                                'createdAt': FieldValue.serverTimestamp(),
                              }, SetOptions(merge: true));

                              await _saveFCMTokenAfterLogin();
                              _setupNotificationsStream();

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: const [
                                        Icon(Icons.check_circle,
                                            color: Colors.white),
                                        SizedBox(width: 12),
                                        Expanded(
                                            child: Text(
                                                'Acceso administrativo concedido')),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFF10B981),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                                Navigator.pop(context);
                                setState(() {});
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error de autenticación: $e'),
                                    backgroundColor: const Color(0xFFEF4444),
                                  ),
                                );
                              }
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: const [
                                    Icon(Icons.error_outline,
                                        color: Colors.white),
                                    SizedBox(width: 12),
                                    Text('Código incorrecto'),
                                  ],
                                ),
                                backgroundColor: const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        },
                        icon: Icon(Icons.check_circle_rounded,
                            size: width < 600 ? 18 : 20),
                        label: Text(
                          'Verificar Código',
                          style: TextStyle(
                            fontSize: width < 600 ? 14 : 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryNavy,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: width < 600 ? 14 : 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRegisterModal(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final maxWidth = width < 600 ? width * 0.9 : 400.0;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: width < 600 ? 16 : 20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(width < 600 ? 20 : 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(width < 600 ? 8 : 10),
                          decoration: BoxDecoration(
                            color: accentBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.asset(
                            'assets/icon2.png',
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Flexible(
                          child: Text(
                            'Crear Cuenta',
                            style: TextStyle(
                              color: darkGray,
                              fontSize: width < 600 ? 18 : 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: width < 600 ? 20 : 24),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Correo electrónico',
                      hint: 'tu@email.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: width < 600 ? 14 : 16),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Contraseña',
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      obscureText: true,
                    ),
                    SizedBox(height: width < 600 ? 20 : 24),
                    SizedBox(
                      width: double.infinity,
                      height: width < 600 ? 48 : 52,
                      child: ElevatedButton.icon(
                        onPressed: _registerWithEmail,
                        icon: Icon(Icons.person_add_rounded,
                            color: const Color(0xFF940016),
                            size: width < 600 ? 18 : 20),
                        label: Text(
                          'Crear Cuenta',
                          style: TextStyle(
                            fontSize: width < 600 ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF940016),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: accentBlue.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: width < 600 ? 16 : 20),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color: mediumGray,
                            fontWeight: FontWeight.w600,
                            fontSize: width < 600 ? 14 : 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============= FUNCIONES AUXILIARES =============

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: darkGray,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 15,
            color: darkGray,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: mediumGray.withOpacity(0.5),
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: primaryNavy, size: 20),
            filled: true,
            fillColor: lightGray,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryNavy, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  void _signInWithEmail(BuildContext context) async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore
          .collection('usuarios_registrados')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _saveFCMTokenAfterLogin();
      _setupNotificationsStream();

      if (!mounted) return;

      Navigator.pop(context, true); // 👈 solo cerramos
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.message}'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        scopes: ['email'],
      ).signIn();

      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection('usuarios_registrados').doc(user.uid).set({
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await _saveFCMTokenAfterLogin();
        _setupNotificationsStream();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Sesión iniciada con Google'),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.of(context, rootNavigator: true).pop();
          setState(() {});
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _registerWithEmail() async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _firestore
          .collection('usuarios_registrados')
          .doc(userCredential.user!.uid)
          .set({
        'email': _emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _saveFCMTokenAfterLogin();
      _setupNotificationsStream();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Cuenta creada exitosamente'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
        setState(() {});
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = 'Error al crear la cuenta';

        if (e.code == 'weak-password') {
          errorMessage = 'La contraseña es muy débil';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'Este correo ya está registrado';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Correo electrónico inválido';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _logout() async {
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut();

      _setupNotificationsStream();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.exit_to_app, color: Colors.white),
                SizedBox(width: 12),
                Text('Sesión cerrada correctamente'),
              ],
            ),
            backgroundColor: primaryNavy,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  String _getPageTitle(int index) {
    return ['Información', 'Menú', 'Notificaciones'][index];
  }
}
