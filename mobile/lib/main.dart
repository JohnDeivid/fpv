import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:buana_vpad/database/db_config.dart';
import 'package:buana_vpad/database/db_helper.dart';
import 'package:buana_vpad/screens/homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await initializeDatabase();
  final dbHelper = DatabaseHelper();
  await dbHelper.database;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'FPV Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Color(0xFFB0B0B0),
          surface: Color(0xFF0A0A0A),
          background: Color(0xFF000000),
          onPrimary: Colors.black,
          onSurface: Colors.white,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xE6141414), // Frosted dark translucent
          modalBackgroundColor: Color(0xE6141414),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            side: BorderSide(color: Color(0x33FFFFFF), width: 1),
          ),
        ),
        dialogTheme: DialogTheme(
          backgroundColor: const Color(0xE6161616),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0x33FFFFFF), width: 1),
          ),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
          contentTextStyle: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        scaffoldBackgroundColor: const Color(0xFF000000),
      ),
      home: const HomePage(),
    );
  }
}

