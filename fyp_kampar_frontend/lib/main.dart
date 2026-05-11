import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; 
import 'dart:developer';
import 'home.dart';
import 'onboarding.dart';

void pingBackendSilently() {
  final url = Uri.parse('https://kampar-backend-830798580425.asia-southeast1.run.app/status');
  
  http.get(url).then((response) {
    if (response.statusCode == 200) {
      log("Wake-Up Successful: Server is warming up!");
    }
  }).catchError((error) {
    log("Wake-Up failed (probably poor internet, ignoring...): $error");
  });
}

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  pingBackendSilently();

  final prefs = await SharedPreferences.getInstance();

  // FOR DEBUG: This deletes the 'showHome' save file every time the app starts
  //await prefs.remove('showHome');

  // Check if 'showHome' exists. If it not exist first launch, it defaults to false.
  final showHome = prefs.getBool('showHome') ?? false;

  runApp(MainApp(showHome: showHome));
}

class MainApp extends StatelessWidget {
  final bool showHome;
  const MainApp({super.key, required this.showHome});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KampAR',
      initialRoute: showHome ? '/home' : '/first_launch',

      routes: {
        '/home': (context) => const HomePage(),
        '/first_launch': (context) => const OnboardingPage(), 
      },
    );
  }
}
