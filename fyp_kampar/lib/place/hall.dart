//grand hall page
import 'package:flutter/material.dart';
import '../camera_recognition.dart';

class HallPage extends StatelessWidget {
  const HallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CameraRecognition(
      title: "UTAR Grand Hall",    
      place: "hall",
    );
  }
}
