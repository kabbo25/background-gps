import 'dart:developer' as developer;

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fcm_demo/current_location.dart';
import 'package:fcm_demo/network_utils.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<bool> triggerButton() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('button_triggered', true);
  return true;
}

@pragma('vm:entry-point')
Future<void> validateOfficePresence() async {
  developer.log('Validating office presence');
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('attempt', true);
  final connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult[0] == ConnectivityResult.wifi) {
    try {
      final response = await http
          .post(
            Uri.parse('http://10.0.0.137:8080/api/v1/main/success'),
          )
          .timeout(const Duration(seconds: 2));
      if (response.statusCode == 201) {
        String? wifiName = await NetworkUtils.initNetworkInfo();
        // Store the successful validation result

        await prefs.setBool('office_validated', true);
        await prefs.setString('office_wifi_name', wifiName ?? 'Unknown');
      } else {
        // Store the failed validation result
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('office_validated', false);
      }
    } catch (e) {
      // Store the failed validation result due to error
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('office_validated', false);
    }
  } else {
    developer.log('try to find locations');

    String address = await Locationservices.checkLocation();
    bool isInsideOffice =
        !address.contains("You are outside the office premises");
    if (isInsideOffice) {
      await prefs.setBool('office_validated', true);
    } else {
      await prefs.setBool('office_validated', false);
    }
    developer.log(address);
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  developer.log("Handling a background message: ${message.messageId}");
  if (message.data['action'] == 'trigger_button') {
    await triggerButton();
  } else if (message.data['action'] == 'trigger_office') {
    // Schedule the validation to run immediately
    await AndroidAlarmManager.oneShot(
      const Duration(seconds: 0),
      // Ensure this ID is unique
      1,
      validateOfficePresence,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await AndroidAlarmManager.initialize();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
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
  bool _buttonTriggered = false;
  bool _officeValidated = false;
  String _officeWifiName = '';

  @override
  void initState() {
    super.initState();
    setupFCM();
    checkButtonStatus();
    checkValidationResult();
    checkAlarmPermission();
  }

  Future<void> checkAlarmPermission() async {
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  Future<void> setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    developer.log('FCM Token: $token');
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      developer.log('User granted permission');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        developer.log("Received a foreground message: ${message.messageId}");

        handlePushNotification(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        developer.log("Opened app from notification: ${message.messageId}");

        checkValidationResult();
      });
    } else {
      developer.log('User declined or has not accepted permission');
    }
  }

  void handlePushNotification(RemoteMessage message) async {
    developer.log(message.data.toString());
    if (message.data['action'] == 'trigger_button') {
      bool triggered = false;
      if (await Permission.scheduleExactAlarm.isGranted) {
        triggered = await AndroidAlarmManager.oneShot(
          const Duration(seconds: 0),
          0,
          triggerButton,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
        );
      } else {
        developer.log('permission not granted');
        // If permission is not granted, trigger the button directly
        triggered = await triggerButton();
      }
      if (triggered) {
        setState(() {
          _buttonTriggered = true;
        });
      }
    } else if (message.data['action'] == 'trigger_office') {
      if (await Permission.scheduleExactAlarm.isGranted) {
        await AndroidAlarmManager.oneShot(
          const Duration(seconds: 0),
          1,
          validateOfficePresence,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
        );
        await Future.delayed(const Duration(seconds: 6));
      } else {
        developer.log('permission not granted');
        // If permission is not granted, validate office presence directly
        await validateOfficePresence();
      }
      checkValidationResult();
    }
  }

  Future<void> checkButtonStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _buttonTriggered = prefs.getBool('button_triggered') ?? false;
    });
  }

  Future<void> checkValidationResult() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    bool wasAtempted = prefs.getBool('attempt') ?? false;
    if (wasAtempted) {
      bool wasValidated = prefs.getBool('office_validated') ?? false;
      String wifiName = prefs.getString('office_wifi_name') ?? 'Unknown';
      developer.log('validated or not');
      developer.log(wasValidated.toString());
      setState(() {
        _officeValidated = wasValidated;
        _officeWifiName = wifiName;
      });

      if (wasValidated) {
        showConnectedModal(context, wifiName);
      } else {
        showNotConnectedModal(context, handleOfficeButtonPress);
      }

      // Clear the stored results after checking
      await prefs.remove('office_validated');
      await prefs.remove('office_wifi_name');
      await prefs.remove('attempt');
    }
  }

  void showConnectedModal(BuildContext context, String wifiName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Connected to Office'),
          content: Text('You are connected to the office WiFi: $wifiName'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showNotConnectedModal(BuildContext context, VoidCallback onRetry) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Not Connected to Office'),
          content: const Text('You are not connected to the office WiFi.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Retry'),
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void handleOfficeButtonPress() async {
    await validateOfficePresence();
    checkValidationResult();
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
            Text(
              _buttonTriggered
                  ? 'Button was triggered by push notification!'
                  : 'Waiting for push notification...',
            ),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('button_triggered', false);
                checkButtonStatus();
              },
              child: const Text('Reset Button'),
            ),
            const SizedBox(height: 20),
            Text(
              _officeValidated
                  ? 'Connected to office WiFi: $_officeWifiName'
                  : 'Not connected to office WiFi',
            ),
            ElevatedButton(
              onPressed: handleOfficeButtonPress,
              child: const Text('Check Office Connection'),
            ),
          ],
        ),
      ),
    );
  }
}
