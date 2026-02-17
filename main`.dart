import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// ⚠️ Do NOT include your firebase_options.dart in GitHub, replace with your own locally
// import 'firebase_options.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initLocalNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings settings = InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(settings);
}

// ---------------- Background Message Handler ----------------
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
      // ⚠️ Use your own Firebase options locally
      // options: DefaultFirebaseOptions.currentPlatform
  );

  print("📩 Background message: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      // ⚠️ Use your own Firebase options locally
      // options: DefaultFirebaseOptions.currentPlatform
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ⚠️ Subscribe to topic locally
  await FirebaseMessaging.instance.subscribeToTopic("oxygen_alerts");
  print("✅ Subscribed to oxygen_alerts");

  // ⚠️ Print token locally
  String? token = await FirebaseMessaging.instance.getToken();
  print("FCM Token: $token");

  runApp(const MyApp());
}

// ⚠️ Replace with your backend IP locally when running the app
const String backendIp = "YOUR_BACKEND_IP";
const int backendPort = 5000;
final String backendBase = "http://$backendIp:$backendPort";

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize local notifications
    initLocalNotifications();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message: ${message.notification?.title}');
      if (message.notification != null) {
        flutterLocalNotificationsPlugin.show(
          0,
          message.notification!.title,
          message.notification!.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'foreground_channel',
              'Foreground Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    return MaterialApp(home: const HomeMenu());
  }
}

// ---------------- HOME MENU ----------------
class HomeMenu extends StatefulWidget {
  const HomeMenu({super.key});

  @override
  State<HomeMenu> createState() => _HomeMenuState();
}

class _HomeMenuState extends State<HomeMenu> {
  @override
  void initState() {
    super.initState();

    FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.instance.getToken().then((token) {
      print("FCM Token: $token");
    });

    FirebaseMessaging.instance.subscribeToTopic("oxygen_alerts").then((_) {
      print("Subscribed to oxygen_alerts topic ✅");
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("📬 ${message.notification!.title ?? "New Notification"}"),
          ),
        );
      }
    });
  }

  Future<bool> _checkServer(BuildContext context) async {
    try {
      final uri = Uri.parse("$backendBase/");
      final res = await http.get(uri).timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server unavailable. Please check server.'),
          ),
        );
      }
      return false;
    }
  }

  void _openRegister(BuildContext context) async {
    if (!await _checkServer(context)) return;
    if (!context.mounted) return;
    // Navigate to Register page
  }

  void _openRecognize(BuildContext context) async {
    if (!await _checkServer(context)) return;
    if (!context.mounted) return;
    // Navigate to Recognize page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Home Security',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () => _openRegister(context),
                child: const Text('Register'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _openRecognize(context),
                child: const Text('Login'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => exit(0),
                child: const Text('Exit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
