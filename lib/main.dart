import 'dart:typed_data';
import 'package:app2tesis/usuario/Pantallas_inicio/menu.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'tema.dart';
import 'usuario/Pantallas_inicio/iniciarsesion.dart';

// ==================== NOTIFICACIONES ====================
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await showLocalNotification(message);
  debugPrint('🔔 Notificación en segundo plano: ${message.messageId}');
}

Future<void> showLocalNotification(RemoteMessage message) async {
  final notification = message.notification;
  final data = message.data;

  if (notification == null) return;

  final androidDetails = AndroidNotificationDetails(
    'general_channel',
    'Notificaciones',
    channelDescription: 'Canal para notificaciones generales de la app',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
    icon: '@mipmap/ic_launcher',
    // Agregar un color de acento para Android
    color: Colors.blue,
    // Permitir expandir la notificación
    styleInformation: BigTextStyleInformation(
      notification.body ?? '',
      contentTitle: notification.title,
    ),
  );

  final iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    // Agregar categorías si las usas
    threadIdentifier: 'general',
  );

  await flutterLocalNotificationsPlugin.show(
    notification.hashCode,
    notification.title,
    notification.body,
    NotificationDetails(android: androidDetails, iOS: iosDetails),
    // Payload para manejar la interacción
    payload: data['route'] ?? data['screen'] ?? '',
  );
}

// ==================== MAIN ====================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('es', null);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await requestPermissions();
  await initializeLocalNotifications();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

// ==================== PERMISOS ====================
Future<void> requestPermissions() async {
  // Solicitar permisos de notificación del sistema
  final notificationStatus = await Permission.notification.request();
  debugPrint('📱 Permiso de notificaciones: $notificationStatus');

  // Solicitar permisos de FCM
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    announcement: false,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
  );

  debugPrint('🔔 Permisos FCM: ${settings.authorizationStatus}');

  // Configurar opciones de presentación para iOS
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
}

// ==================== NOTIFICACIONES LOCALES ====================
Future<void> initializeLocalNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    ),
    // Manejar cuando el usuario toca la notificación
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload != null && response.payload!.isNotEmpty) {
        debugPrint(
            '🔔 Usuario tocó notificación con payload: ${response.payload}');
        // Aquí puedes navegar a una pantalla específica
        // navigatorKey.currentState?.pushNamed(response.payload!);
      }
    },
  );

  // Crear canal de notificaciones para Android
  final androidPlugin =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      'general_channel',
      'Notificaciones',
      description: 'Canal para notificaciones generales de la app',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ),
  );

  // Canal adicional para notificaciones importantes
  await androidPlugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      'important_channel',
      'Notificaciones Importantes',
      description: 'Canal para notificaciones prioritarias',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    ),
  );
}

// ==================== VALIDACIÓN DE VERSIÓN ====================
class AppVersionService {
  static bool _isCheckingVersion = false;

