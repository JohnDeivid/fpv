// settings_manager.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SettingsManager {
  static const String _deviceIdKey = 'device_id';
  static const String _deviceNameKey = 'device_name';
  
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);
    
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
    }
    
    return deviceId;
  }

  static Future<String> getDeviceName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceNameKey) ?? 'My Controller';
  }
  
  static Future<void> setDeviceName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceNameKey, name);
  }

  static const String _use3dModelKey = 'use_3d_model_bg';

  /// Returns whether 3D model is used as background (default is false: uses 12.webp image)
  static Future<bool> getUse3dModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_use3dModelKey) ?? false;
  }

  static Future<void> setUse3dModel(bool use3d) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_use3dModelKey, use3d);
  }

  // Untuk debug/testing
  static Future<void> resetDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
  }
}