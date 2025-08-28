import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:developer';


Timer? _timer;
CameraController? _controller; // moved here so startFrameCapture can use it

void main() => runApp(MainApp());

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KampAR',
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _navigateTo(BuildContext context, Widget destination) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 207, 233, 255),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'KampAR',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 40),
              Text(
                'Welcome!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Choose the place you at:', style: TextStyle(fontSize: 14)),
              SizedBox(height: 40),
              PlaceButton(
                label: 'UTAR Grand Hall',
                color: Colors.black,
                onPressed: () => _navigateTo(context, GrandHall()),
              ),
              SizedBox(height: 16),
              PlaceButton(
                label: 'Kampar Chinese Temple',
                color: Colors.black,
                onPressed: () {
                  // Add Kampar Chinese Temple page navigation
                },
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
  final Color color;
  final VoidCallback onPressed;

  const PlaceButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: onPressed,
        child: Text(label, style: TextStyle(color: Colors.white, fontSize: 14)),
      ),
    );
  }
}

class GrandHall extends StatefulWidget {
  const GrandHall({super.key});

  @override
  UTARPageState createState() => UTARPageState();
}

class UTARPageState extends State<GrandHall> {
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (await Permission.camera.request().isGranted) {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );

      _controller = CameraController(backCamera, ResolutionPreset.max);
      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        startFrameCapture(); // start sending frames after camera ready
      }
    } else {
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Permission Denied"),
        content: Text("Camera access is required to use this feature."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK"),
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
        title: Text('UTAR Grand Hall'),
        backgroundColor: const Color.fromARGB(255, 35, 97, 142),
      ),
      body: _isCameraInitialized
          ? CameraPreview(_controller!)
          : Center(child: CircularProgressIndicator()),
    );
  }
}

// Sends frames every 2 seconds
void startFrameCapture() {
  _timer = Timer.periodic(Duration(seconds: 2), (timer) async {
    if (_controller != null && _controller!.value.isInitialized) {
      final picture = await _controller!.takePicture();
      await sendFrameToBackend(File(picture.path));
    }
  });
}

Future<void> sendFrameToBackend(File imageFile) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('http://192.168.30.76:8000/predict'), // PC ip
  );
  request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

  try {
    var response = await request.send();
    if (response.statusCode == 200) {
      var responseBody = await response.stream.bytesToString();
      log("Prediction: $responseBody", name: "KampAR");  // use log instead of print
    } else {
      log("Error: ${response.statusCode}", name: "KampAR");
    }
  } catch (e) {
    log("Exception: $e", name: "KampAR");
  }
}