  static Future<void> checkVersion(BuildContext context) async {
    if (_isCheckingVersion) return;
    _isCheckingVersion = true;

    try {
      final info = await PackageInfo.fromPlatform();
      final localVersion = info.version;

      final doc = await FirebaseFirestore.instance
          .collection('configuracion')
          .doc('app_update')
          .get();

      if (!doc.exists || !context.mounted) {
        _isCheckingVersion = false;
        return;
      }

      final data = doc.data()!;
      final minVersion = data['versionMinima'] as String?;
      final obligatorio = data['obligatorio'] as bool? ?? false;
      final urlAPK = data['urlAPK'] as String?;

      if (minVersion == null || urlAPK == null) {
        _isCheckingVersion = false;
        return;
      }

      if (isLower(localVersion, minVersion)) {
        if (!context.mounted) {
          _isCheckingVersion = false;
          return;
        }

        showDialog(
          context: context,
          barrierDismissible:
              !obligatorio, // Solo se puede cerrar si no es obligatorio
          builder: (_) => PopScope(
            canPop:
                !obligatorio, // Solo se puede cerrar con back si no es obligatorio
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.system_update,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      obligatorio
                          ? 'Actualización Requerida'
                          : 'Actualización Disponible',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    obligatorio
                        ? 'Para continuar usando la aplicación, necesitas actualizar a la versión $minVersion.'
                        : 'Hay una nueva versión $minVersion disponible. Te recomendamos actualizar para obtener las últimas mejoras.',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Versión actual',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                localVersion,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward,
                          color: Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                obligatorio
                                    ? 'Versión requerida'
                                    : 'Nueva versión',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                minVersion,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                // Botón de Descargar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(urlAPK);

                      if (!await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      )) {
                        debugPrint('No se pudo abrir la URL');
                      }
                    },
                    icon: const Icon(Icons.download, size: 20),
                    label: const Text(
                      'Descargar Actualización',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                // Botón Omitir - Solo visible cuando NO es obligatorio
                if (!obligatorio) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Omitir por ahora',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al verificar versión: $e');
    } finally {
      _isCheckingVersion = false;
    }
  }

  static bool isLower(String current, String minimum) {
    try {
      final c = current.split('.').map(int.parse).toList();
      final m = minimum.split('.').map(int.parse).toList();

      for (int i = 0; i < m.length; i++) {
        if (c.length <= i || c[i] < m[i]) return true;
        if (c[i] > m[i]) return false;
      }
      return false;
    } catch (e) {
      debugPrint('Error al comparar versiones: $e');
      return false;
    }
  }
}

// ==================== GUARDAR TOKEN ====================
Future<void> saveFCMToken() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('⚠️ No hay usuario logueado, no se guarda token');
      return;
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      debugPrint('⚠️ No se pudo obtener el token FCM');
      return;
    }

    debugPrint('✅ Token FCM obtenido: ${token.substring(0, 20)}...');

    await FirebaseFirestore.instance
        .collection('usuarios_registrados')
        .doc(user.uid)
        .set({
      'email': user.email,
      'fcmToken': token,
      'lastTokenUpdate': FieldValue.serverTimestamp(),
      'platform': Theme.of(WidgetsBinding
              .instance.platformDispatcher.views.first as BuildContext)
          .platform
          .toString(),
    }, SetOptions(merge: true));

    debugPrint('✅ Token FCM guardado en Firestore');

    // Escuchar cuando el token se refresca
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 Token FCM actualizado');
      FirebaseFirestore.instance
          .collection('usuarios_registrados')
          .doc(user.uid)
          .update({
        'fcmToken': newToken,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    });
  } catch (e) {
    debugPrint('❌ Error al guardar token FCM: $e');
  }
}

// ==================== SUSCRIBIR A TÓPICOS ====================
Future<void> subscribeToTopics() async {
  try {
    // Suscribirse a un tópico general
    await FirebaseMessaging.instance.subscribeToTopic('todos');
    debugPrint('✅ Suscrito al tópico: todos');

    // Puedes suscribirte a más tópicos según tu app
    // await FirebaseMessaging.instance.subscribeToTopic('ofertas');
    // await FirebaseMessaging.instance.subscribeToTopic('noticias');
  } catch (e) {
    debugPrint('❌ Error al suscribirse a tópicos: $e');
  }
}

// ==================== APP ====================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (_, theme, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: theme.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              secondary: Colors.blueAccent,
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            primaryColor: Colors.blue,
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              secondary: Colors.blueAccent,
            ),
          ),
          home: const AppInitializer(),
        );
      },
    );
  }
}

// ==================== APP INITIALIZER ====================
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Verificar versión de la app
      await AppVersionService.checkVersion(context);

      // Guardar token si hay usuario logueado
      await saveFCMToken();

      // Suscribirse a tópicos generales
      await subscribeToTopics();

      // Manejar notificación que abrió la app (cuando estaba cerrada)
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
            '🔔 App abierta desde notificación: ${initialMessage.messageId}');
        _handleNotificationNavigation(initialMessage.data);
      }

      // Manejar notificación cuando la app está en segundo plano
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🔔 App abierta desde segundo plano: ${message.messageId}');
        _handleNotificationNavigation(message.data);
      });
    });

    // Escuchar notificaciones en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 Notificación recibida en primer plano');
      showLocalNotification(message);
    });
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    // Aquí puedes navegar a pantallas específicas según el payload
    final route = data['route'] ?? data['screen'];
    if (route != null && route.isNotEmpty) {
      debugPrint('📍 Navegando a: $route');
      // Navigator.of(context).pushNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}
