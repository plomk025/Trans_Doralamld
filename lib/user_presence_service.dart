import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Servicio para manejar el estado de presencia del usuario
class UserPresenceService {
  static final UserPresenceService _instance = UserPresenceService._internal();
  factory UserPresenceService() => _instance;
  UserPresenceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Establece el estado del usuario como conectado
  Future<void> setUserOnline() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ No hay usuario logueado, no se actualiza estado');
        return;
      }

      await _firestore.collection('usuarios_registrados').doc(user.uid).set({
        'estado': 'conectado',
        'ultimaConexion': FieldValue.serverTimestamp(),
        'email': user.email,
      }, SetOptions(merge: true));

      debugPrint('✅ Usuario marcado como CONECTADO: ${user.email}');
    } catch (e) {
      debugPrint('❌ Error al actualizar estado a conectado: $e');
    }
  }

  /// Establece el estado del usuario como desconectado
  Future<void> setUserOffline() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ No hay usuario logueado, no se actualiza estado');
        return;
      }

      await _firestore.collection('usuarios_registrados').doc(user.uid).set({
        'estado': 'desconectado',
        'ultimaDesconexion': FieldValue.serverTimestamp(),
        'email': user.email,
      }, SetOptions(merge: true));

      debugPrint('✅ Usuario marcado como DESCONECTADO: ${user.email}');
    } catch (e) {
      debugPrint('❌ Error al actualizar estado a desconectado: $e');
    }
  }

  /// Configura el listener de cambios de autenticación
  void setupAuthListener() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // Usuario logueado -> marcar como conectado
        setUserOnline();
        debugPrint('👤 Usuario autenticado: ${user.email}');
      } else {
        // No hay usuario -> no hacer nada
        debugPrint('👤 No hay usuario autenticado');
      }
    });
  }
}
