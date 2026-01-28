import 'package:app2tesis/usuario/Pantallas_inicio/iniciarsesion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GestionDatosScreen extends StatefulWidget {
  @override
  _GestionDatosScreenState createState() => _GestionDatosScreenState();
}

class _GestionDatosScreenState extends State<GestionDatosScreen> {
  final db = FirebaseFirestore.instance;

  // Controladores
  final _numeroCtrl = TextEditingController();
  final _placaCtrl = TextEditingController();
  final _capacidadCtrl = TextEditingController();
  final _choferCtrl = TextEditingController();
  final _lugarCtrl = TextEditingController();

  // FocusNodes
  final _numeroFocus = FocusNode();
  final _placaFocus = FocusNode();
  final _capacidadFocus = FocusNode();
  final _choferFocus = FocusNode();
  final _lugarFocus = FocusNode();

  // Paleta de colores moderna
  static const Color primaryBusBlue = Color(0xFF940016);
  static const Color accentOrange = Color(0xFFEA580C);
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color roadGray = Color(0xFF334155);
  static const Color lightBg = Color(0xFFF1F5F9);
  static const Color textGray = Color(0xFF475569);
  static const Color successGreen = Color(0xFF940016);
  static const Color accentRed = Color(0xFFEF4444);

  int _currentTab = 0;

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _placaCtrl.dispose();
    _capacidadCtrl.dispose();
    _choferCtrl.dispose();
    _lugarCtrl.dispose();
    _numeroFocus.dispose();
    _placaFocus.dispose();
    _capacidadFocus.dispose();
    _choferFocus.dispose();
    _lugarFocus.dispose();
    super.dispose();
  }

  bool _validarPlaca(String placa) {
    RegExp regExp = RegExp(r'^[A-Z]{3,4}-[0-9]{3,4}$');
    return regExp.hasMatch(placa.toUpperCase());
  }

  String _formatearPlaca(String valor) {
    String limpio = valor.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9-]'), '');

    if (!limpio.contains('-') && limpio.length > 3) {
      String letras = limpio.replaceAll(RegExp(r'[0-9]'), '');
      String numeros = limpio.replaceAll(RegExp(r'[A-Z]'), '');

      if (letras.length >= 3 && letras.length <= 4 && numeros.isNotEmpty) {
        limpio = '$letras-$numeros';
      }
    }

    return limpio;
  }

  Future<void> _agregarBusCompleto() async {
    if (_numeroCtrl.text.trim().isEmpty) {
      _mostrarSnackBar('Ingresa el número de bus', accentOrange);
      return;
    }

    if (_placaCtrl.text.trim().isEmpty) {
      _mostrarSnackBar('Ingresa la placa', accentOrange);
      return;
    }

    if (_capacidadCtrl.text.trim().isEmpty) {
      _mostrarSnackBar('Ingresa la capacidad', accentOrange);
      return;
    }

    if (_choferCtrl.text.trim().isEmpty) {
      _mostrarSnackBar('Ingresa el nombre del chofer', accentOrange);
      return;
    }

    String placaFormateada = _formatearPlaca(_placaCtrl.text);
    if (!_validarPlaca(placaFormateada)) {
      _mostrarSnackBar(
        'Formato de placa inválido. Usa: ABC-123 o ABCD-1234',
        accentRed,
      );
      return;
    }

    try {
      final existente = await db
          .collection('conductores_registrados')
          .where('numero', isEqualTo: _numeroCtrl.text.trim())
          .get();

      if (existente.docs.isNotEmpty) {
        _mostrarSnackBar(
          'El número de bus ${_numeroCtrl.text} ya existe',
          accentRed,
        );
        return;
      }

      await db.collection('conductores_registrados').add({
        'numero': _numeroCtrl.text.trim(),
        'placa': placaFormateada,
        'capacidad': _capacidadCtrl.text.trim(),
        'chofer': _choferCtrl.text.trim(),
        'fecha_creacion': Timestamp.now(),
      });

      _mostrarSnackBar('✓ Bus agregado correctamente', successGreen);

      _numeroCtrl.clear();
      _placaCtrl.clear();
      _capacidadCtrl.clear();
      _choferCtrl.clear();

      FocusScope.of(context).requestFocus(_numeroFocus);
    } catch (e) {
      _mostrarSnackBar('Error al agregar: $e', accentRed);
    }
  }

  Future<void> _agregarLugar() async {
    if (_lugarCtrl.text.trim().isEmpty) {
      _mostrarSnackBar('Ingresa el nombre del lugar', accentOrange);
      return;
    }

    try {
      final existente = await db
          .collection('lugares_salida')
          .where('lugar', isEqualTo: _lugarCtrl.text.trim())
          .get();

      if (existente.docs.isNotEmpty) {
        _mostrarSnackBar(
          'El lugar "${_lugarCtrl.text.trim()}" ya existe',
          accentRed,
        );
        return;
      }

      await db.collection('lugares_salida').add({
        'lugar': _lugarCtrl.text.trim(),
        'fecha_creacion': Timestamp.now(),
      });

      _mostrarSnackBar('✓ Lugar agregado correctamente', successGreen);

      _lugarCtrl.clear();
      FocusScope.of(context).requestFocus(_lugarFocus);
    } catch (e) {
      _mostrarSnackBar('Error al agregar: $e', accentRed);
    }
  }

  Future<void> _eliminarBus(String id, String numero) async {
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(Icons.warning_amber_rounded, color: accentRed, size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '¿Eliminar Bus?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: darkNavy,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '¿Deseas eliminar el Bus #$numero y todos sus datos?',
          style: TextStyle(
            fontSize: 14,
            color: textGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: textGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Eliminar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await db.collection('conductores_registrados').doc(id).delete();
        _mostrarSnackBar('✓ Bus eliminado correctamente', accentOrange);
      } catch (e) {
        _mostrarSnackBar('Error al eliminar: $e', accentRed);
      }
    }
  }

  Future<void> _eliminarLugar(String id, String lugar) async {
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(Icons.warning_amber_rounded, color: accentRed, size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '¿Eliminar Lugar?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: darkNavy,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '¿Deseas eliminar el lugar "$lugar"?',
          style: TextStyle(
            fontSize: 14,
            color: textGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: textGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Eliminar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await db.collection('lugares_salida').doc(id).delete();
        _mostrarSnackBar('✓ Lugar eliminado correctamente', accentOrange);
      } catch (e) {
        _mostrarSnackBar('Error al eliminar: $e', accentRed);
      }
    }
  }

  void _mostrarSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == successGreen
                  ? Icons.check_circle_outline
                  : color == accentOrange
                      ? Icons.info_outline
                      : Icons.error_outline,
              color: Colors.white,
            ),
            SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 243, 248, 255),
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(context),
            ),
            SliverToBoxAdapter(
              child: _buildTabs(),
            ),
            SliverFillRemaining(
              child: _currentTab == 0 ? _buildBusesTab() : _buildLugaresTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                        'GESTIÓN DE DATOS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: darkNavy,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'Buses y Lugares de Salida',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: textGray,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Administrar Sistema',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: darkNavy,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gestiona buses, choferes y lugares de salida',
                style: TextStyle(
                  fontSize: 14,
                  color: textGray,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildStatChip(Icons.verified_rounded, 'Seguro'),
                  const SizedBox(width: 10),
                  _buildStatChip(Icons.settings_rounded, 'Control'),
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
        color: primaryBusBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryBusBlue.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primaryBusBlue, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryBusBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              index: 0,
              icon: Icons.directions_bus_rounded,
              label: 'Buses',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade200,
          ),
          Expanded(
            child: _buildTab(
              index: 1,
              icon: Icons.location_on,
              label: 'Lugares',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required int index,
    required IconData icon,
    required String label,
  }) {
    bool isSelected = _currentTab == index;
    return InkWell(
      onTap: () => setState(() => _currentTab = index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [primaryBusBlue, primaryBusBlue.withOpacity(0.85)],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : textGray,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : textGray,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('conductores_registrados')
          .orderBy('fecha_creacion', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryBusBlue),
              strokeWidth: 3,
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState();
        }

        var docs = snapshot.data?.docs ?? [];

        return SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              _buildBusForm(),
              SizedBox(height: 20),
              if (docs.isEmpty)
                _buildEmptyState(
                  Icons.directions_bus_outlined,
                  'No hay buses registrados',
                  'Agrega tu primer bus arriba',
                )
              else
                _buildBusList(docs),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBusForm() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBusBlue, primaryBusBlue.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.directions_bus_rounded,
                    color: Colors.white, size: 24),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Agregar Nuevo Bus',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: darkNavy,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildModernTextField(
            controller: _numeroCtrl,
            focusNode: _numeroFocus,
            label: 'Número de Bus',
            hint: 'Ej: 101, 102, 103',
            icon: Icons.numbers,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          SizedBox(height: 16),
          _buildModernTextField(
            controller: _placaCtrl,
            focusNode: _placaFocus,
            label: 'Placa',
            hint: 'Ej: ABC-1234',
            icon: Icons.credit_card,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
              LengthLimitingTextInputFormatter(9),
              _PlacaInputFormatter(),
            ],
          ),
          SizedBox(height: 16),
          _buildModernTextField(
            controller: _capacidadCtrl,
            focusNode: _capacidadFocus,
            label: 'Capacidad',
            hint: 'Ej: 40, 45, 50',
            icon: Icons.event_seat,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          SizedBox(height: 16),
          _buildModernTextField(
            controller: _choferCtrl,
            focusNode: _choferFocus,
            label: 'Nombre del Chofer',
            hint: 'Ej: Juan Pérez',
            icon: Icons.person,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
            ],
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _agregarBusCompleto,
              style: ElevatedButton.styleFrom(
                backgroundColor: successGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Agregar Bus',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization? textCapitalization,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization ?? TextCapitalization.none,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: textGray,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: TextStyle(color: textGray.withOpacity(0.5)),
          prefixIcon: Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryBusBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryBusBlue, size: 20),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryBusBlue, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildBusList(List<QueryDocumentSnapshot> docs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Buses Registrados',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: darkNavy,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryBusBlue, primaryBusBlue.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryBusBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${docs.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var doc = docs[index];
            var data = doc.data() as Map<String, dynamic>;
            String id = doc.id;

            return Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(18),
                leading: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryBusBlue, primaryBusBlue.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.directions_bus_rounded,
                      color: Colors.white, size: 24),
                ),
                title: Text(
                  'Bus #${data['numero']}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: darkNavy,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    _buildInfoChip(Icons.credit_card, data['placa']),
                    SizedBox(height: 6),
                    _buildInfoChip(
                        Icons.event_seat, '${data['capacidad']} asientos'),
                    SizedBox(height: 6),
                    _buildInfoChip(Icons.person, data['chofer']),
                  ],
                ),
                trailing: InkWell(
                  onTap: () => _eliminarBus(id, data['numero'].toString()),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.delete_outline_rounded,
                        color: accentRed, size: 20),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: textGray),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: textGray,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLugaresTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          _buildLugarForm(),
          SizedBox(height: 20),
          _buildLugaresList(),
        ],
      ),
    );
  }

  Widget _buildLugarForm() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentOrange, accentOrange.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.location_on, color: Colors.white, size: 24),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Agregar Lugar de Salida',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: darkNavy,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildModernTextField(
            controller: _lugarCtrl,
            focusNode: _lugarFocus,
            label: 'Nombre del Lugar',
            hint: 'Ej: Chical',
            icon: Icons.place,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ0-9\s-]')),
            ],
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _agregarLugar,
              style: ElevatedButton.styleFrom(
                backgroundColor: successGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_location_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Agregar Lugar',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLugaresList() {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('lugares_salida')
          .orderBy('fecha_creacion', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryBusBlue),
              strokeWidth: 3,
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState();
        }

        var docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState(
            Icons.location_on_outlined,
            'No hay lugares registrados',
            'Agrega tu primer lugar arriba',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lugares Registrados',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: darkNavy,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentOrange, accentOrange.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: accentOrange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${docs.length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                var doc = docs[index];
                var data = doc.data() as Map<String, dynamic>;
                String id = doc.id;

                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(18),
                    leading: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentOrange, accentOrange.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.location_on,
                          color: Colors.white, size: 24),
                    ),
                    title: Text(
                      data['lugar'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: darkNavy,
                      ),
                    ),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: textGray),
                          SizedBox(width: 6),
                          Text(
                            _formatearFecha(data['fecha_creacion']),
                            style: TextStyle(fontSize: 13, color: textGray),
                          ),
                        ],
                      ),
                    ),
                    trailing: InkWell(
                      onTap: () => _eliminarLugar(id, data['lugar'] ?? ''),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accentRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.delete_outline_rounded,
                            color: accentRed, size: 20),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Container(
      padding: EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: lightBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: textGray),
            ),
            SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: darkNavy,
              ),
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: textGray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: accentRed),
          SizedBox(height: 16),
          Text(
            'Error al cargar datos',
            style: TextStyle(fontSize: 16, color: darkNavy),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(dynamic timestamp) {
    if (timestamp == null) return 'Sin fecha';
    try {
      DateTime fecha = (timestamp as Timestamp).toDate();
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    } catch (e) {
      return 'Sin fecha';
    }
  }
}

class _PlacaInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.toUpperCase();

    if (text.length < oldValue.text.length) {
      return newValue.copyWith(text: text);
    }

    text = text.replaceAll(RegExp(r'[^A-Z0-9-]'), '');

    if (text.indexOf('-') != text.lastIndexOf('-')) {
      int firstDash = text.indexOf('-');
      text = text.substring(0, firstDash + 1) +
          text.substring(firstDash + 1).replaceAll('-', '');
    }

    if (!text.contains('-') && text.length >= 3) {
      String letras = text.replaceAll(RegExp(r'[0-9]'), '');
      String numeros = text.replaceAll(RegExp(r'[A-Z]'), '');

      if (letras.length >= 3 && numeros.isNotEmpty) {
        text = '$letras-$numeros';
      }
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
