import 'package:flutter/material.dart';
import 'package:faustina/screens/home_page.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // no SQLite on web
  } else if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {

    // --- DESKTOP ---
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

  } else {
    // --- MOBILE (Android / iOS) ---
    // sqflite initializes automatically; no setup needed
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false, 
    );
  }
}