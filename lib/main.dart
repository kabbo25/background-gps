import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:fcm_demo/current_location.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  developer.log("Handling a background message: ${message.messageId}");
  await showFullScreenNotification(message);
  //await initializeService();
  // if (message.data['action'] == 'trigger_office') {
  //   developer.log('Triggering office check');
  //   final prefs = await SharedPreferences.getInstance();
  //   double? latitude = prefs.getDouble('last_latitude');
  //   double? longitude = prefs.getDouble('last_longitude');

  //   developer
  //       .log("Location not available. Attempting to get current position...");
  //   try {
  //     Position position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high,
  //     ).timeout(const Duration(seconds: 1), onTimeout: () {
  //       throw TimeoutException('Location retrieval timed out');
  //     });
  //     latitude = position.latitude;
  //     longitude = position.longitude;
  //     developer.log("Current position: lat=$latitude, long=$longitude");
  //     // Save this position to SharedPreferences
  //     await prefs.setDouble('last_latitude', 0);
  //     await prefs.setDouble('last_longitude', 0);
  //   } catch (e) {
  //     String address = prefs.getString('office_address') ?? 'un';
  //     developer.log('Retrieved from SharedPreferences: $address');
  //     developer.log("Error getting current position: $e");
  //   }
  // }
}

// Future<bool> _handleLocationPermission() async {
//   bool serviceEnabled;
//   LocationPermission permission;

//   serviceEnabled = await Geolocator.isLocationServiceEnabled();
//   if (!serviceEnabled) {
//     developer.log('Location services are disabled.');
//     return false;
//   }

//   permission = await Geolocator.checkPermission();
//   if (permission == LocationPermission.denied) {
//     permission = await Geolocator.requestPermission();
//     if (permission == LocationPermission.denied) {
//       developer.log('Location permissions are denied');
//       return false;
//     }
//   }

//   if (permission == LocationPermission.deniedForever) {
//     developer.log('Location permissions are permanently denied');
//     return false;
//   }

//   return true;
// }

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'AWESOME SERVICE',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  await service.startService();
}
// Future<void> startForegroundService() async {
//   final service = FlutterBackgroundService();
//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: true,
//       isForegroundMode: true,
//       notificationChannelId: 'my_foreground',
//       initialNotificationTitle: 'AWESOME SERVICE',
//       initialNotificationContent: 'Initializing',
//       foregroundServiceNotificationId: 888,
//     ),
//     iosConfiguration: IosConfiguration(
//       autoStart: true,
//       onForeground: onStart,
//       onBackground: onIosBackground,
//     ),
//   );

//   await service.startService();
// }

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // // Start foreground service immediately
  // service.on('setAsForeground').listen((event) {
  //   service.setAsForegroundService();
  // });
  // service.invoke('setAsForeground');

  developer.log('Location service started');
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize notification channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'location_service_channel',
    'Location Service Notifications',
    description: 'This channel is used for location service notifications.',
    importance: Importance.low,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  const locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );

  StreamSubscription<Position>? positionStream;

  positionStream =
      Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen((Position position) async {
    String address = await Locationservices.getAddress(
        position.latitude, position.longitude);
    bool isInsideOffice =
        !address.contains("You are outside the office premises");
    developer.log('inside office: $isInsideOffice');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('office_validated', isInsideOffice);
    await prefs.setString('office_address', address);
    developer.log('office address: $address');

    service.invoke(
      'update',
      {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'isInsideOffice': isInsideOffice,
      },
    );
  });

  // Stop the service after 2 minutes
  Timer(const Duration(minutes: 2), () async {
    await positionStream?.cancel();
    developer.log('Location service stopped after 2 minutes');
    service.stopSelf();
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

Future<void> showFullScreenNotification(RemoteMessage message) async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Create a high-priority notification channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'full_screen_channel',
    'Full Screen Notifications',
    description: 'Notifications that appear as full-screen alerts',
    importance: Importance.max,
    playSound: true,
    showBadge: true,
    enableVibration: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Initialize the plugin
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Configure the notification
  final AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    channel.id,
    channel.name,
    channelDescription: channel.description,
    importance: Importance.max,
    priority: Priority.max,
    fullScreenIntent: true,
    ticker: 'ticker',
    category: AndroidNotificationCategory.call, // Use call category
    visibility: NotificationVisibility.public,
  );

  final NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  // Show the notification
  await flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title ?? 'Incoming Call',
    message.notification?.body ?? 'Someone is calling you',
    platformChannelSpecifics,
    payload: 'item x',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  //await initializeService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'FCM Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String currentAddress = 'Unknown';

  @override
  void initState() {
    super.initState();
    setupFCM();
    _loadCurrentAddress();
    // _requestOverlayPermission();
  }

  Future<void> _loadCurrentAddress() async {
    String address = await Locationservices.checkLocation();
    setState(() {
      currentAddress = address;
    });
  }

  Future<void> _requestOverlayPermission() async {
    if (await Permission.systemAlertWindow.isDenied) {
      await Permission.systemAlertWindow.request();
    }
  }

  Future<void> postDeviceToken(String deviceToken, int employeeId) async {
    // Replace with your computer's local IP address
    const String url = 'http://10.0.3.135:8080/api/device-token';

    final Map<String, dynamic> payload = {
      'deviceToken': deviceToken,
      'employeeId': employeeId,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201) {
        developer.log('Device token posted successfully');
      } else {
        developer.log(
            'Failed to post device token. Status code: ${response.statusCode}');
        developer.log('Response body: ${response.body}');
      }
    } catch (e) {
      developer.log('Error posting device token: $e');
    }
  }

  Future<void> setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String token = await messaging.getToken() ?? 'latest';
    developer.log('FCM Token: $token');
    postDeviceToken(token, 33);
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      developer.log('User granted permission');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        developer.log("Received a foreground message: ${message.messageId}");
        //loadCurrentAddress(); // Reload address when a message is received
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        developer.log("Opened app from notification: ${message.messageId}");
        //loadCurrentAddress(); // Reload address when app is opened from notification
      });
    } else {
      developer.log('User declined or has not accepted permission');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Current Address:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              currentAddress,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: setupFCM,
              child: const Text('Refresh Address'),
            ),
          ],
        ),
      ),
    );
  }
}
