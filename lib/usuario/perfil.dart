import 'package:app2tesis/usuario/Pantallas_inicio/iniciarsesion.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PerfilUsuarioScreen extends StatefulWidget {
  const PerfilUsuarioScreen({Key? key}) : super(key: key);

  @override
  _PerfilUsuarioScreenState createState() => _PerfilUsuarioScreenState();
}

class _PerfilUsuarioScreenState extends State<PerfilUsuarioScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  User? currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  // Estadísticas
  int totalViajes = 0;
  double totalGastado = 0;
  int viajesPendientes = 0;

  // Paleta de colores empresarial
  final Color primaryBlue = const Color.fromARGB(255, 230, 230, 230);
  final Color darkBlue = const Color.fromARGB(255, 155, 155, 155);
  final Color lightBlue = const Color(0xFFDEEAFF);
  final Color accentOrange = const Color.fromARGB(255, 255, 255, 255);
  final Color darkGray = const Color(0xFF1F2937);
  final Color mediumGray = const Color(0xFF6B7280);
  final Color lightGray = const Color.fromARGB(255, 255, 255, 255);
  final Color successGreen = const Color(0xFF059669);
  final Color borderGray = const Color.fromARGB(255, 235, 231, 229);

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      currentUser = auth.currentUser;

      if (currentUser != null) {
        // Cargar datos del usuario
        final userDoc = await db
            .collection('usuarios_registrados')
            .doc(currentUser!.uid)
            .get();
        if (userDoc.exists) {
          userData = userDoc.data();
        }

        // Calcular estadísticas
        await _calcularEstadisticas();
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error al cargar datos: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _calcularEstadisticas() async {
    if (currentUser == null) return;

    try {
      // Total de viajes (comprados)
      final comprados = await db
          .collection('comprados')
          .where('userId', isEqualTo: currentUser!.uid)
          .get();

      totalViajes = comprados.docs.length;
      totalGastado = 0;

      for (var doc in comprados.docs) {
        totalGastado += (doc.data()['total'] ?? 0).toDouble();
      }

      // Viajes pendientes (reservas activas)
      final reservas = await db
          .collection('reservas')
          .where('userId', isEqualTo: currentUser!.uid)
          .where('estado',
              whereIn: ['pendiente_verificacion', 'aprobado']).get();

      viajesPendientes = reservas.docs.length;
    } catch (e) {
      print('Error al calcular estadísticas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: lightGray,
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
              ),
            )
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildHeaderPerfil(),
                      const SizedBox(height: 20),
                      _buildEstadisticas(),
                      const SizedBox(height: 20),
                      _buildInformacionPersonal(isTablet),
                      const SizedBox(height: 20),
                      _buildInformacionCuenta(isTablet),
                      const SizedBox(height: 20),
                      _buildAccionesRapidas(),
                      const SizedBox(height: 20),
                      _buildBotonCerrarSesion(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: primaryBlue,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 0, 0, 0)),
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
            (route) => false,
          );
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: const [
                Color.fromARGB(255, 255, 255, 255),
                Color.fromARGB(255, 230, 230, 230)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderPerfil() {
    final nombre = userData?['nombre'] ?? currentUser?.displayName ?? 'Usuario';
    final email = userData?['email'] ?? currentUser?.email ?? 'No disponible';
    final iniciales = _obtenerIniciales(nombre);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      transform: Matrix4.translationValues(0, -40, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [accentOrange, accentOrange.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: accentOrange.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      iniciales,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: successGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Nombre
            Text(
              nombre,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            // Email con icono
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email_outlined, size: 16, color: mediumGray),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      color: mediumGray,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Badge de cliente
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryBlue.withOpacity(0.1),
                    lightBlue.withOpacity(0.3)
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryBlue.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Color.fromARGB(2, 0, 0, 0), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Cliente Trans Doramald',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticas() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(2, 255, 74, 74).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Mis Estadísticas',
                style: TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  Icons.confirmation_number,
                  'Viajes',
                  totalViajes.toString(),
                  'Realizados',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  Icons.attach_money,
                  'Gastado',
                  '\$${totalGastado.toStringAsFixed(0)}',
                  'Total',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  Icons.schedule,
                  'Pendientes',
                  viajesPendientes.toString(),
                  'Próximos',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      IconData icon, String label, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformacionPersonal(bool isTablet) {
    final nombre = userData?['nombre'] ?? currentUser?.displayName ?? 'Usuario';
    final telefono =
        userData?['telefono'] ?? userData?['celular'] ?? 'No especificado';
    final cedula = userData?['cedula'] ?? 'No especificada';
    final fechaCreacion = currentUser?.metadata.creationTime;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person_outline, color: primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Información Personal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.badge_outlined, 'Nombre Completo', nombre),
          _buildDivider(),
          _buildInfoRow(Icons.phone_outlined, 'Teléfono', telefono),
          _buildDivider(),
          _buildInfoRow(Icons.credit_card_outlined, 'Cédula', cedula),
          if (fechaCreacion != null) ...[
            _buildDivider(),
            _buildInfoRow(
              Icons.calendar_today_outlined,
              'Miembro desde',
              DateFormat('dd/MM/yyyy').format(fechaCreacion),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInformacionCuenta(bool isTablet) {
    final email = currentUser?.email ?? 'No disponible';
    final emailVerificado = currentUser?.emailVerified ?? false;
    final uid = currentUser?.uid ?? 'No disponible';
    final ultimoAcceso = currentUser?.metadata.lastSignInTime;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.security_outlined,
                    color: successGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Información de la Cuenta',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.email_outlined, 'Correo Electrónico', email),
          _buildDivider(),
          Row(
            children: [
              Icon(Icons.verified_user_outlined, size: 20, color: mediumGray),
              const SizedBox(width: 12),
              Text(
                'Estado del Email:',
                style: TextStyle(
                  fontSize: 13,
                  color: mediumGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: emailVerificado
                      ? successGreen.withOpacity(0.1)
                      : accentOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: emailVerificado
                        ? successGreen.withOpacity(0.3)
                        : accentOrange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      emailVerificado ? Icons.check_circle : Icons.warning,
                      size: 14,
                      color: emailVerificado ? successGreen : accentOrange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      emailVerificado ? 'Verificado' : 'Sin verificar',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: emailVerificado ? successGreen : accentOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          _buildDivider(),
          _buildInfoRow(
            Icons.fingerprint_outlined,
            'ID de Usuario',
            '${uid.substring(0, 8)}...',
          ),
          if (ultimoAcceso != null) ...[
            _buildDivider(),
            _buildInfoRow(
              Icons.access_time_outlined,
              'Último acceso',
              DateFormat('dd/MM/yyyy HH:mm').format(ultimoAcceso),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccionesRapidas() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
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
                child: Icon(Icons.flash_on_outlined,
                    color: accentOrange, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Acciones Rápidas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            Icons.edit_outlined,
            'Editar Perfil',
            'Actualiza tu información personal',
            primaryBlue,
            () => _editarPerfil(),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            Icons.lock_outline,
            'Cambiar Contraseña',
            'Modifica tu contraseña de acceso',
            successGreen,
            () => _cambiarContrasena(),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            Icons.history_outlined,
            'Historial de Viajes',
            'Revisa todos tus viajes anteriores',
            accentOrange,
            () {
              // Navegar al historial
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: darkGray,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: mediumGray,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: mediumGray),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonCerrarSesion() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFEF4444),
          side: const BorderSide(color: Color(0xFFEF4444), width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.logout, size: 22),
        label: const Text(
          'Cerrar Sesión',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: () => _cerrarSesion(),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: mediumGray),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                color: mediumGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: darkGray,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: borderGray,
      height: 24,
    );
  }

  String _obtenerIniciales(String nombre) {
    if (nombre.isEmpty) return 'U';

    final palabras = nombre.trim().split(' ');
    if (palabras.length == 1) {
      return palabras[0][0].toUpperCase();
    }

    return '${palabras[0][0]}${palabras[1][0]}'.toUpperCase();
  }

  void _editarPerfil() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit, color: primaryBlue),
            const SizedBox(width: 12),
            const Text('Editar Perfil'),
          ],
        ),
        content: const Text(
          'Función de edición de perfil en desarrollo.\n\nPronto podrás actualizar tu información personal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _cambiarContrasena() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lock, color: successGreen),
            const SizedBox(width: 12),
            const Text('Cambiar Contraseña'),
          ],
        ),
        content: const Text(
          'Se enviará un correo de recuperación a tu email registrado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: mediumGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: successGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              try {
                await auth.sendPasswordResetEmail(email: currentUser!.email!);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Correo de recuperación enviado'),
                    backgroundColor: successGreen,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error al enviar correo'),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _cerrarSesion() async {
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.logout,
                color: Color(0xFFEF4444),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Cerrar Sesión'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: mediumGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await auth.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
        (route) => false,
      );
    }
  }
}
