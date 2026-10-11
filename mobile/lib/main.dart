import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:buana_vpad/database/db_config.dart';
import 'package:buana_vpad/database/db_helper.dart';
import 'package:buana_vpad/screens/homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        fontFamily: 'SF Pro Display',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D4FF),
          secondary: Color(0xFF0099CC),
          surface: Color(0xFF0A0E17),
          background: Color(0xFF060A12),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF060A12),
      ),
      home: const HomePage(),
    );
  }
}
