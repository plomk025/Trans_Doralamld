import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;

// ==================== PANTALLA PRINCIPAL ====================
class NotificacionesScreen extends StatefulWidget {
  final String userEmail;

  const NotificacionesScreen({
    Key? key,
    required this.userEmail,
  }) : super(key: key);

  @override
  _NotificacionesScreenState createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // ── Colores modernos ──
  static const Color bgPrimary = Color(0xFFF8F9FA);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color dividerColor = Color(0xFFE5E7EB);
  static const Color unreadBg = Color(0xFFF0F9FF);

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Utilidades ──
  String _sanitizeEmail(String email) =>
      email.replaceAll('.', '_').replaceAll('@', '_at_');

  bool _esMensaje3Leido(Map<String, dynamic> data) {
    if (data['leida3'] == null) return false;
    if (data['leida3'] is Map)
      return (data['leida3'] as Map)[_sanitizeEmail(widget.userEmail)] == true;
    if (data['leida3'] is bool) return data['leida3'] as bool;
    return false;
  }

  bool _estaOcultadaParaUsuario(Map<String, dynamic> data) {
    if (data['ocultadoPara'] == null) return false;
    if (data['ocultadoPara'] is Map)
      return (data['ocultadoPara'] as Map)[_sanitizeEmail(widget.userEmail)] ==
          true;
    return false;
  }

  Future<void> _marcarComoLeida(String docId, int tipoMensaje) async {
    try {
      Map<String, dynamic> updateData = {};
      switch (tipoMensaje) {
        case 1:
          updateData = {'leida': true};
          break;
        case 2:
          updateData = {'leida2': true};
          break;
        case 3:
          updateData = {'leida3.${_sanitizeEmail(widget.userEmail)}': true};
          break;
        case 4:
          updateData = {'leida': true};
          break;
      }
      await db.collection('notificaciones').doc(docId).update(updateData);
    } catch (e) {
      print('Error marcar leída: $e');
    }
  }

  Future<void> _eliminarNotificacion(String docId, bool esGlobal) async {
    try {
      if (esGlobal) {
        await db.collection('notificaciones').doc(docId).update({
          'ocultadoPara.${_sanitizeEmail(widget.userEmail)}': true,
        });
      } else {
        await db.collection('notificaciones').doc(docId).delete();
      }
      _mostrarSnackBar(
          esGlobal ? 'Notificación ocultada' : 'Notificación eliminada');
    } catch (e) {
      print('Error eliminar: $e');
      _mostrarSnackBar('Error al procesar');
    }
  }

  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Copiar al portapapeles ──
  Future<void> _copiarAlPortapapeles(String texto) async {
    await Clipboard.setData(ClipboardData(text: texto));
    _mostrarSnackBar('Código copiado: $texto');
  }

