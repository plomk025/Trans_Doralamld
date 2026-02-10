import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de sincronización offline
/// Maneja toda la lógica de guardar operaciones pendientes y sincronizarlas automáticamente
class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  // Llaves para SharedPreferences
  static const String _keyImagenesPendientes = 'imagenes_pendientes';
  static const String _keyActualizacionesPendientes =
      'actualizaciones_pendientes';
  static const String _keyNotificacionesPendientes =
      'notificaciones_pendientes';

  bool _isSyncing = false;

  /// Verifica si hay conexión a internet
  Future<bool> hasConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Guarda una actualización de encomienda para sincronizar después
  Future<void> guardarActualizacionPendiente({
    required String codigoEncomienda,
    required Map<String, dynamic> updateData,
    required String coleccionBus,
    required String idBus,
    String? rutaImagenLocal,
    String? campoImagen,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendientes =
          prefs.getStringList(_keyActualizacionesPendientes) ?? [];

      final actualizacion = {
        'codigo_encomienda': codigoEncomienda,
        'update_data': updateData,
        'coleccion_bus': coleccionBus,
        'id_bus': idBus,
        'ruta_imagen_local': rutaImagenLocal,
        'campo_imagen': campoImagen,
        'timestamp': DateTime.now().toIso8601String(),
      };

      pendientes.add(json.encode(actualizacion));
      await prefs.setStringList(_keyActualizacionesPendientes, pendientes);

      print('✅ Actualización guardada offline: $codigoEncomienda');
    } catch (e) {
      print('❌ Error al guardar actualización offline: $e');
      rethrow;
    }
  }

  /// Guarda una notificación para enviar después
  Future<void> guardarNotificacionPendiente({
    required String uidRemitente,
    required String correoRemitente,
    required String nombreRemitente,
    required String titulo,
    required String mensaje,
    required String codigoEncomienda,
    required String estado,
    required String accion,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendientes =
          prefs.getStringList(_keyNotificacionesPendientes) ?? [];

      final notificacion = {
        'uid_remitente': uidRemitente,
        'correo_remitente': correoRemitente,
        'nombre_remitente': nombreRemitente,
        'titulo': titulo,
        'mensaje': mensaje,
        'codigo_encomienda': codigoEncomienda,
        'estado': estado,
        'accion': accion,
        'timestamp': DateTime.now().toIso8601String(),
      };

      pendientes.add(json.encode(notificacion));
      await prefs.setStringList(_keyNotificacionesPendientes, pendientes);

      print('✅ Notificación guardada offline para: $uidRemitente');
    } catch (e) {
      print('❌ Error al guardar notificación offline: $e');
    }
  }

  /// Sincroniza todas las operaciones pendientes
  Future<SyncResult> sincronizarPendientes() async {
    if (_isSyncing) {
      print('⚠️ Ya hay una sincronización en curso');
      return SyncResult(success: false, message: 'Sincronización en curso');
    }

    _isSyncing = true;

    try {
      if (!await hasConnection()) {
        print('📴 Sin conexión, sincronización cancelada');
        return SyncResult(success: false, message: 'Sin conexión a internet');
      }

      print('🔄 Iniciando sincronización...');

      int totalSincronizadas = 0;
      int totalErrores = 0;

      // 1. Sincronizar actualizaciones de encomiendas
      final resultActualizaciones = await _sincronizarActualizaciones();
      totalSincronizadas += resultActualizaciones.sincronizadas;
      totalErrores += resultActualizaciones.errores;

      // 2. Sincronizar notificaciones
      final resultNotificaciones = await _sincronizarNotificaciones();
      totalSincronizadas += resultNotificaciones.sincronizadas;
      totalErrores += resultNotificaciones.errores;

      print('✅ Sincronización completada:');
      print('   - Sincronizadas: $totalSincronizadas');
      print('   - Errores: $totalErrores');

      return SyncResult(
        success: totalErrores == 0,
        message: totalErrores == 0
            ? 'Sincronización exitosa: $totalSincronizadas operaciones'
            : 'Sincronización con errores: $totalSincronizadas exitosas, $totalErrores fallidas',
        sincronizadas: totalSincronizadas,
        errores: totalErrores,
      );
    } catch (e) {
      print('❌ Error en sincronización: $e');
      return SyncResult(success: false, message: 'Error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Sincroniza las actualizaciones de encomiendas pendientes
  Future<_SyncStats> _sincronizarActualizaciones() async {
    int sincronizadas = 0;
    int errores = 0;

    try {
      final prefs = await SharedPreferences.getInstance();
      final pendientes =
          prefs.getStringList(_keyActualizacionesPendientes) ?? [];

      if (pendientes.isEmpty) {
        print('ℹ️ No hay actualizaciones pendientes');
        return _SyncStats(sincronizadas: 0, errores: 0);
      }

      print('📤 Sincronizando ${pendientes.length} actualizaciones...');

      List<String> noSincronizadas = [];

      for (String actualizacionJson in pendientes) {
        try {
          final actualizacion = json.decode(actualizacionJson);

          // 1. Subir imagen si existe
          String? urlImagen;
          if (actualizacion['ruta_imagen_local'] != null) {
            urlImagen = await _subirImagen(
              actualizacion['ruta_imagen_local'],
              actualizacion['codigo_encomienda'],
              actualizacion['campo_imagen'],
            );
          }

          // 2. Actualizar Firestore
          Map<String, dynamic> updateData = Map<String, dynamic>.from(
            actualizacion['update_data'],
          );

          // Agregar URL de imagen si se subió
          if (urlImagen != null && actualizacion['campo_imagen'] != null) {
            updateData[actualizacion['campo_imagen']] = urlImagen;
          }

          await FirebaseFirestore.instance
              .collection('encomiendas_registradas')
              .doc(actualizacion['codigo_encomienda'])
              .update(updateData);

          // 3. Actualizar bus si corresponde
          if (actualizacion['coleccion_bus'] != null &&
              actualizacion['id_bus'] != null) {
            await FirebaseFirestore.instance
                .collection(actualizacion['coleccion_bus'])
                .doc(actualizacion['id_bus'])
                .set({
              'encomiendas':
                  FieldValue.arrayUnion([actualizacion['codigo_encomienda']])
            }, SetOptions(merge: true));
          }

          sincronizadas++;
          print(
              '✅ Actualización sincronizada: ${actualizacion['codigo_encomienda']}');
        } catch (e) {
          print('❌ Error al sincronizar actualización: $e');
          noSincronizadas.add(actualizacionJson);
          errores++;
        }
      }

      // Guardar solo las que no se sincronizaron
      await prefs.setStringList(_keyActualizacionesPendientes, noSincronizadas);

      return _SyncStats(sincronizadas: sincronizadas, errores: errores);
    } catch (e) {
      print('❌ Error al sincronizar actualizaciones: $e');
      return _SyncStats(sincronizadas: sincronizadas, errores: errores);
    }
  }

  /// Sincroniza las notificaciones pendientes
  Future<_SyncStats> _sincronizarNotificaciones() async {
    int sincronizadas = 0;
    int errores = 0;

    try {
      final prefs = await SharedPreferences.getInstance();
      final pendientes =
          prefs.getStringList(_keyNotificacionesPendientes) ?? [];

      if (pendientes.isEmpty) {
        print('ℹ️ No hay notificaciones pendientes');
        return _SyncStats(sincronizadas: 0, errores: 0);
      }

      print('📤 Sincronizando ${pendientes.length} notificaciones...');

      List<String> noSincronizadas = [];

      for (String notificacionJson in pendientes) {
        try {
          final notificacion = json.decode(notificacionJson);

          // 1. Crear notificación en Firestore
          await FirebaseFirestore.instance.collection('notificaciones').add({
            'uid': notificacion['uid_remitente'],
            'correo': notificacion['correo_remitente'],
            'nombre_remitente': notificacion['nombre_remitente'],
            'titulo': notificacion['titulo'],
            'mensaje': notificacion['mensaje'],
            'codigo_encomienda': notificacion['codigo_encomienda'],
            'estado': notificacion['estado'],
            'leida': false,
            'fecha': FieldValue.serverTimestamp(),
            'tipo': 'encomienda',
            'accion': notificacion['accion'],
          });

          // 2. Enviar push notification
          await _enviarPushNotification(
            uidRemitente: notificacion['uid_remitente'],
            titulo: notificacion['titulo'],
            mensaje: notificacion['mensaje'],
            codigoEncomienda: notificacion['codigo_encomienda'],
            estado: notificacion['estado'],
          );

          sincronizadas++;
          print(
              '✅ Notificación sincronizada: ${notificacion['codigo_encomienda']}');
        } catch (e) {
          print('❌ Error al sincronizar notificación: $e');
          noSincronizadas.add(notificacionJson);
          errores++;
        }
      }

      // Guardar solo las que no se sincronizaron
      await prefs.setStringList(_keyNotificacionesPendientes, noSincronizadas);

      return _SyncStats(sincronizadas: sincronizadas, errores: errores);
    } catch (e) {
      print('❌ Error al sincronizar notificaciones: $e');
      return _SyncStats(sincronizadas: sincronizadas, errores: errores);
    }
  }

  /// Sube una imagen a Firebase Storage
  Future<String?> _subirImagen(
    String rutaLocal,
    String codigoEncomienda,
    String campoImagen,
  ) async {
    try {
      final file = File(rutaLocal);
      if (!await file.exists()) {
        print('⚠️ Archivo no existe: $rutaLocal');
        return null;
      }

      final rutaStorage =
          'encomiendas/$codigoEncomienda/$campoImagen-${DateTime.now().millisecondsSinceEpoch}.jpg';

      final ref = FirebaseStorage.instance.ref().child(rutaStorage);
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      print('✅ Imagen subida: $rutaStorage');
      return url;
    } catch (e) {
      print('❌ Error al subir imagen: $e');
      return null;
    }
  }

  /// Envía una push notification
  Future<void> _enviarPushNotification({
    required String uidRemitente,
    required String titulo,
    required String mensaje,
    required String codigoEncomienda,
    required String estado,
  }) async {
    try {
      const String baseUrl = 'https://notificaciones-1hoa.onrender.com';
      final Uri url = Uri.parse('$baseUrl/api/notifications/send-to-user');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'userId': uidRemitente,
              'title': titulo,
              'body': mensaje,
              'data': {
                'tipo': 'encomienda',
                'codigo': codigoEncomienda,
                'estado': estado,
                'accion': 'cambio_estado',
                'timestamp': DateTime.now().toIso8601String(),
              },
              'channelId': 'encomiendas_channel',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ Push notification enviada');
      } else {
        print('⚠️ Error al enviar push: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en push notification: $e');
      // No lanzar excepción, la notificación se creó en Firestore
    }
  }

  /// Obtiene el número de operaciones pendientes
  Future<PendingOperations> getPendingOperationsCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final actualizaciones =
          prefs.getStringList(_keyActualizacionesPendientes) ?? [];
      final notificaciones =
          prefs.getStringList(_keyNotificacionesPendientes) ?? [];

      return PendingOperations(
        actualizaciones: actualizaciones.length,
        notificaciones: notificaciones.length,
        total: actualizaciones.length + notificaciones.length,
      );
    } catch (e) {
      print('❌ Error al obtener operaciones pendientes: $e');
      return PendingOperations(actualizaciones: 0, notificaciones: 0, total: 0);
    }
  }

  /// Limpia todas las operaciones pendientes (usar con cuidado)
  Future<void> clearAllPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActualizacionesPendientes);
    await prefs.remove(_keyNotificacionesPendientes);
    print('🗑️ Todas las operaciones pendientes eliminadas');
  }
}

/// Clase auxiliar para estadísticas de sincronización
class _SyncStats {
  final int sincronizadas;
  final int errores;

  _SyncStats({required this.sincronizadas, required this.errores});
}

/// Resultado de la sincronización
class SyncResult {
  final bool success;
  final String message;
  final int sincronizadas;
  final int errores;

  SyncResult({
    required this.success,
    required this.message,
    this.sincronizadas = 0,
    this.errores = 0,
  });
}

/// Operaciones pendientes
class PendingOperations {
  final int actualizaciones;
  final int notificaciones;
  final int total;

  PendingOperations({
    required this.actualizaciones,
    required this.notificaciones,
    required this.total,
  });

  bool get hasPending => total > 0;
}
