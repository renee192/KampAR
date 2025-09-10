//homepage
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget{
  const HomePage({super.key});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 207, 233, 255),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'KampAR',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 60),
              Text(
                'Welcome!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Choose the place you at:', style: TextStyle(fontSize: 14)),
              SizedBox(height: 60),
              PlaceButton(
                label: 'UTAR Grand Hall',
                onPressed: () => Navigator.pushNamed(context, '/hall'),
              ),
              SizedBox(height: 25),
              PlaceButton(
                label: 'Kampar Chinese Temple',
                onPressed: () => Navigator.pushNamed(context, '/temple'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlaceButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const PlaceButton({
    super.key,
    required this.label,r,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          foregroundColor: const Color.fromARGB(255, 255, 255, 255),
          overlayColor: Colors.white.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: onPressed,
        child: Text(label, style: TextStyle(color: Colors.white, fontSize: 14)),
      ),
    );
  }
}