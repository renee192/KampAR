import 'package:flutter/material.dart';
import 'camera_recognition.dart';

class LiveCapturePage extends StatelessWidget {
  final String placeName;
  final String placeId;

  const LiveCapturePage({
    super.key,
    required this.placeName,
    required this.placeId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFA4B5C4),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: Text(
          "Live Capture\n($placeName)",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: "Montserrat-Bold",
            fontSize: 16,
          ),
        ),
      ),

      body: CameraRecognition(placeId: placeId),
    );
  }
}
