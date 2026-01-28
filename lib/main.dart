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
}

Future<void> showLocalNotification(RemoteMessage message) async {
  final notification = message.notification;
  if (notification == null) return;

  final androidDetails = AndroidNotificationDetails(
    'general_channel',
    'Notificaciones',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
  );

  final iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  await flutterLocalNotificationsPlugin.show(
    notification.hashCode,
    notification.title,
    notification.body,
    NotificationDetails(android: androidDetails, iOS: iosDetails),
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
  await Permission.notification.request();
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
}

// ==================== NOTIFICACIONES LOCALES ====================
Future<void> initializeLocalNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: androidSettings, iOS: iosSettings),
  );

  final androidPlugin =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      'general_channel',
      'Notificaciones',
      importance: Importance.high,
    ),
  );
}

// ==================== VALIDACIÓN DE VERSIÓN ====================
class AppVersionService {
  static bool _isCheckingVersion = false;

  static Future<void> checkVersion(BuildContext context) async {
    // Evitar múltiples llamadas simultáneas
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

      if (obligatorio && isLower(localVersion, minVersion)) {
        if (!context.mounted) {
          _isCheckingVersion = false;
          return;
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => PopScope(
            canPop: false,
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
                  const Expanded(
                    child: Text(
                      'Actualización Requerida',
                      style: TextStyle(
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
                    'Para continuar usando la aplicación, necesitas actualizar a la versión $minVersion.',
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
                              const Text(
                                'Versión requerida',
                                style: TextStyle(
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
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance
        .collection('usuarios_registrados')
        .doc(user.uid)
        .set({
      'email': user.email,
      'fcmToken': token,
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  } catch (e) {
    debugPrint('Error al guardar token FCM: $e');
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
          // DIRECTO A HomePage - YA NO USAMOS AuthWrapper
          home: const AppInitializer(),
        );
      },
    );
  }
}

// ==================== APP INITIALIZER ====================
// Este widget solo inicializa la app y muestra HomePage
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

    // Esperar a que el widget esté completamente montado
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Verificar versión de la app
      await AppVersionService.checkVersion(context);

      // Guardar token si hay usuario logueado
      await saveFCMToken();
    });

    // Escuchar notificaciones en primer plano
    FirebaseMessaging.onMessage.listen(showLocalNotification);
  }

  @override
  Widget build(BuildContext context) {
    // Importa tu HomePage desde el archivo correcto
    // import 'usuario/Pantallas_inicio/home_page.dart' o donde esté
    return const HomePage();
  }
}
