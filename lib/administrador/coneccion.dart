import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'offline_services.dart'; // ← Importación corregida

/// Servicio que monitorea la conectividad y sincroniza automáticamente
class ConnectivitySyncManager {
  static final ConnectivitySyncManager _instance =
      ConnectivitySyncManager._internal();
  factory ConnectivitySyncManager() => _instance;
  ConnectivitySyncManager._internal();

  final Connectivity _connectivity = Connectivity();
  final OfflineSyncService _syncService = OfflineSyncService();

  StreamSubscription<List<ConnectivityResult>>?
      _connectivitySubscription; // ✅ Corregido: List<ConnectivityResult>
  bool _wasOffline = false;
  bool _isInitialized = false;

  /// Callbacks para notificar cambios de estado
  Function(bool isOnline)? onConnectivityChange;
  Function(SyncResult result)? onSyncComplete;
  Function(int pendingCount)? onPendingCountChange;

  /// Inicializa el monitoreo de conectividad
  Future<void> initialize() async {
    if (_isInitialized) {
      print('⚠️ ConnectivitySyncManager ya está inicializado');
      return;
    }

    print('🚀 Inicializando ConnectivitySyncManager...');

    // Verificar estado inicial
    final initialStatus = await _connectivity.checkConnectivity();
    _wasOffline = _isOfflineStatus(initialStatus); // ✅ Corregido

    // Verificar operaciones pendientes
    await _checkPendingOperations();

    // Escuchar cambios de conectividad
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged, // ✅ Corregido: acepta List<ConnectivityResult>
      onError: (error) {
        print('❌ Error en conectividad: $error');
      },
    );

    _isInitialized = true;
    print('✅ ConnectivitySyncManager inicializado');
  }

  /// Verifica si el estado de conectividad es offline
  bool _isOfflineStatus(List<ConnectivityResult> results) {
    return results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none);
  }

  /// Maneja cambios en la conectividad
  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    final isOnline = !_isOfflineStatus(results);

    print('📡 Cambio de conectividad: ${_getConnectionType(results)}');

    // Notificar cambio de conectividad
    onConnectivityChange?.call(isOnline);

    // Si recuperamos conexión después de estar offline
    if (isOnline && _wasOffline) {
      print('✅ Conexión recuperada, iniciando sincronización...');
      await _sincronizarAutomaticamente();
    }

    _wasOffline = !isOnline;
  }

  /// Sincroniza automáticamente las operaciones pendientes
  Future<void> _sincronizarAutomaticamente() async {
    try {
      // Verificar si hay operaciones pendientes
      final pending = await _syncService.getPendingOperationsCount();

      if (!pending.hasPending) {
        print('ℹ️ No hay operaciones pendientes para sincronizar');
        return;
      }

      print('🔄 Iniciando sincronización automática...');
      print('   - Actualizaciones pendientes: ${pending.actualizaciones}');
      print('   - Notificaciones pendientes: ${pending.notificaciones}');

      // Pequeño delay para asegurar estabilidad de conexión
      await Future.delayed(const Duration(seconds: 2));

      // Ejecutar sincronización
      final result = await _syncService.sincronizarPendientes();

      // Notificar resultado
      onSyncComplete?.call(result);

      if (result.success) {
        print('✅ Sincronización automática completada exitosamente');
      } else {
        print('⚠️ Sincronización automática con errores: ${result.message}');
      }

      // Actualizar contador de pendientes
      await _checkPendingOperations();
    } catch (e) {
      print('❌ Error en sincronización automática: $e');
    }
  }

  /// Verifica operaciones pendientes y notifica
  Future<void> _checkPendingOperations() async {
    try {
      final pending = await _syncService.getPendingOperationsCount();
      onPendingCountChange?.call(pending.total);

      if (pending.hasPending) {
        print('📊 Operaciones pendientes: ${pending.total}');
      }
    } catch (e) {
      print('❌ Error al verificar operaciones pendientes: $e');
    }
  }

  /// Fuerza una sincronización manual
  Future<SyncResult> sincronizarManualmente() async {
    print('🔄 Sincronización manual solicitada...');

    if (!await _syncService.hasConnection()) {
      return SyncResult(
        success: false,
        message: 'Sin conexión a internet',
      );
    }

    final result = await _syncService.sincronizarPendientes();

    // Actualizar contador después de sincronizar
    await _checkPendingOperations();

    return result;
  }

  /// Obtiene el estado actual de conectividad
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return !_isOfflineStatus(results);
  }

  /// Obtiene el conteo de operaciones pendientes
  Future<PendingOperations> getPendingOperations() async {
    return await _syncService.getPendingOperationsCount();
  }

  /// Detiene el monitoreo
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _isInitialized = false;
    print('🛑 ConnectivitySyncManager detenido');
  }

  /// Obtiene descripción del tipo de conexión
  String _getConnectionType(List<ConnectivityResult> results) {
    if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
      return 'Sin conexión';
    }

    // Mostrar el primer tipo de conexión activo
    final activeConnection = results.firstWhere(
      (r) => r != ConnectivityResult.none,
      orElse: () => ConnectivityResult.none,
    );

    switch (activeConnection) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Datos móviles';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return 'Otra conexión';
      case ConnectivityResult.none:
      default:
        return 'Sin conexión';
    }
  }
}
