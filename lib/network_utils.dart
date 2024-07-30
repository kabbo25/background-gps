import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class NetworkUtils {
  static final NetworkInfo _networkInfo = NetworkInfo();

  static Future<String?> initNetworkInfo() async {
    // ... (implementation of _initNetworkInfo method)
    String? wifiName;

    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // Request permissions as recommended by the plugin documentation:
        // https://github.com/fluttercommunity/plus_plugins/tree/main/packages/network_info_plus/network_info_plus
        if (await Permission.locationWhenInUse.request().isGranted) {
          wifiName = await _networkInfo.getWifiName();
        } else {
          wifiName = 'Unauthorized to get Wifi Name';
        }
      } else {
        wifiName = await _networkInfo.getWifiName();
      }
    } on PlatformException catch (e) {
      developer.log('Failed to get Wifi Name', error: e);
      wifiName = 'Failed to get Wifi Name';
    }

    // try {
    //   if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    //     // Request permissions as recommended by the plugin documentation:
    //     // https://github.com/fluttercommunity/plus_plugins/tree/main/packages/network_info_plus/network_info_plus
    //     if (await Permission.locationWhenInUse.request().isGranted) {
    //       wifiBSSID = await _networkInfo.getWifiBSSID();
    //     } else {
    //       wifiBSSID = 'Unauthorized to get Wifi BSSID';
    //     }
    //   } else {
    //     wifiName = await _networkInfo.getWifiName();
    //   }
    // } on PlatformException catch (e) {
    //   developer.log('Failed to get Wifi BSSID', error: e);
    //   wifiBSSID = 'Failed to get Wifi BSSID';
    // }
    //
    // try {
    //   wifiIPv4 = await _networkInfo.getWifiIP();
    // } on PlatformException catch (e) {
    //   developer.log('Failed to get Wifi IPv4', error: e);
    //   wifiIPv4 = 'Failed to get Wifi IPv4';
    // }
    //
    // try {
    //   wifiIPv6 = await _networkInfo.getWifiIPv6();
    // } on PlatformException catch (e) {
    //   developer.log('Failed to get Wifi IPv6', error: e);
    //   wifiIPv6 = 'Failed to get Wifi IPv6';
    // }
    //
    // try {
    //   wifiSubmask = await _networkInfo.getWifiSubmask();
    // } on PlatformException catch (e) {
    //   developer.log('Failed to get Wifi submask address', error: e);
    //   wifiSubmask = 'Failed to get Wifi submask address';
    // }
    //
    // try {
    //   wifiBroadcast = await _networkInfo.getWifiBroadcast();
    // } on PlatformException catch (e) {
    //   developer.log('Failed to get Wifi broadcast', error: e);
    //   wifiBroadcast = 'Failed to get Wifi broadcast';
    // }
    //
    // try {
    //   wifiGatewayIP = await _networkInfo.getWifiGatewayIP();
    // } on PlatformException catch (e) {
    //   developer.log('Failed to get Wifi gateway address', error: e);
    //   wifiGatewayIP = 'Failed to get Wifi gateway address';
    // }

    return '''
      $wifiName
    ''';
  }
}
