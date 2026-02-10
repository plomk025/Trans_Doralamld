import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // NUEVO: Importar Firebase Auth

// ==================== PANTALLA PRINCIPAL DE GESTIÓN DE RUTAS ====================
class AgregarNombrePage extends StatefulWidget {
  const AgregarNombrePage({super.key});

  @override
  _AgregarNombrePageState createState() => _AgregarNombrePageState();
}

class _AgregarNombrePageState extends State<AgregarNombrePage> {
  // Paleta de colores moderna
  static const Color primaryBusBlue = Color(0xFF1E40AF);
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color roadGray = Color(0xFF334155);
  static const Color lightBg = Color(0xFFF1F5F9);
  static const Color textGray = Color(0xFF475569);
  static const Color successGreen = Color(0xFF059669);

  // NUEVO: Variables para verificar el rol
  bool _isAdmin = false;
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _verificarRolUsuario();
  }

  // NUEVO: Método para verificar si el usuario es administrador
  Future<void> _verificarRolUsuario() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          _isAdmin = false;
          _isLoadingRole = false;
        });
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios_registrados')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final rol = userDoc.data()?['rol'] ?? '';
        setState(() {
          _isAdmin = rol.toLowerCase() == 'administrador';
          _isLoadingRole = false;
        });
      } else {
        setState(() {
          _isAdmin = false;
          _isLoadingRole = false;
        });
      }
    } catch (e) {
      print('Error al verificar rol: $e');
      setState(() {
        _isAdmin = false;
        _isLoadingRole = false;
      });
    }
  }

  // NUEVO: Método para mostrar mensaje de acceso denegado
  void _mostrarAccesoDenegado() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.block_rounded,
                color: Color(0xFFEF4444),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Acceso Denegado',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: darkNavy,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Solo los administradores pueden gestionar rutas. Por favor, contacte a un administrador del sistema.',
          style: TextStyle(fontSize: 14, color: textGray, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBusBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    // NUEVO: Mostrar loading mientras se verifica el rol
    if (_isLoadingRole) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 243, 248, 255),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryBusBlue),
            strokeWidth: 3,
          ),
        ),
      );
    }

    // NUEVO: Mostrar pantalla de acceso denegado si no es admin
    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 243, 248, 255),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 80,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Acceso Restringido',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: darkNavy,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Esta sección está disponible solo para administradores del sistema.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: textGray,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Volver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBusBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 248, 255),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, isTablet)),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildOptionCard(
                  context: context,
                  icon: Icons.add_road_rounded,
                  iconColor: successGreen,
                  title: 'Agregar Ruta',
                  subtitle: 'Nueva ruta',
                  description: 'Registra nuevas rutas y destinos en el sistema',
                  features: [
                    'Gestión rápida',
                    'Múltiples orígenes',
                    'Fácil configuración',
                  ],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AgregarRutaScreen(),
                      ),
                    );
                  },
                  isTablet: isTablet,
                ),
                const SizedBox(height: 12),
                _buildOptionCard(
                  context: context,
                  icon: Icons.list_alt_rounded,
                  iconColor: primaryBusBlue,
                  title: 'Ver Rutas',
                  subtitle: 'Administración',
                  description: 'Consulta, edita y elimina rutas existentes',
                  features: [
                    'Búsqueda avanzada',
                    'Filtros por origen',
                    'Edición rápida',
                  ],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VerRutasScreen(),
                      ),
                    );
                  },
                  isTablet: isTablet,
                ),
                const SizedBox(height: 20),
                _buildInfoSection(),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 243, 248, 255),
            Color.fromARGB(255, 245, 249, 255),
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
                                    .withOpacity(0.15),
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
                          Text(
                            'GESTIÓN DE RUTAS',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w900,
                              color: const Color.fromARGB(255, 26, 25, 25),
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Panel administrativo',
                            style: TextStyle(
                              fontSize: isTablet ? 12 : 10,
                              fontWeight: FontWeight.w500,
                              color: const Color.fromARGB(255, 76, 77, 78),
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
                        color: const Color.fromARGB(0, 248, 248, 248),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(0, 255, 255, 255)
                                .withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.route_rounded,
                        color: Color(0xFF940016),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Gestión de Rutas',
                style: TextStyle(
                  fontSize: isTablet ? 32 : 30,
                  fontWeight: FontWeight.w900,
                  color: const Color.fromARGB(255, 32, 31, 31),
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Administra y configura las rutas del sistema de forma rápida y eficiente',
                style: TextStyle(
                  fontSize: isTablet ? 15 : 14,
                  color: const Color.fromARGB(255, 84, 86, 88),
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildStatChip(Icons.admin_panel_settings_rounded, 'Admin'),
                  const SizedBox(width: 10),
                  _buildStatChip(Icons.verified_rounded, 'Seguro'),
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
              color: darkNavy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String description,
    required List<String> features,
    required VoidCallback onTap,
    required bool isTablet,
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
                      color: roadGray,
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
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: lightBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: iconColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Características:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: darkNavy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...features.map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: iconColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: textGray,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
        border: Border.all(color: primaryBusBlue.withOpacity(0.2), width: 1),
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
                '¿Cómo gestionar?',
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
            title: 'Agregar rutas',
            description: 'Crea nuevas rutas seleccionando el origen',
            icon: Icons.add_circle_outline_rounded,
          ),
          const SizedBox(height: 14),
          _buildInfoStep(
            number: '2',
            title: 'Configura precios',
            description: 'Define el costo de cada pasaje',
            icon: Icons.attach_money_rounded,
          ),
          const SizedBox(height: 14),
          _buildInfoStep(
            number: '3',
            title: 'Administra rutas',
            description: 'Edita o elimina rutas existentes',
            icon: Icons.edit_rounded,
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
}

// ==================== PANTALLA AGREGAR RUTA ====================
class AgregarRutaScreen extends StatefulWidget {
  const AgregarRutaScreen({super.key});

  @override
  _AgregarRutaScreenState createState() => _AgregarRutaScreenState();
}

class _AgregarRutaScreenState extends State<AgregarRutaScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String _origenSeleccionado = 'Tulcán';

  static const Color primaryBusBlue = Color(0xFF1E40AF);
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color lightBg = Color(0xFFF1F5F9);
  static const Color textGray = Color(0xFF475569);
  static const Color successGreen = Color(0xFF059669);

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _agregarRuta() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final nombre = _nameController.text.trim();
      final precio = double.parse(_priceController.text.trim());

      final coleccion = _origenSeleccionado == 'Tulcán'
          ? 'paradas_salida_tulcan'
          : 'paradas_salida_la_esperanza';

      await FirebaseFirestore.instance.collection(coleccion).add({
        'nombre': nombre,
        'precio': precio,
        'origen': _origenSeleccionado,
        'fecha_creacion': Timestamp.now(),
      });

      _nameController.clear();
      _priceController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ruta agregada exitosamente desde $_origenSeleccionado',
                  ),
                ),
              ],
            ),
            backgroundColor: successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar ruta: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: darkNavy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey[200]),
        ),
        title: Text(
          'Agregar Nueva Ruta',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: isTablet ? 18 : 16,
            color: darkNavy,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 32 : 20),
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 600 : double.infinity,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          successGreen.withOpacity(0.1),
                          primaryBusBlue.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: successGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: successGreen, size: 24),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Complete los datos para registrar una nueva ruta en el sistema',
                            style: TextStyle(
                              fontSize: 13,
                              color: darkNavy,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Origen de la Ruta',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: darkNavy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _origenSeleccionado = 'Tulcán';
                              });
                            },
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: _origenSeleccionado == 'Tulcán'
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF1E40AF),
                                          Color(0xFF1E3A8A),
                                        ],
                                      )
                                    : null,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_city_rounded,
                                    size: 20,
                                    color: _origenSeleccionado == 'Tulcán'
                                        ? Colors.white
                                        : textGray,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tulcán',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: _origenSeleccionado == 'Tulcán'
                                          ? Colors.white
                                          : textGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: Colors.grey[300],
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _origenSeleccionado = 'La Esperanza';
                              });
                            },
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: _origenSeleccionado == 'La Esperanza'
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFFEA580C),
                                          Color(0xFFC2410C),
                                        ],
                                      )
                                    : null,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.landscape_rounded,
                                    size: 20,
                                    color: _origenSeleccionado == 'La Esperanza'
                                        ? Colors.white
                                        : textGray,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'La Esperanza',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          _origenSeleccionado == 'La Esperanza'
                                              ? Colors.white
                                              : textGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Nombre de la Ruta',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: darkNavy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Ej: Chical, La Carolina, etc.',
                      hintStyle: TextStyle(color: textGray),
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: textGray,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: primaryBusBlue,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, ingrese el nombre de la ruta';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Precio del Pasaje',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: darkNavy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(color: textGray),
                      prefixIcon: Icon(
                        Icons.attach_money_rounded,
                        color: textGray,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: primaryBusBlue,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, ingrese un precio';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Por favor, ingrese un precio válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _agregarRuta,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: successGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 18 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      shadowColor: successGreen.withOpacity(0.3),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle_outline, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Agregar Ruta',
                                style: TextStyle(
                                  fontSize: isTablet ? 16 : 15,
                                  fontWeight: FontWeight.w700,
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
}

// El resto del código (VerRutasScreen) permanece igual...

// ==================== PANTALLA VER RUTAS ====================
class VerRutasScreen extends StatefulWidget {
  const VerRutasScreen({super.key});

  @override
  _VerRutasScreenState createState() => _VerRutasScreenState();
}

class _VerRutasScreenState extends State<VerRutasScreen> {
  static const Color primaryBusBlue = Color(0xFF1E40AF);
  static const Color accentOrange = Color(0xFFEA580C);
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color lightBg = Color(0xFFF1F5F9);
  static const Color textGray = Color(0xFF475569);

  String _searchQuery = '';
  String _origenFiltro = 'Todos';

  Future<void> _eliminarRuta(
    String docId,
    String nombre,
    String coleccion,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Color(0xFFEF4444),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Confirmar Eliminación',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: darkNavy,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '¿Está seguro que desea eliminar la ruta "$nombre"? Esta acción no se puede deshacer.',
          style: const TextStyle(fontSize: 14, color: textGray, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: textGray, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await FirebaseFirestore.instance
            .collection(coleccion)
            .doc(docId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Ruta eliminada exitosamente'),
                ],
              ),
              backgroundColor: accentOrange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }

  void _editarRuta(
    String docId,
    String nombre,
    double precio,
    String coleccion,
    String origen,
  ) {
    final editNameController = TextEditingController(text: nombre);
    final editPriceController = TextEditingController(
      text: precio.toStringAsFixed(2),
    );
    final editFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryBusBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: primaryBusBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Editar Ruta',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: darkNavy,
              ),
            ),
          ],
        ),
        content: Form(
          key: editFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (origen == 'Tulcán' ? primaryBusBlue : accentOrange)
                          .withOpacity(0.1),
                      (origen == 'Tulcán' ? primaryBusBlue : accentOrange)
                          .withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (origen == 'Tulcán' ? primaryBusBlue : accentOrange)
                        .withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      origen == 'Tulcán'
                          ? Icons.location_city_rounded
                          : Icons.landscape_rounded,
                      color: origen == 'Tulcán' ? primaryBusBlue : accentOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Origen: $origen',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color:
                            origen == 'Tulcán' ? primaryBusBlue : accentOrange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nombre de la Ruta',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: darkNavy,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: editNameController,
                decoration: InputDecoration(
                  hintText: 'Nombre de la ruta',
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese el nombre de la ruta';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Precio',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: darkNavy,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: editPriceController,
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.attach_money_rounded, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese un precio';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingrese un precio válido';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: textGray, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!editFormKey.currentState!.validate()) return;

              try {
                final nuevoNombre = editNameController.text.trim();
                final nuevoPrecio = double.parse(
                  editPriceController.text.trim(),
                );

                await FirebaseFirestore.instance
                    .collection(coleccion)
                    .doc(docId)
                    .update({'nombre': nuevoNombre, 'precio': nuevoPrecio});

                Navigator.pop(context);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Ruta actualizada exitosamente'),
                        ],
                      ),
                      backgroundColor: primaryBusBlue,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al actualizar: $e'),
                      backgroundColor: const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBusBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: darkNavy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey[200]),
        ),
        title: Text(
          'Rutas Registradas',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: isTablet ? 18 : 16,
            color: darkNavy,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
              isTablet ? 32 : 20,
              16,
              isTablet ? 32 : 20,
              16,
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: lightBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _origenFiltro = 'Todos';
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _origenFiltro == 'Todos'
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _origenFiltro == 'Todos'
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.all_inclusive_rounded,
                                  size: 18,
                                  color: _origenFiltro == 'Todos'
                                      ? primaryBusBlue
                                      : textGray,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Todos',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _origenFiltro == 'Todos'
                                        ? primaryBusBlue
                                        : textGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _origenFiltro = 'Tulcán';
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _origenFiltro == 'Tulcán'
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _origenFiltro == 'Tulcán'
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_city_rounded,
                                  size: 18,
                                  color: _origenFiltro == 'Tulcán'
                                      ? primaryBusBlue
                                      : textGray,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Tulcán',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _origenFiltro == 'Tulcán'
                                        ? primaryBusBlue
                                        : textGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _origenFiltro = 'La Esperanza';
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _origenFiltro == 'La Esperanza'
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _origenFiltro == 'La Esperanza'
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.landscape_rounded,
                                  size: 18,
                                  color: _origenFiltro == 'La Esperanza'
                                      ? accentOrange
                                      : textGray,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'La Esperanza',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _origenFiltro == 'La Esperanza'
                                        ? accentOrange
                                        : textGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: lightBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Buscar ruta...',
                            hintStyle: TextStyle(color: textGray, fontSize: 14),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: textGray,
                              size: 22,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    StreamBuilder<List<int>>(
                      stream: _getCombinedCountStream(),
                      builder: (context, snapshot) {
                        final count = snapshot.hasData
                            ? snapshot.data!.reduce((a, b) => a + b)
                            : 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E40AF), Color(0xFF1E3A8A)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: _buildCombinedRutasList(isTablet, padding)),
        ],
      ),
    );
  }

  Stream<List<int>> _getCombinedCountStream() {
    return Stream.periodic(const Duration(milliseconds: 500), (_) async {
      final personaSnapshot = await FirebaseFirestore.instance
          .collection('paradas_salida_tulcan')
          .get();
      final paradasSnapshot = await FirebaseFirestore.instance
          .collection('paradas_salida_la_esperanza')
          .get();

      int personaCount = personaSnapshot.docs.length;
      int paradasCount = paradasSnapshot.docs.length;

      if (_origenFiltro == 'Tulcán') {
        return [personaCount, 0];
      } else if (_origenFiltro == 'La Esperanza') {
        return [0, paradasCount];
      }
      return [personaCount, paradasCount];
    }).asyncMap((event) => event);
  }

  Widget _buildCombinedRutasList(bool isTablet, EdgeInsets padding) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('paradas_salida_tulcan')
          .snapshots(),
      builder: (context, personaSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('paradas_salida_la_esperanza')
              .snapshots(),
          builder: (context, paradasSnapshot) {
            if (personaSnapshot.connectionState == ConnectionState.waiting ||
                paradasSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryBusBlue),
                  strokeWidth: 3,
                ),
              );
            }

            if (personaSnapshot.hasError || paradasSnapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Error al cargar las rutas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: darkNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Por favor, intente nuevamente',
                      style: TextStyle(fontSize: 14, color: textGray),
                    ),
                  ],
                ),
              );
            }

            List<Map<String, dynamic>> todasLasRutas = [];

            if (_origenFiltro == 'Todos' || _origenFiltro == 'Tulcán') {
              if (personaSnapshot.hasData) {
                for (var doc in personaSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  todasLasRutas.add({
                    'id': doc.id,
                    'nombre': data['nombre'] ?? 'Sin nombre',
                    'precio': (data['precio'] ?? 0.0).toDouble(),
                    'origen': data['origen'] ?? 'Tulcán',
                    'coleccion': 'paradas_salida_tulcan',
                  });
                }
              }
            }

            if (_origenFiltro == 'Todos' || _origenFiltro == 'La Esperanza') {
              if (paradasSnapshot.hasData) {
                for (var doc in paradasSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  todasLasRutas.add({
                    'id': doc.id,
                    'nombre': data['nombre'] ?? 'Sin nombre',
                    'precio': (data['precio'] ?? 0.0).toDouble(),
                    'origen': data['origen'] ?? 'La Esperanza',
                    'coleccion': 'paradas_salida_la_esperanza',
                  });
                }
              }
            }

            final rutasFiltradas = todasLasRutas.where((ruta) {
              final nombre = ruta['nombre'].toString().toLowerCase();
              return nombre.contains(_searchQuery);
            }).toList();

            rutasFiltradas.sort(
              (a, b) =>
                  a['nombre'].toString().compareTo(b['nombre'].toString()),
            );

            if (rutasFiltradas.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: lightBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _searchQuery.isNotEmpty
                            ? Icons.search_off_rounded
                            : Icons.route_outlined,
                        size: 64,
                        color: textGray,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'No se encontraron resultados'
                          : 'No hay rutas registradas',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: darkNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'Intente con otro término de búsqueda'
                          : 'Agregue su primera ruta para comenzar',
                      style: const TextStyle(fontSize: 14, color: textGray),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 32 : 16,
                16,
                isTablet ? 32 : 16,
                padding.bottom + 16,
              ),
              itemCount: rutasFiltradas.length,
              itemBuilder: (context, index) {
                final ruta = rutasFiltradas[index];
                final nombre = ruta['nombre'];
                final precio = ruta['precio'];
                final origen = ruta['origen'];
                final coleccion = ruta['coleccion'];
                final docId = ruta['id'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 800 : double.infinity,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
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
                            gradient: LinearGradient(
                              colors: origen == 'Tulcán'
                                  ? [primaryBusBlue, primaryBusBlue]
                                  : [accentOrange, accentOrange],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              nombre[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      nombre,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: darkNavy,
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (origen == 'Tulcán'
                                              ? primaryBusBlue
                                              : accentOrange)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          origen == 'Tulcán'
                                              ? Icons.location_city_rounded
                                              : Icons.landscape_rounded,
                                          size: 11,
                                          color: origen == 'Tulcán'
                                              ? primaryBusBlue
                                              : accentOrange,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          origen,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: origen == 'Tulcán'
                                                ? primaryBusBlue
                                                : accentOrange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF059669,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.attach_money_rounded,
                                      size: 14,
                                      color: Color(0xFF059669),
                                    ),
                                    Text(
                                      precio.toStringAsFixed(2),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF059669),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: lightBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                color: primaryBusBlue,
                                tooltip: 'Editar',
                                onPressed: () => _editarRuta(
                                  docId,
                                  nombre,
                                  precio,
                                  coleccion,
                                  origen,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 24,
                                color: Colors.grey[300],
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                ),
                                color: const Color(0xFFEF4444),
                                tooltip: 'Eliminar',
                                onPressed: () =>
                                    _eliminarRuta(docId, nombre, coleccion),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
