import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

const platform = MethodChannel('com.example.fcm_demo/locationService');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Set up the background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Set up foreground message handler
  FirebaseMessaging.onMessage.listen(_handleMessage);

  // Handle notification when the app is opened from the background
  FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

  // Get the FCM token and send it to the backend
  String? token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    print('FCM Token: $token');
    await postDeviceToken(token, 1245); // Replace 1234 with actual employee ID
  }

  runApp(MyApp());
}

Future<void> postDeviceToken(String deviceToken, int employeeId) async {
  // Replace with your computer's local IP address
  const String url = 'http://192.168.0.6:8080/api/device-token';
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
      print('Device token posted successfully');
    } else {
      print(
          'Failed to post device token. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  } catch (e) {
    developer.log('Error posting device token: $e');
  }
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  //await _startForegroundService();
  print('Handling a background message: ${message.messageId}');
  // Handle background notifications, e.g., start the service
}

// Foreground message handler
Future<void> _handleMessage(RemoteMessage message) async{
  //await _startForegroundService();
  print('Handling a foreground message: ${message.messageId}');
  // Handle foreground notifications, e.g., start or stop the service based on the action
  // if (message.data['action'] == 'start') {
  //   _startForegroundService();
  // } else if (message.data['action'] == 'stop') {
  //   _stopForegroundService();
  // }
}

// Handle notification when the app is opened from the background
Future<void> _handleMessageOpenedApp(RemoteMessage message) async{
  //await _startForegroundService();
  print('Handling a notification opened from background: ${message.messageId}');
  // Handle notification opened, e.g., navigate to a specific screen or start/stop the service
}

Future<void> _startForegroundService() async {
  try {
    //await platform.invokeMethod('startForegroundService');
    await platform.invokeMethod('sendBroadcast', {'action': 'START_FOREGROUND_SERVICE'});

  } on PlatformException catch (e) {
    print("Failed to start foreground service: '${e.message}'.");
  }
}

Future<void> _stopForegroundService() async {
  try {
    //await platform.invokeMethod('stopForegroundService');
    await platform.invokeMethod('sendBroadcast', {'action': 'STOP_FOREGROUND_SERVICE'});

  } on PlatformException catch (e) {
    print("Failed to stop foreground service: '${e.message}'.");
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Foreground Service Example'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _startForegroundService,
                child: Text('Start Location Service'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _stopForegroundService,
                child: Text('Stop Location Service'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}