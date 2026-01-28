const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

// ==================== NOTIFICAR APROBACIÓN ====================
exports.notificarAprobacion = functions.https.onCall(async (data, context) => {
  try {
    const { 
      userId, 
      reservaId, 
      busId, 
      asiento, 
      nombreComprador, 
      paradaNombre, 
      total,
      boletoUrl,
      numeroBus,
      horaSalida,
      fechaSalida
    } = data;

    console.log(`✅ Iniciando notificación de aprobación para userId: ${userId}`);

    // Buscar el FCM token del usuario
    const usuarioDoc = await db.collection('usuarios').doc(userId).get();

    if (!usuarioDoc.exists) {
      console.error(`❌ Usuario no encontrado: ${userId}`);
      return { success: false, error: 'Usuario no encontrado' };
    }

    const userData = usuarioDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      console.log(`⚠️ Usuario ${userId} no tiene FCM token registrado`);
      return { success: false, error: 'Usuario sin token FCM' };
    }

    console.log(`🔑 Token encontrado para usuario ${userId}`);

    // Construir payload de notificación
    const message = {
      token: fcmToken,
      notification: {
        title: '✅ ¡Pago Aprobado!',
        body: `Tu reserva del asiento ${asiento} en el bus ${numeroBus} ha sido aprobada. ¡Buen viaje!`,
      },
      data: {
        tipo: 'compra_aprobada',
        reservaId: reservaId,
        busId: busId,
        asiento: asiento.toString(),
        nombreComprador: nombreComprador || '',
        paradaNombre: paradaNombre || '',
        total: total.toString(),
        boletoUrl: boletoUrl || '',
        numeroBus: numeroBus || '',
        horaSalida: horaSalida || '',
        fechaSalida: fechaSalida || '',
        timestamp: Date.now().toString(),
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        accion: 'ver_boleto',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'compras_channel',
          sound: 'default',
          color: '#10B981',
          icon: '@mipmap/ic_launcher',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            contentAvailable: true,
          },
        },
      },
    };

    // Enviar notificación
    const response = await admin.messaging().send(message);
    console.log('✅ Notificación de aprobación enviada:', response);

    // Guardar en historial
    await db.collection('notificaciones').add({
      usuarioId: userId,
      titulo: '✅ ¡Pago Aprobado!',
      mensaje: `Tu reserva del asiento ${asiento} en el bus ${numeroBus} ha sido aprobada. ¡Buen viaje!`,
      tipo: 'compra_aprobada',
      reservaId: reservaId,
      busId: busId,
      enviada: true,
      fechaEnvio: admin.firestore.FieldValue.serverTimestamp(),
      messageId: response,
      data: {
        asiento: asiento,
        total: total,
        boletoUrl: boletoUrl,
      }
    });

    return { success: true, messageId: response };

  } catch (error) {
    console.error('❌ Error al enviar notificación de aprobación:', error);
    
    // Guardar error en historial
    if (data.userId) {
      await db.collection('notificaciones').add({
        usuarioId: data.userId,
        titulo: '✅ ¡Pago Aprobado!',
        tipo: 'compra_aprobada',
        reservaId: data.reservaId,
        enviada: false,
        error: error.message,
        errorCode: error.code,
        fechaIntento: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return { success: false, error: error.message };
  }
});

// ==================== NOTIFICAR RECHAZO ====================
exports.notificarRechazo = functions.https.onCall(async (data, context) => {
  try {
    const { 
      userId, 
      reservaId, 
      busId, 
      asiento, 
      motivo,
      nombreComprador
    } = data;

    console.log(`❌ Iniciando notificación de rechazo para userId: ${userId}`);

    // Buscar el FCM token del usuario
    const usuarioDoc = await db.collection('usuarios').doc(userId).get();

    if (!usuarioDoc.exists) {
      console.error(`❌ Usuario no encontrado: ${userId}`);
      return { success: false, error: 'Usuario no encontrado' };
    }

    const userData = usuarioDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      console.log(`⚠️ Usuario ${userId} no tiene FCM token registrado`);
      return { success: false, error: 'Usuario sin token FCM' };
    }

    console.log(`🔑 Token encontrado para usuario ${userId}`);

    // Construir payload de notificación
    const message = {
      token: fcmToken,
      notification: {
        title: '⚠️ Pago Rechazado',
        body: `Tu pago del asiento ${asiento} fue rechazado. Motivo: ${motivo}`,
      },
      data: {
        tipo: 'compra_rechazada',
        reservaId: reservaId,
        busId: busId,
        asiento: asiento.toString(),
        motivo: motivo,
        nombreComprador: nombreComprador || '',
        timestamp: Date.now().toString(),
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        accion: 'ver_reservas',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'compras_channel',
          sound: 'default',
          color: '#EF4444',
          icon: '@mipmap/ic_launcher',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            contentAvailable: true,
          },
        },
      },
    };

    // Enviar notificación
    const response = await admin.messaging().send(message);
    console.log('✅ Notificación de rechazo enviada:', response);

    // Guardar en historial
    await db.collection('notificaciones').add({
      usuarioId: userId,
      titulo: '⚠️ Pago Rechazado',
      mensaje: `Tu pago del asiento ${asiento} fue rechazado. Motivo: ${motivo}`,
      tipo: 'compra_rechazada',
      reservaId: reservaId,
      busId: busId,
      enviada: true,
      fechaEnvio: admin.firestore.FieldValue.serverTimestamp(),
      messageId: response,
      data: {
        asiento: asiento,
        motivo: motivo,
      }
    });

    return { success: true, messageId: response };

  } catch (error) {
    console.error('❌ Error al enviar notificación de rechazo:', error);
    
    // Guardar error en historial
    if (data.userId) {
      await db.collection('notificaciones').add({
        usuarioId: data.userId,
        titulo: '⚠️ Pago Rechazado',
        tipo: 'compra_rechazada',
        reservaId: data.reservaId,
        enviada: false,
        error: error.message,
        errorCode: error.code,
        fechaIntento: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return { success: false, error: error.message };
  }
});

// ==================== NOTIFICACIÓN DE PRUEBA ====================
exports.enviarNotificacionPrueba = functions.https.onCall(async (data, context) => {
  try {
    const { userId } = data;

    if (!userId) {
      throw new functions.https.HttpsError('invalid-argument', 'userId es requerido');
    }

    console.log(`🧪 Enviando notificación de prueba a userId: ${userId}`);

    const usuarioDoc = await db.collection('usuarios').doc(userId).get();

    if (!usuarioDoc.exists) {
      return { success: false, error: 'Usuario no encontrado' };
    }

    const userData = usuarioDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      return { success: false, error: 'Usuario sin token FCM' };
    }

    const message = {
      token: fcmToken,
      notification: {
        title: '🔔 Notificación de Prueba',
        body: 'Si ves esto, ¡las notificaciones funcionan correctamente! 🎉',
      },
      data: {
        tipo: 'prueba',
        timestamp: Date.now().toString(),
        es_prueba: 'true',
      },
    };

    const response = await admin.messaging().send(message);
    console.log('✅ Notificación de prueba enviada:', response);

    return { success: true, messageId: response };

  } catch (error) {
    console.error('❌ Error al enviar notificación de prueba:', error);
    return { success: false, error: error.message };
  }
});

console.log('🚀 Cloud Functions inicializadas correctamente');
console.log('📱 Funciones disponibles:');
console.log('   - notificarAprobacion');
console.log('   - notificarRechazo');
console.log('   - enviarNotificacionPrueba');