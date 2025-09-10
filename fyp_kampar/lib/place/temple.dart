//temple page
import 'package:flutter/material.dart';
import '../camera_recognition.dart';

class TemplePage extends StatelessWidget {
  const TemplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CameraRecognition(
      title: "Kampar Chinese Temple",
      place: "temple",
    );
  }
}
