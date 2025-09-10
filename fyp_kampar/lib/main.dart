//app setup, routes
import 'package:flutter/material.dart';
import 'home.dart';
import 'place/hall.dart';
import 'place/temple.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KampAR',
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/hall': (context) => const HallPage(),
        '/temple': (context) => const TemplePage(),
      },
    );
  }
}
