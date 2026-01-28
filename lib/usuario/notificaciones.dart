import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

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

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Paleta de colores inspirada en transporte de buses
  final Color primaryBusBlue = const Color.fromARGB(255, 243, 248, 255);
  final Color accentOrange = const Color(0xFFEA580C);
  final Color darkNavy = const Color(0xFF0F172A);
  final Color roadGray = const Color(0xFF334155);
  final Color lightBg = const Color(0xFFF1F5F9);
  final Color textGray = const Color(0xFF475569);
  final Color successGreen = const Color(0xFF059669);
  final Color accentBlue = const Color(0xFF1E40AF);
  final Color mainRed = const Color(0xFF940016);
  final Color unreadBg = const Color(0xFFFEF3C7);
  final Color borderColor = const Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());

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

  Future<void> _marcarComoLeida(String notificacionId, int tipoMensaje) async {
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
        case 4: // Notificación de encomienda
          updateData = {'leida': true};
          break;
      }

      await db
          .collection('notificaciones')
          .doc(notificacionId)
          .update(updateData);
    } catch (e) {
      print('Error al marcar notificación como leída: $e');
    }
  }

  Future<void> _eliminarNotificacion(
      String notificacionId, bool esGlobal) async {
    try {
      if (esGlobal) {
        await db.collection('notificaciones').doc(notificacionId).update({
          'ocultadoPara.${_sanitizeEmail(widget.userEmail)}': true,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notificación ocultada'),
            backgroundColor: successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        await db.collection('notificaciones').doc(notificacionId).delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notificación eliminada'),
            backgroundColor: successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error al eliminar notificación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al eliminar la notificación'),
          backgroundColor: accentOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  String _sanitizeEmail(String email) {
    return email.replaceAll('.', '_').replaceAll('@', '_at_');
  }

  bool _esMensaje3Leido(Map<String, dynamic> data) {
    if (data['leida3'] == null) return false;

    if (data['leida3'] is Map) {
      final leida3Map = data['leida3'] as Map<String, dynamic>;
      final sanitizedEmail = _sanitizeEmail(widget.userEmail);
      return leida3Map[sanitizedEmail] == true;
    }

    if (data['leida3'] is bool) {
      return data['leida3'] as bool;
    }

    return false;
  }

  bool _estaOcultadaParaUsuario(Map<String, dynamic> data) {
    if (data['ocultadoPara'] == null) return false;

    if (data['ocultadoPara'] is Map) {
      final ocultadoMap = data['ocultadoPara'] as Map<String, dynamic>;
      final sanitizedEmail = _sanitizeEmail(widget.userEmail);
      return ocultadoMap[sanitizedEmail] == true;
    }

    return false;
  }

  List<Map<String, dynamic>> _expandirNotificaciones(
      List<QueryDocumentSnapshot> docs) {
    List<Map<String, dynamic>> notificacionesExpandidas = [];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final docId = doc.id;

      bool esGlobal =
          data['mensaje3'] != null && data['mensaje3'].toString().isNotEmpty;
      if (esGlobal && _estaOcultadaParaUsuario(data)) {
        continue;
      }

      bool esEncomienda = data['tipo'] == 'encomienda';

      if (esEncomienda) {
        if (data['correo'] == widget.userEmail) {
          notificacionesExpandidas.add({
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
          notificacionesExpandidas.add({
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
          notificacionesExpandidas.add({
            'docId': docId,
            'mensaje': data['mensaje2'],
            'asiento': data['asiento2'] ?? data['asiento'],
            'fecha': data['fecha'] ?? null,
            'leida': data['leida2'] ?? false,
            'tipoMensaje': 2,
            'esGlobal': false,
            'esEncomienda': false,
          });
        }

        if (data['mensaje3'] != null &&
            data['mensaje3'].toString().isNotEmpty) {
          notificacionesExpandidas.add({
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

    notificacionesExpandidas.sort((a, b) {
      if (a['leida'] != b['leida']) {
        return a['leida'] ? 1 : -1;
      }
      if (a['fecha'] != null && b['fecha'] != null) {
        return (b['fecha'] as Timestamp).compareTo(a['fecha'] as Timestamp);
      }
      return 0;
    });

    return notificacionesExpandidas;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBusBlue,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildHeader(),
          _buildNotificacionesList(),
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
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: Color(0xFF940016),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NOTIFICACIONES',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color.fromARGB(255, 36, 35, 35),
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                'Actualizaciones de viajes',
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
                      StreamBuilder<QuerySnapshot>(
                        stream: db.collection('notificaciones').snapshots(),
                        builder: (context, snapshot) {
                          int count = 0;
                          if (snapshot.hasData) {
                            final notificacionesFiltradas =
                                snapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;

                              bool esEncomienda = data['tipo'] == 'encomienda';
                              bool esGlobal = data['mensaje3'] != null &&
                                  data['mensaje3'].toString().isNotEmpty;

                              if (esEncomienda) {
                                return data['correo'] == widget.userEmail;
                              }

                              if (esGlobal && _estaOcultadaParaUsuario(data)) {
                                return false;
                              }

                              if (esGlobal) {
                                return true;
                              }
                              if (data['email'] == widget.userEmail) {
                                return true;
                              }
                              return false;
                            }).toList();

                            final expandidas = _expandirNotificaciones(
                                notificacionesFiltradas);
                            count = expandidas.where((n) => !n['leida']).length;
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: count > 0
                                  ? const Color(0xFF940016)
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: count > 0
                                    ? const Color(0xFF940016).withOpacity(0.2)
                                    : Colors.grey.shade400,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  count > 0
                                      ? Icons.circle_notifications
                                      : Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  count > 0 ? '$count' : 'Al día',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Mis Notificaciones',
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
                      'Mantente informado sobre tus reservas, viajes y encomiendas',
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

  Widget _buildNotificacionesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('notificaciones')
          .orderBy('fecha', descending: true)
          .snapshots(),
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
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(mainRed),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Cargando notificaciones...',
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

        if (snapshot.hasError) {
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
                    child: Icon(Icons.error_outline,
                        size: 60, color: accentOrange),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Error al cargar',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: darkNavy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No se pudieron cargar las notificaciones',
                    style: TextStyle(fontSize: 14, color: textGray),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEstadoVacio();
        }

        final notificacionesFiltradas = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          bool esGlobal = data['mensaje3'] != null &&
              data['mensaje3'].toString().isNotEmpty;
          if (esGlobal && _estaOcultadaParaUsuario(data)) {
            return false;
          }

          if (data['tipo'] == 'encomienda' &&
              data['correo'] == widget.userEmail) {
            return true;
          }

          if (esGlobal) {
            return true;
          }

          if (data['email'] == widget.userEmail) {
            return true;
          }

          return false;
        }).toList();

        if (notificacionesFiltradas.isEmpty) {
          return _buildEstadoVacio();
        }

        final notificacionesExpandidas =
            _expandirNotificaciones(notificacionesFiltradas);

        if (notificacionesExpandidas.isEmpty) {
          return _buildEstadoVacio();
        }

        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child:
                      _buildNotificacionCard(notificacionesExpandidas[index]),
                );
              },
              childCount: notificacionesExpandidas.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEstadoVacio() {
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
                  Icons.notifications_none_outlined,
                  size: 60,
                  color: textGray,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Sin Notificaciones',
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
                  'Aquí aparecerán las actualizaciones\nde tus reservas, compras y encomiendas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: textGray,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificacionCard(Map<String, dynamic> notif) {
    final bool leida = notif['leida'] ?? false;
    final String mensaje = notif['mensaje'] ?? 'Sin mensaje';
    final dynamic asientoData = notif['asiento'];
    final String asiento = asientoData?.toString() ?? 'N/A';
    final int tipoMensaje = notif['tipoMensaje'] ?? 1;
    final bool esGlobal = notif['esGlobal'] ?? false;
    final bool esEncomienda = notif['esEncomienda'] ?? false;
    final String docId = notif['docId'];
    final String estado = notif['estado'] ?? '';
    final String descripcion = notif['descripcion'] ?? '';

    String fechaRelativa = 'Hace un momento';
    if (notif['fecha'] != null) {
      try {
        Timestamp timestamp = notif['fecha'] as Timestamp;
        fechaRelativa = timeago.format(timestamp.toDate(), locale: 'es');
      } catch (e) {
        fechaRelativa = 'Hace un momento';
      }
    }

    Color encomiendaColor = successGreen;
    IconData encomiendaIcon = Icons.local_shipping_rounded;

    if (esEncomienda) {
      switch (estado.toLowerCase()) {
        case 'entregado':
          encomiendaColor = successGreen;
          encomiendaIcon = Icons.check_circle_rounded;
          break;
        case 'en tránsito':
        case 'en transito':
          encomiendaColor = accentOrange;
          encomiendaIcon = Icons.local_shipping_rounded;
          break;
        case 'pendiente':
          encomiendaColor = Colors.amber.shade700;
          encomiendaIcon = Icons.schedule_rounded;
          break;
        default:
          encomiendaColor = accentBlue;
          encomiendaIcon = Icons.inventory_2_rounded;
      }
    }

    return Dismissible(
      key: Key(docId + tipoMensaje.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    esGlobal ? Icons.visibility_off : Icons.delete_outline,
                    color: mainRed,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      esGlobal
                          ? 'Ocultar notificación'
                          : 'Eliminar notificación',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                esGlobal
                    ? '¿Deseas ocultar esta notificación? No la volverás a ver.'
                    : '¿Estás seguro de que deseas eliminar esta notificación?',
                style: TextStyle(
                  color: textGray,
                  fontSize: 14,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: textGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    esGlobal ? 'Ocultar' : 'Eliminar',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        _eliminarNotificacion(docId, esGlobal);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: mainRed,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              esGlobal ? Icons.visibility_off : Icons.delete_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              esGlobal ? 'Ocultar' : 'Eliminar',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () {
          if (!leida) {
            setState(() {
              _marcarComoLeida(docId, tipoMensaje);
            });
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: leida ? Colors.white : unreadBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: leida
                  ? Colors.grey.shade200
                  : (esEncomienda
                      ? encomiendaColor.withOpacity(0.3)
                      : (esGlobal
                          ? mainRed.withOpacity(0.3)
                          : Colors.amber.shade400)),
              width: esGlobal || esEncomienda ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(leida ? 0.04 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: leida
                        ? lightBg
                        : (esEncomienda
                            ? encomiendaColor.withOpacity(0.15)
                            : (esGlobal
                                ? mainRed.withOpacity(0.15)
                                : Colors.amber.shade100)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: leida
                          ? Colors.grey.shade300
                          : (esEncomienda
                              ? encomiendaColor
                              : (esGlobal ? mainRed : Colors.amber.shade400)),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    esEncomienda
                        ? encomiendaIcon
                        : (esGlobal
                            ? Icons.campaign_rounded
                            : (tipoMensaje == 2
                                ? Icons.notification_add_rounded
                                : Icons.notifications_active_rounded)),
                    color: leida
                        ? textGray
                        : (esEncomienda
                            ? encomiendaColor
                            : (esGlobal ? mainRed : Colors.amber.shade700)),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (esGlobal || tipoMensaje == 2 || esEncomienda)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: esEncomienda
                                  ? encomiendaColor.withOpacity(0.15)
                                  : (esGlobal
                                      ? mainRed.withOpacity(0.15)
                                      : accentBlue.withOpacity(0.15)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              esEncomienda
                                  ? 'Encomienda'
                                  : (esGlobal
                                      ? 'Anuncio General'
                                      : 'Actualización'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: esEncomienda
                                    ? encomiendaColor
                                    : (esGlobal ? mainRed : accentBlue),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      Text(
                        mensaje,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: leida ? FontWeight.w500 : FontWeight.w600,
                          color: leida ? textGray : darkNavy,
                          height: 1.5,
                        ),
                      ),
                      if (esEncomienda && descripcion.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          descripcion,
                          style: TextStyle(
                            fontSize: 12,
                            color: textGray,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: textGray,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            fechaRelativa,
                            style: TextStyle(
                              fontSize: 12,
                              color: textGray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (asiento != 'INFO' && asiento != 'N/A') ...[
                            const SizedBox(width: 12),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: textGray,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              esEncomienda ? Icons.qr_code_2 : Icons.event_seat,
                              size: 14,
                              color: textGray,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                esEncomienda ? asiento : 'Asiento $asiento',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textGray,
                                  fontWeight: FontWeight.w600,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== WIDGET DE BADGE - CORREGIDO ====================
class NotificacionesBadge extends StatelessWidget {
  final String userEmail;
  final VoidCallback onTap;

  const NotificacionesBadge({
    Key? key,
    required this.userEmail,
    required this.onTap,
  }) : super(key: key);

  String _sanitizeEmail(String email) {
    return email.replaceAll('.', '_').replaceAll('@', '_at_');
  }

  bool _esMensaje3Leido(Map<String, dynamic> data, String userEmail) {
    if (data['leida3'] == null) return false;

    if (data['leida3'] is Map) {
      final leida3Map = data['leida3'] as Map<String, dynamic>;
      final sanitizedEmail = _sanitizeEmail(userEmail);
      return leida3Map[sanitizedEmail] == true;
    }

    if (data['leida3'] is bool) {
      return data['leida3'] as bool;
    }

    return false;
  }

  bool _estaOcultadaParaUsuario(Map<String, dynamic> data, String userEmail) {
    if (data['ocultadoPara'] == null) return false;

    if (data['ocultadoPara'] is Map) {
      final ocultadoMap = data['ocultadoPara'] as Map<String, dynamic>;
      final sanitizedEmail = _sanitizeEmail(userEmail);
      return ocultadoMap[sanitizedEmail] == true;
    }

    return false;
  }

  int _contarNotificacionesNoLeidas(
      List<QueryDocumentSnapshot> docs, String userEmail) {
    int count = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      bool esEncomienda = data['tipo'] == 'encomienda';
      bool esDelUsuario = data['email'] == userEmail;
      bool tieneMensaje3 =
          data['mensaje3'] != null && data['mensaje3'].toString().isNotEmpty;

      // ========== MANEJO DE ENCOMIENDAS ==========
      if (esEncomienda) {
        if (data['correo'] == userEmail && (data['leida'] ?? false) == false) {
          count++;
        }
        continue; // ⚠️ CRÍTICO: Saltar al siguiente documento
      }

      // Si es global y está oculta, no contar
      if (tieneMensaje3 && _estaOcultadaParaUsuario(data, userEmail)) {
        continue;
      }

      // Si no es del usuario ni global, saltar
      if (!esDelUsuario && !tieneMensaje3) {
        continue;
      }

      // Contar mensaje 1 (no leído)
      if (esDelUsuario &&
          (data['leida'] ?? false) == false &&
          data['mensaje'] != null &&
          data['mensaje'].toString().isNotEmpty) {
        count++;
      }

      // Contar mensaje 2 (no leído)
      if (esDelUsuario &&
          (data['leida2'] ?? false) == false &&
          data['mensaje2'] != null &&
          data['mensaje2'].toString().isNotEmpty) {
        count++;
      }

      // Contar mensaje 3 (global no leído)
      if (tieneMensaje3 && !_esMensaje3Leido(data, userEmail)) {
        count++;
      }
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

        if (snapshot.hasData) {
          count = _contarNotificacionesNoLeidas(snapshot.data!.docs, userEmail);
        }

        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined, size: 26),
              if (count > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF940016),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF940016).withOpacity(0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        count > 99 ? '99+' : count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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
