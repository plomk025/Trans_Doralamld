import 'package:app2tesis/usuario/compra_de_boletos/De_regreso/seleccion_de_asientos_desde_laesperanza.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParadasScreen2 extends StatefulWidget {
  final String busId;
  const ParadasScreen2({Key? key, required this.busId}) : super(key: key);

  @override
  _ParadasScreen2State createState() => _ParadasScreen2State();
}

class _ParadasScreen2State extends State<ParadasScreen2>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String _searchQuery = '';

  // Paleta de colores inspirada en transporte de buses
  final Color primaryBusBlue = const Color.fromARGB(255, 243, 248, 255);
  final Color accentOrange = const Color(0xFFEA580C);
  final Color darkNavy = const Color(0xFF0F172A);
  final Color roadGray = const Color(0xFF334155);
  final Color lightBg = const Color(0xFFF1F5F9);
  final Color textGray = const Color(0xFF475569);
  final Color successGreen = const Color(0xFF059669);
  final Color accentBlue = const Color(0xFF1E40AF);

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
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: primaryBusBlue,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildHeader(),
          _buildSearchBar(),
          _buildParadasList(db),
        ],
      ),
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
                                    color:
                                        const Color.fromARGB(0, 240, 240, 240)
                                            .withOpacity(0.1),
                                    blurRadius: 10,
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
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SELECCIÓN DE PARADA',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color.fromARGB(255, 36, 35, 35),
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                'Elige tu parada',
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
                            color: const Color.fromARGB(0, 240, 240, 240),
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
                            Icons.location_on_rounded,
                            color: Color(0xFF940016),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Selecciona tu Parada',
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
                      'Elige el punto de destino más conveniente para ti',
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

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar parada por nombre...',
                hintStyle: TextStyle(
                  color: textGray,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: roadGray,
                  size: 22,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: roadGray,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParadasList(FirebaseFirestore db) {
    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('paradas_salida_la_esperanza').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF940016),
                      ),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Cargando paradas disponibles...',
                    style: TextStyle(
                      color: textGray,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.location_off_outlined,
            title: 'No hay paradas disponibles',
            subtitle: 'Intenta de nuevo más tarde',
          );
        }

        var paradas = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          var nombre = (data['nombre'] ?? '').toString().toLowerCase();
          return nombre.contains(_searchQuery);
        }).toList();

        if (paradas.isEmpty && _searchQuery.isNotEmpty) {
          return _buildEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No se encontraron resultados',
            subtitle: 'Intenta con otro término de búsqueda',
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildParadaCard(paradas[index], index),
                );
              },
              childCount: paradas.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return SliverFillRemaining(
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: lightBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  icon,
                  size: 60,
                  color: textGray,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: darkNavy,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: textGray,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParadaCard(DocumentSnapshot parada, int index) {
    var data = parada.data() as Map<String, dynamic>;
    var nombre = data['nombre'] ?? 'Sin nombre';
    var precio = data['precio']?.toString() ?? '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AsientosScreen2(
                  busId: widget.busId,
                  paradaNombre: nombre,
                  paradaPrecio: double.parse(precio),
                  userId: '',
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icono de la parada
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: accentBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: accentBlue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Información de la parada
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
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
                            'Parada disponible',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: successGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Flecha
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
                const SizedBox(height: 12),
                // Precio y estado
                Row(
                  children: [
                    // Precio
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.attach_money_rounded,
                              color: Color(0xFF059669),
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              precio,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF059669),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'USD',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: successGreen.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Estado
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: lightBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF059669),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Activa',
                            style: TextStyle(
                              fontSize: 13,
                              color: textGray,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
