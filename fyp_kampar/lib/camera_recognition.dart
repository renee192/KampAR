//camera
import 'dart:async';
import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

class CameraRecognition extends StatefulWidget {
  final String place;
  final String title;
  const CameraRecognition({
    super.key,
    required this.title,
    required this.place,
  });

  @override
  State<CameraRecognition> createState() => _CameraRecognitionState();
}

class _CameraRecognitionState extends State<CameraRecognition> {
  CameraController? _controller;
  Timer? _timer;
  bool _isCameraInitialized = false;
  String? _prediction;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (await Permission.camera.request().isGranted) {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );

      _controller = CameraController(backCamera, ResolutionPreset.max);
      await _controller!.initialize();

      if (mounted) {
        setState(() => _isCameraInitialized = true);
        _startFrameCapture();
      }
    } else {
      _showPermissionDeniedDialog();
    }
  }

  void _startFrameCapture() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_controller != null && _controller!.value.isInitialized) {
        final picture = await _controller!.takePicture();
        final result = await _sendFrameToBackend(
          File(picture.path),
          widget.place,
        );

        setState(() => _prediction = result ?? "No prediction");
      }
    });
  }

  Future<String?> _sendFrameToBackend(File imageFile, String place) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.144.50.76:8000/predict'),
    );
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );
    request.fields['place'] = place; // tell backend which location

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        log("Prediction JSON: $responseBody", name: "KampAR");
        
        try {
          final converted = jsonDecode(responseBody) as Map<String, dynamic>;
          return converted['predicted'] as String?;
        } catch(e){
          log("JSON decode error: $e", name:"KampAR");
          return null;
        }
        
      } else {
        log("Error: ${response.statusCode}", name: "KampAR");
        return null;
      }
    } catch (e) {
      log("Exception: $e", name: "KampAR");
      return null;
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Permission Denied"),
        content: const Text("Camera access is required to use this feature."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 189, 227, 245),
      ),
      body: Stack(
        children: [
          // Camera preview fills screen
          if (_isCameraInitialized)
            SizedBox.expand(child: CameraPreview(_controller!))
          else
            const Center(child: CircularProgressIndicator()),

          // Prediction overlay
          if (_prediction != null)
            Positioned(
              bottom: 80,
              left: 20,
              right: 20,
              child: Text(
                _prediction!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  backgroundColor: Color.fromARGB(153, 141, 140, 140),
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
