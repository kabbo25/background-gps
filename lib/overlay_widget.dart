import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OverlayWidget extends StatefulWidget {
  const OverlayWidget({super.key});

  @override
  _OverlayWidgetState createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> {
  static const platform = MethodChannel('com.yourapp/location');
  String _location = 'Unknown';

  @override
  void initState() {
    super.initState();
    platform.setMethodCallHandler(_handleMethod);
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'updateLocation':
        final double latitude = call.arguments['latitude'];
        final double longitude = call.arguments['longitude'];
        setState(() {
          _location = 'Lat: $latitude, Long: $longitude';
        });
        break;
      default:
        print('No such method ${call.method}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Current Location: $_location'),
              ElevatedButton(
                child: const Text('Open App'),
                onPressed: () {
                  // Close overlay and open main app
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