  // ── Expandir docs en items individuales ──
  List<Map<String, dynamic>> _expandirNotificaciones(
      List<QueryDocumentSnapshot> docs) {
    List<Map<String, dynamic>> items = [];
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final docId = doc.id;
      bool esGlobal =
          data['mensaje3'] != null && data['mensaje3'].toString().isNotEmpty;
      if (esGlobal && _estaOcultadaParaUsuario(data)) continue;
      bool esEncomienda = data['tipo'] == 'encomienda';

      if (esEncomienda) {
        if (data['correo'] == widget.userEmail) {
          items.add({
            'docId': docId,
            'mensaje': data['titulo'] ?? 'Encomienda Actualizada',
            'descripcion': data['mensaje2'] ?? data['mensaje'] ?? '',
            'asiento': data['codigo_encomienda'] ?? 'N/A',
            'fecha': data['fecha'],
            'leida': data['leida'] ?? false,
            'tipoMensaje': 4,
            'esGlobal': false,
            'esEncomienda': true,
            'estado': data['estado'] ?? '',
            'nombreRemitente': data['nombre_remitente'] ?? '',
          });
        }
      } else {
        if (data['mensaje'] != null && data['mensaje'].toString().isNotEmpty) {
          items.add({
            'docId': docId,
            'mensaje': data['mensaje'],
            'asiento': data['asiento'],
            'fecha': data['fecha'],
            'leida': data['leida'] ?? false,
            'tipoMensaje': 1,
            'esGlobal': false,
            'esEncomienda': false,
          });
        }
        if (data['mensaje2'] != null &&
            data['mensaje2'].toString().isNotEmpty) {
          items.add({
            'docId': docId,
            'mensaje': data['mensaje2'],
            'asiento': data['asiento2'] ?? data['asiento'],
            'fecha': data['fecha'],
            'leida': data['leida2'] ?? false,
            'tipoMensaje': 2,
            'esGlobal': false,
            'esEncomienda': false,
          });
        }
        if (data['mensaje3'] != null &&
            data['mensaje3'].toString().isNotEmpty) {
          items.add({
            'docId': docId,
            'mensaje': data['mensaje3'],
            'asiento': data['asiento3'] ?? 'INFO',
            'fecha': data['fecha'],
            'leida': _esMensaje3Leido(data),
            'tipoMensaje': 3,
            'esGlobal': true,
            'esEncomienda': false,
          });
        }
      }
    }
    items.sort((a, b) {
      if (a['leida'] != b['leida']) return a['leida'] ? 1 : -1;
      if (a['fecha'] != null && b['fecha'] != null)
        return (b['fecha'] as Timestamp).compareTo(a['fecha'] as Timestamp);
      return 0;
    });
    return items;
  }

  // ── Contar no leídas ──
  int _contarNoLeidas(List<QueryDocumentSnapshot> docs) {
    int count = 0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      bool esEncomienda = data['tipo'] == 'encomienda';
      bool esDelUsuario = data['email'] == widget.userEmail;
      bool tieneMensaje3 =
          data['mensaje3'] != null && data['mensaje3'].toString().isNotEmpty;

      if (esEncomienda) {
        if (data['correo'] == widget.userEmail &&
            (data['leida'] ?? false) == false) count++;
        continue;
      }
      if (tieneMensaje3 && _estaOcultadaParaUsuario(data)) continue;
      if (!esDelUsuario && !tieneMensaje3) continue;

      if (esDelUsuario &&
          !(data['leida'] ?? false) &&
          data['mensaje'] != null &&
          data['mensaje'].toString().isNotEmpty) count++;

      if (esDelUsuario &&
          !(data['leida2'] ?? false) &&
          data['mensaje2'] != null &&
          data['mensaje2'].toString().isNotEmpty) count++;

      if (tieneMensaje3 && !_esMensaje3Leido(data)) count++;
    }
    return count;
  }

  // ── BUILD ──
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgPrimary,
      body: _buildNotificacionesList(),
    );
  }

  // ── Lista ──
  Widget _buildNotificacionesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('notificaciones')
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(accentBlue),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: accentRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: accentRed,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error al cargar',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return _buildEstadoVacio();

        final filtrados = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          bool esGlobal = data['mensaje3'] != null &&
              data['mensaje3'].toString().isNotEmpty;
          if (esGlobal && _estaOcultadaParaUsuario(data)) return false;
          if (data['tipo'] == 'encomienda' &&
              data['correo'] == widget.userEmail) return true;
          if (esGlobal) return true;
          if (data['email'] == widget.userEmail) return true;
          return false;
        }).toList();

        if (filtrados.isEmpty) return _buildEstadoVacio();

        final items = _expandirNotificaciones(filtrados);
        if (items.isEmpty) return _buildEstadoVacio();

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding:
              const EdgeInsets.only(top: 16, bottom: 90, left: 16, right: 16),
          itemCount: items.length,
          itemBuilder: (ctx, index) {
            return FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildNotificacionItem(items[index]),
              ),
            );
          },
        );
      },
    );
  }

  // ── Estado vacío ──
  Widget _buildEstadoVacio() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentBlue.withOpacity(0.1),
                    accentPurple.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: accentBlue.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Todo al día',
              style: TextStyle(
                color: textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No tienes notificaciones nuevas',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSecondary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card individual mejorada ──
  Widget _buildNotificacionItem(Map<String, dynamic> notif) {
    final bool leida = notif['leida'] ?? false;
    final String mensaje = notif['mensaje'] ?? 'Sin mensaje';
    final String asiento = notif['asiento']?.toString() ?? 'N/A';
    final int tipoMensaje = notif['tipoMensaje'] ?? 1;
    final bool esGlobal = notif['esGlobal'] ?? false;
    final bool esEncomienda = notif['esEncomienda'] ?? false;
    final String docId = notif['docId'];
    final String estado = notif['estado'] ?? '';
    final String descripcion = notif['descripcion'] ?? '';

    String fechaRelativa = 'Hace un momento';
    if (notif['fecha'] != null) {
      try {
        fechaRelativa = timeago.format((notif['fecha'] as Timestamp).toDate(),
            locale: 'es');
      } catch (e) {}
    }

    // Icono y color según tipo
    IconData avatarIcon;
    Color avatarColor;
    if (esEncomienda) {
      avatarIcon = Icons.local_shipping_rounded;
      avatarColor = _colorEncomienda(estado);
    } else if (esGlobal) {
      avatarIcon = Icons.campaign_rounded;
      avatarColor = accentPurple;
    } else if (tipoMensaje == 2) {
      avatarIcon = Icons.info_rounded;
      avatarColor = accentOrange;
    } else {
      avatarIcon = Icons.notifications_active_rounded;
      avatarColor = accentBlue;
    }

    // Etiqueta
    String? etiqueta;
    if (esEncomienda)
      etiqueta = 'Encomienda';
    else if (esGlobal)
      etiqueta = 'Anuncio';
    else if (tipoMensaje == 2) etiqueta = 'Actualización';

    return Dismissible(
      key: Key('${docId}_$tipoMensaje'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (dir) async {
        return await _confirmarEliminar(esGlobal);
      },
      onDismissed: (_) => _eliminarNotificacion(docId, esGlobal),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: accentRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              esGlobal ? Icons.visibility_off_rounded : Icons.delete_rounded,
              color: accentRed,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              esGlobal ? 'Ocultar' : 'Eliminar',
              style: const TextStyle(
                color: accentRed,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () {
          if (!leida) {
            setState(() {});
            _marcarComoLeida(docId, tipoMensaje);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: leida ? bgCard : unreadBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: leida ? dividerColor : accentBlue.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(leida ? 0.02 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar con gradiente
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      avatarColor.withOpacity(0.8),
                      avatarColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: avatarColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(avatarIcon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (etiqueta != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: avatarColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          etiqueta,
                          style: TextStyle(
                            color: avatarColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      mensaje,
                      style: TextStyle(
                        color: leida ? textSecondary : textPrimary,
                        fontSize: 15,
                        fontWeight: leida ? FontWeight.w500 : FontWeight.w600,
                        height: 1.4,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (esEncomienda && descripcion.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        descripcion,
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: textSecondary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          fechaRelativa,
                          style: TextStyle(
                            color: textSecondary.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (asiento != 'INFO' && asiento != 'N/A') ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: textSecondary.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Código de encomienda con botón de copiar
                          if (esEncomienda)
                            Flexible(
                              child: GestureDetector(
                                onTap: () => _copiarAlPortapapeles(asiento),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: avatarColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: avatarColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.copy_rounded,
                                        size: 12,
                                        color: avatarColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          asiento,
                                          style: TextStyle(
                                            color: avatarColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            Flexible(
                              child: Text(
                                'Asiento $asiento',
                                style: TextStyle(
                                  color: textSecondary.withOpacity(0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Indicador no leída
              if (!leida) ...[
                const SizedBox(width: 12),
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [accentBlue, accentPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentBlue.withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _colorEncomienda(String estado) {
    switch (estado.toLowerCase()) {
      case 'entregado':
        return accentGreen;
      case 'en tránsito':
      case 'en transito':
        return accentOrange;
      case 'pendiente':
        return accentBlue;
      default:
        return accentRed;
    }
  }

  Future<bool> _confirmarEliminar(bool esGlobal) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              esGlobal ? 'Ocultar notificación' : 'Eliminar notificación',
              style: const TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              esGlobal
                  ? '¿Deseas ocultar esta notificación?'
                  : '¿Estás seguro de que deseas eliminarla?',
              style: const TextStyle(
                color: textSecondary,
                fontSize: 15,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(
                  backgroundColor: accentRed.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  esGlobal ? 'Ocultar' : 'Eliminar',
                  style: const TextStyle(
                    color: accentRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// ==================== BADGE EXTERNO ====================
class NotificacionesBadge extends StatelessWidget {
  final String userEmail;
  final VoidCallback onTap;

  const NotificacionesBadge({
    Key? key,
    required this.userEmail,
    required this.onTap,
  }) : super(key: key);

  String _sanitizeEmail(String email) =>
      email.replaceAll('.', '_').replaceAll('@', '_at_');

  bool _esMensaje3Leido(Map<String, dynamic> data) {
    if (data['leida3'] == null) return false;
    if (data['leida3'] is Map)
      return (data['leida3'] as Map)[_sanitizeEmail(userEmail)] == true;
    if (data['leida3'] is bool) return data['leida3'] as bool;
    return false;
  }

  bool _estaOcultada(Map<String, dynamic> data) {
    if (data['ocultadoPara'] == null) return false;
    if (data['ocultadoPara'] is Map)
      return (data['ocultadoPara'] as Map)[_sanitizeEmail(userEmail)] == true;
    return false;
  }

  int _contarNoLeidas(List<QueryDocumentSnapshot> docs) {
    int count = 0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      bool esEncomienda = data['tipo'] == 'encomienda';
      bool esDelUsuario = data['email'] == userEmail;
      bool tieneMensaje3 =
          data['mensaje3'] != null && data['mensaje3'].toString().isNotEmpty;

      if (esEncomienda) {
        if (data['correo'] == userEmail && (data['leida'] ?? false) == false)
          count++;
        continue;
      }
      if (tieneMensaje3 && _estaOcultada(data)) continue;
      if (!esDelUsuario && !tieneMensaje3) continue;

      if (esDelUsuario &&
          !(data['leida'] ?? false) &&
          data['mensaje'] != null &&
          data['mensaje'].toString().isNotEmpty) count++;

      if (esDelUsuario &&
          !(data['leida2'] ?? false) &&
          data['mensaje2'] != null &&
          data['mensaje2'].toString().isNotEmpty) count++;

      if (tieneMensaje3 && !_esMensaje3Leido(data)) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('notificaciones').snapshots(),
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) count = _contarNoLeidas(snapshot.data!.docs);

        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 26,
              ),
              if (count > 0)
                Positioned(
                  right: -5,
                  top: -3,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        count > 99 ? '99+' : count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          onPressed: onTap,
        );
      },
    );
  }
}
