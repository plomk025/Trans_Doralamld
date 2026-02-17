import 'package:app2tesis/usuario/compra_de_boletos/De_regreso/seleccion_de_asientos_desde_laesperanza.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParadasScreen2 extends StatefulWidget {
  final String busId;
  final String chofer; // 🆕 AGREGADO
  const ParadasScreen2({Key? key, required this.busId, required this.chofer})
      : super(key: key);

  @override
  _ParadasScreen2State createState() => _ParadasScreen2State();
}

class _ParadasScreen2State extends State<ParadasScreen2>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String _searchQuery = '';

  // Variables para el lugar de salida seleccionado
  String? _lugarSalidaSeleccionado;
  String? _nombreLugarSalida;

  // Paleta de colores
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

  Future<void> _mostrarSelectorLugarSalida() async {
    final db = FirebaseFirestore.instance;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Color(0xFF940016).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.trip_origin_rounded,
                            color: Color(0xFF940016),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lugar de Salida',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Selecciona desde dónde saldrás',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream:
                          db.collection('paradas_salida_tulcan').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(accentBlue),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text('No hay lugares de salida disponibles'),
                          );
                        }

                        var lugaresSalida = snapshot.data!.docs;

                        return ListView.builder(
                          controller: controller,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: lugaresSalida.length,
                          itemBuilder: (context, index) {
                            var lugar = lugaresSalida[index];
                            var data = lugar.data() as Map<String, dynamic>;
                            var nombreLugar = data['nombre'] ?? 'Sin nombre';
                            var lugarId = lugar.id;

                            bool isSelected =
                                _lugarSalidaSeleccionado == lugarId;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Color(0xFF940016).withOpacity(0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Color(0xFF940016)
                                      : Colors.grey.shade200,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Color(0xFF940016)
                                        : Color(0xFF940016).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.location_city_rounded,
                                    color: isSelected
                                        ? Colors.white
                                        : Color(0xFF940016),
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  nombreLugar,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Color(0xFF940016)
                                        : darkNavy,
                                  ),
                                ),
                                subtitle: Text(
                                  'Punto de partida',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textGray,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: isSelected
                                    ? Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFF940016),
                                        size: 28,
                                      )
                                    : Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: roadGray,
                                      ),
                                onTap: () {
                                  setState(() {
                                    _lugarSalidaSeleccionado = lugarId;
                                    _nombreLugarSalida = nombreLugar;
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
          _buildLugarSalidaSelector(),
          if (_lugarSalidaSeleccionado != null) _buildSearchBar(),
          if (_lugarSalidaSeleccionado != null) _buildParadasList(db),
          if (_lugarSalidaSeleccionado == null) _buildSelectorPrompt(),
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
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
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
                                'SELECCIÓN DE PARADAs',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color.fromARGB(255, 36, 35, 35),
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                'Origen y destino',
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
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Selecciona tu parada de salida',
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
                      'Selecciona tu punto de salida y destino',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(255, 71, 74, 76),
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
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

  Widget _buildLugarSalidaSelector() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: InkWell(
            onTap: _mostrarSelectorLugarSalida,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _lugarSalidaSeleccionado != null
                      ? Color(0xFF940016)
                      : Colors.grey.shade200,
                  width: _lugarSalidaSeleccionado != null ? 2 : 1,
                ),
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _lugarSalidaSeleccionado != null
                          ? Color(0xFF940016).withOpacity(0.1)
                          : lightBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.trip_origin_rounded,
                      color: _lugarSalidaSeleccionado != null
                          ? Color(0xFF940016)
                          : roadGray,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lugar de Salida',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textGray,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _nombreLugarSalida ?? 'Seleccionar lugar de salida',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _lugarSalidaSeleccionado != null
                                ? darkNavy
                                : textGray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _lugarSalidaSeleccionado != null
                        ? Icons.check_circle_rounded
                        : Icons.arrow_forward_ios,
                    color: _lugarSalidaSeleccionado != null
                        ? successGreen
                        : roadGray,
                    size: _lugarSalidaSeleccionado != null ? 28 : 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorPrompt() {
    return SliverFillRemaining(
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(40),
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
                    Icons.location_searching_rounded,
                    size: 64,
                    color: Color(0xFF940016),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Selecciona tu lugar de salida',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: darkNavy,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Para continuar, primero debes elegir desde dónde comenzará tu viaje',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: textGray,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _mostrarSelectorLugarSalida,
                  icon: const Icon(Icons.add_location_rounded),
                  label: const Text('Elegir lugar de salida'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF940016),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
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
                hintText: 'Buscar destino...',
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
              child: CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF940016),
                ),
                strokeWidth: 3,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.location_off_outlined,
            title: 'No hay destinos disponibles',
            subtitle: 'Intenta de nuevo más tarde',
          );
        }

        var paradasFiltradas = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          var salidaId = data['salida'] ?? '';
          var nombre = (data['nombre'] ?? '').toString().toLowerCase();

          // Compara el campo 'salida' con el NOMBRE del lugar de salida seleccionado
          return salidaId == _nombreLugarSalida &&
              nombre.contains(_searchQuery);
        }).toList();

        if (paradasFiltradas.isEmpty) {
          return _buildEmptyState(
            icon: Icons.route_outlined,
            title: 'No hay rutas disponibles',
            subtitle: _searchQuery.isEmpty
                ? 'No existen destinos desde este lugar de salida'
                : 'No se encontraron resultados',
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildParadaCard(paradasFiltradas[index]),
                );
              },
              childCount: paradasFiltradas.length,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: lightBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 60, color: textGray),
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
                style: TextStyle(fontSize: 14, color: textGray),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParadaCard(DocumentSnapshot parada) {
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
                  chofer: widget.chofer,
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
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Color(0xFF940016).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF940016),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
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
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: textGray,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Destino disponible',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textGray,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '\$$precio',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: successGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: lightBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Color(0xFF940016),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Toca para seleccionar asientos',
                          style: TextStyle(
                            fontSize: 12,
                            color: textGray,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: Color(0xFF940016),
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
}
