import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:geolocator/geolocator.dart';

// This is the entry point for the overlay
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(OverlayWidget());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // Show overlay with location
  await FlutterOverlayWindow.showOverlay(
    height: 2000,
    width: 1000,
    enableDrag: true,
    flag: OverlayFlag.defaultFlag,
    alignment: OverlayAlignment.center,
    visibility: NotificationVisibility.visibilityPublic,
    positionGravity: PositionGravity.auto,
    overlayTitle: "Current Location",
  );

  // Fetch location when notification is received in background
  final location = await _getLocationString();
  developer.log('Background Location: $location');

  /// broadcast data to and from overlay app
  await FlutterOverlayWindow.shareData(location);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request overlay permission
  bool? status = await FlutterOverlayWindow.isPermissionGranted();
  developer.log('Overlay permission status: $status');
  if (status != true) {
    await FlutterOverlayWindow.requestPermission();
  }

  // Get and log FCM token
  String? token = await FirebaseMessaging.instance.getToken();
  developer.log('FCM Token: $token');

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const platform = MethodChannel('com.yourapp/location');
  String _location = 'Unknown';

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    platform.setMethodCallHandler(_handleMethod);
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      setState(() {
        _location = 'Location services are disabled';
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permission denied
        setState(() {
          _location = 'Location permissions are denied';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever
      setState(() {
        _location = 'Location permissions are permanently denied';
      });
      return;
    }

    // Permission granted, proceed with location fetching
    _getLocation();
  }

  Future<void> _getLocation() async {
    developer.log('Fetching location...');
    try {
      final String result = await platform.invokeMethod('getLocation');
      setState(() {
        _location = result;
      });
      developer.log(result);
    } on PlatformException catch (e) {
      developer.log("Failed to get location: '${e.message}'.");
      setState(() {
        _location = "Failed to get location: '${e.message}'.";
      });
    } on MissingPluginException catch (e) {
      developer.log("Plugin not available: ${e.message}");
      setState(() {
        _location = "Plugin not available: ${e.message}";
      });
    }
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    developer.log('Method ${call.method} called');
    switch (call.method) {
      case 'updateLocation':
        final double latitude = call.arguments['latitude'];
        final double longitude = call.arguments['longitude'];
        developer.log('Location updated: $latitude, $longitude');
        setState(() {
          _location = 'Lat: $latitude, Long: $longitude';
        });
        break;
      default:
        developer.log('No such method ${call.method}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Location on Push Notification')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Current Location: $_location'),
              ElevatedButton(
                onPressed: _getLocation,
                child: Text('Refresh Location'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OverlayWidget extends StatefulWidget {
  @override
  _OverlayWidgetState createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> {
  String _location = 'Fetching location...';

  @override
  void initState() {
    super.initState();
    _listenToOverlayData();
  }

  void _listenToOverlayData() {
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data != null && data is String) {
        setState(() {
          _location = data;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.8),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Current Location',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  _location,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  child: Text('Close'),
                  onPressed: () {
                    FlutterOverlayWindow.closeOverlay();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper function to get location as a string
Future<String> _getLocationString() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return 'Location services are disabled';
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return 'Location permissions are denied';
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return 'Location permissions are permanently denied';
  }

  Position position = await Geolocator.getCurrentPosition();
  return 'Lat: ${position.latitude}, Long: ${position.longitude}';
}
