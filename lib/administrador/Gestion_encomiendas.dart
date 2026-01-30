import 'dart:io';
import 'package:app2tesis/administrador/detalles_encomienda.dart';
import 'package:app2tesis/administrador/ingresar_tipos_encomienda.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ConfiguracionEncomiendas extends StatefulWidget {
  const ConfiguracionEncomiendas({super.key});

  @override
  State<ConfiguracionEncomiendas> createState() =>
      _ConfiguracionEncomiendasState();
}

const String NOTIFICATIONS_SERVER_URL =
    'https://tu-servidor-render.onrender.com';

class _ConfiguracionEncomiendasState extends State<ConfiguracionEncomiendas>
    with SingleTickerProviderStateMixin {
  // Paleta de colores (misma que MenuOpcionesScreen)
  static const Color primaryBusBlue = Color(0xFF1E40AF);
  static const Color accentOrange = Color(0xFFEA580C);
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color roadGray = Color(0xFF334155);
  static const Color lightBg = Color(0xFFF1F5F9);
  static const Color textGray = Color(0xFF475569);
  static const Color successGreen = Color(0xFF059669);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningYellow = Color(0xFFF59E0B);
  static const Color mainRed = Color(0xFF940016);

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _procesarImagenesPendientes();
  }

  Future<void> _procesarImagenesPendientes() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      final prefs = await SharedPreferences.getInstance();
      final pendientes = prefs.getStringList('imagenes_pendientes') ?? [];

      List<String> procesadas = [];

      for (String imagenData in pendientes) {
        try {
          final data = json.decode(imagenData);
          final file = File(data['ruta_local']);

          if (await file.exists()) {
            final ref =
                FirebaseStorage.instance.ref().child(data['ruta_storage']);
            await ref.putFile(file);
            final url = await ref.getDownloadURL();

            await FirebaseFirestore.instance
                .collection('encomiendas_registradas')
                .doc(data['codigo_envio'])
                .update({data['campo']: url});

            print('✅ Imagen subida: ${data['campo']}');

            if (data['campo'] == 'imagenes.entregada' &&
                data['uid_remitente'] != null) {
              final encomiendaDoc = await FirebaseFirestore.instance
                  .collection('encomiendas_registradas')
                  .doc(data['codigo_envio'])
                  .get();

              final encomiendaData = encomiendaDoc.data();
              final correo = encomiendaData?['remitente']?['correo'] ?? '';
              final nombre = encomiendaData?['remitente']?['nombre'] ?? '';

              await FirebaseFirestore.instance
                  .collection('notificaciones')
                  .add({
                'uid': data['uid_remitente'],
                'correo': correo,
                'nombre_remitente': nombre,
                'titulo': 'Encomienda Entregada ✅',
                'mensaje':
                    'Tu encomienda ${data['codigo_envio']} ha sido entregada exitosamente.',
                'codigo_encomienda': data['codigo_envio'],
                'estado': 'entregado',
                'leida': false,
                'fecha': FieldValue.serverTimestamp(),
                'tipo': 'encomienda',
                'accion': 'entregado',
              });
              print('✅ Notificación creada tras sincronización offline');
            }

            procesadas.add(imagenData);
            await file.delete();
          }
        } catch (e) {
          print('❌ Error procesando imagen pendiente: $e');
        }
      }

      if (procesadas.isNotEmpty) {
        pendientes.removeWhere((item) => procesadas.contains(item));
        await prefs.setStringList('imagenes_pendientes', pendientes);
        print('✅ ${procesadas.length} imagen(es) sincronizada(s)');
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 248, 255),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildHeader(),
          _buildTabBar(),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: const [
                EncomiendaPorEstadoTab(estado: 'pendiente'),
                EncomiendaPorEstadoTab(estado: 'en_transito'),
                EncomiendaPorEstadoTab(estado: 'entregado'),
                TiposEncomiendaTab(),
              ],
            ),
          ),
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                              color: mainRed,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GESTIÓN DE ENCOMIENDAS',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color.fromARGB(255, 26, 25, 25),
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              'Control y seguimiento',
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
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {},
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
                          Icons.local_shipping_rounded,
                          color: mainRed,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  'Gestión de Encomiendas',
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
                  'Administra y controla todas las encomiendas del sistema',
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
                    _buildStatChip(Icons.inventory_2, 'Organizado'),
                    const SizedBox(width: 10),
                    _buildStatChip(Icons.verified_rounded, 'Seguro'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 66, 58, 58).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 46, 44, 44),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        child: Column(
          children: [
            Container(
              height: 60,
              padding: const EdgeInsets.all(6),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: textGray,
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [mainRed, mainRed.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: mainRed.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  letterSpacing: 0.2,
                ),
                tabs: [
                  _buildTab(Icons.schedule_rounded, 'Pendientes'),
                  _buildTab(Icons.local_shipping_rounded, 'Tránsito'),
                  _buildTab(Icons.check_circle_rounded, 'Entregadas'),
                  _buildTab(Icons.settings_rounded, 'Tipos'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(IconData icon, String text) {
    return Tab(
      height: 48,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 3),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(height: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// TAB: ENCOMIENDAS POR ESTADO (REDISEÑADO)
// ============================================
class EncomiendaPorEstadoTab extends StatefulWidget {
  final String estado;

  const EncomiendaPorEstadoTab({super.key, required this.estado});

  @override
  State<EncomiendaPorEstadoTab> createState() => _EncomiendaPorEstadoTabState();
}

class _EncomiendaPorEstadoTabState extends State<EncomiendaPorEstadoTab> {
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color lightBg = Color(0xFFF1F5F9);
  static const Color textGray = Color(0xFF475569);
  static const Color primaryBusBlue = Color(0xFF1E40AF);
  static const Color successGreen = Color(0xFF059669);
  static const Color warningYellow = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color mainRed = Color(0xFF940016);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 243, 248, 255),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('encomiendas_registradas')
            .where('estado', isEqualTo: widget.estado)
            .orderBy('fecha_creacion', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: errorRed),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: mainRed),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando encomiendas...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textGray,
                    ),
                  ),
                ],
              ),
            );
          }

          final encomiendas = snapshot.data!.docs;

          if (encomiendas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _getColorEstado().withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconoEstado(),
                      size: 64,
                      color: _getColorEstado(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay encomiendas ${_getTextoEstado()}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Las encomiendas aparecerán aquí',
                    style: TextStyle(fontSize: 13, color: textGray),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildActionButtons(encomiendas)),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = encomiendas[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildEncomiendaCard(doc.id, data),
                      );
                    },
                    childCount: encomiendas.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(List<QueryDocumentSnapshot> encomiendas) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getColorEstado().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(_getIconoEstado(), color: _getColorEstado(), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${encomiendas.length} encomienda(s) ${_getTextoEstado()}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: darkNavy,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _generarReporte(encomiendas),
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBusBlue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          if (encomiendas.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _eliminarTodasEncomiendas(encomiendas),
                icon: const Icon(Icons.delete_sweep, size: 20),
                label: Text('Eliminar todas las ${_getTextoEstado()}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: errorRed,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEncomiendaCard(String codigo, Map<String, dynamic> data) {
    final remitente = data['remitente'] ?? {};
    final destinatario = data['destinatario'] ?? {};
    final costos = data['costos'] ?? {};
    final envio = data['envio'] ?? {};

    return InkWell(
      onTap: () => _abrirDetalleEncomienda(codigo, data),
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
                      color: _getColorEstado().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconoEstado(),
                      color: _getColorEstado(),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          codigo,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: darkNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          remitente['nombre'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getColorEstado(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _eliminarEncomienda(codigo),
                    icon: const Icon(Icons.delete_outline),
                    color: errorRed,
                    tooltip: 'Eliminar',
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
                      color: textGray,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                destinatario['nombre'] ?? 'N/A',
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
                          Icons.info_outline,
                          size: 16,
                          color: _getColorEstado(),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Detalles:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: darkNavy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(
                        Icons.location_on, destinatario['ciudad'] ?? 'N/A'),
                    _buildInfoItem(
                        Icons.inventory_2, envio['tipo_encomienda'] ?? 'N/A'),
                    _buildInfoItem(
                        Icons.monitor_weight, envio['rango_peso'] ?? 'N/A'),
                    if (data['numero'] != null)
                      _buildInfoItem(
                          Icons.directions_bus, 'Bus ${data['numero']}',
                          isLast: true),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: darkNavy,
                      ),
                    ),
                    Text(
                      '\$${(costos['total'] ?? 0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: successGreen,
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

  Widget _buildInfoItem(IconData icon, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: _getColorEstado(),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 14, color: textGray),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: textGray,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _abrirDetalleEncomienda(String codigo, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleEncomiendaScreen(
          codigo: codigo,
          data: data,
          estado: widget.estado,
        ),
      ),
    );
  }

  Future<void> _eliminarEncomienda(String codigo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: errorRed, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '¿Eliminar encomienda?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estás a punto de eliminar la encomienda:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lightBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                codigo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: darkNavy,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Esta acción no se puede deshacer.',
              style: TextStyle(
                fontSize: 13,
                color: errorRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await FirebaseFirestore.instance
            .collection('encomiendas_registradas')
            .doc(codigo)
            .delete();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Encomienda eliminada exitosamente'),
            backgroundColor: successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: errorRed,
          ),
        );
      }
    }
  }

  Future<void> _eliminarTodasEncomiendas(
      List<QueryDocumentSnapshot> encomiendas) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Eliminar todo?'),
        content: Text(
            '¿Estás seguro de eliminar ${encomiendas.length} encomienda(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            child: const Text('Eliminar Todo'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in encomiendas) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Encomiendas eliminadas'),
              backgroundColor: successGreen),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: errorRed),
        );
      }
    }
  }

  Future<void> _generarReporte(List<QueryDocumentSnapshot> encomiendas) async {
    final pdf = pw.Document();

    // Agrupar encomiendas por bus
    Map<String, List<Map<String, dynamic>>> encomiendaPorBus = {};

    for (var doc in encomiendas) {
      final data = doc.data() as Map<String, dynamic>;
      final codigo = doc.id;
      final numeroBus = data['numero'];

      if (numeroBus == null || numeroBus.toString().trim().isEmpty) {
        continue;
      }

      final busKey = numeroBus.toString().trim();
      encomiendaPorBus.putIfAbsent(busKey, () => []);

      encomiendaPorBus[busKey]!.add({
        'codigo': codigo,
        'data': data,
      });
    }

    // Generar PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          List<pw.Widget> widgets = [];

          // Encabezado del reporte
          widgets.add(
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'TRANS DORAMALD',
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Reporte de Encomiendas',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Estado: ${_getTextoEstado().toUpperCase()}',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),
          );

          widgets.add(pw.SizedBox(height: 20));

          // Generar secciones por BUS
          for (var entry in encomiendaPorBus.entries) {
            // Encabezado del bus
            widgets.add(
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'BUS ${entry.key}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Spacer(),
                    pw.Text(
                      '${entry.value.length} encomienda(s)',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
            );

            widgets.add(pw.SizedBox(height: 15));

            // Tabla de encomiendas para este bus
            widgets.add(
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                  width: 1,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.5),
                  1: const pw.FlexColumnWidth(2.5),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                  4: const pw.FlexColumnWidth(2.5),
                },
                children: [
                  // Encabezados
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _cellHeader('Código'),
                      _cellHeader('Destinatario'),
                      _cellHeader('Destino'),
                      _cellHeader('Cedula'),
                      _cellHeader('Firma'),
                    ],
                  ),
                  // Filas de datos
                  ...entry.value.map((item) {
                    final data = item['data'] as Map<String, dynamic>;
                    final destinatario = data['destinatario'] ?? {};

                    return pw.TableRow(
                      children: [
                        _cellData(item['codigo'], isBold: true),
                        _cellData(destinatario['nombre'] ?? 'N/A'),
                        _cellData(destinatario['ciudad'] ?? 'N/A'),
                        _cellData(destinatario['cedula'] ?? 'N/A'),
                        _cellFirma(),
                      ],
                    );
                  }).toList(),
                ],
              ),
            );

            widgets.add(pw.SizedBox(height: 30));
          }

          // Resumen final
          widgets.add(pw.Divider(thickness: 2));
          widgets.add(pw.SizedBox(height: 10));
          widgets.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total de encomiendas: ${encomiendas.length}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Buses: ${encomiendaPorBus.keys.length}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          );

          return widgets;
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  // Helper para encabezados de tabla
  pw.Widget _cellHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 11,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // Helper para datos de tabla
  pw.Widget _cellData(String text, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // Helper para celda de firma
  pw.Widget _cellFirma() {
    return pw.Container(
      height: 40,
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(
            height: 1,
            color: PdfColors.grey600,
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Firma',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconoEstado() {
    switch (widget.estado) {
      case 'pendiente':
        return Icons.schedule;
      case 'en_transito':
        return Icons.local_shipping;
      case 'entregado':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  String _getTextoEstado() {
    switch (widget.estado) {
      case 'pendiente':
        return 'pendientes';
      case 'en_transito':
        return 'en tránsito';
      case 'entregado':
        return 'entregadas';
      default:
        return widget.estado;
    }
  }

  Color _getColorEstado() {
    switch (widget.estado) {
      case 'pendiente':
        return warningYellow;
      case 'en_transito':
        return primaryBusBlue;
      case 'entregado':
        return successGreen;
      default:
        return textGray;
    }
  }
}
