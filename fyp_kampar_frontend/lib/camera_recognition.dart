//camera view
import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'ar_display.dart';

class CameraRecognition extends StatefulWidget {
  final String placeId;
  const CameraRecognition({super.key, required this.placeId});

  @override
  State<CameraRecognition> createState() => _CameraRecognitionState();
}

class _CameraRecognitionState extends State<CameraRecognition>
    with WidgetsBindingObserver {
  Timer? _timer;
  Timer? _clearDisplayTimer;
  Timer? _coldStartTimer;

  bool _hasPermissions = false;
  List<dynamic> _prediction = [];
  ARSessionManager? _arSessionManager;
  bool _isProcessingFrame = false;
  bool _isARVisible = true;

  bool _isWaitingForBackend = false;
  String _loadingText = "Analysing environment...";
  bool _hasReceivedFirstResponse = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _timer?.cancel();
      setState(() {
        _isARVisible = false;
        _prediction = [];
      });
      log("App in background. Timer paused and AR surface destroyed.");
    } else if (state == AppLifecycleState.resumed) {
      setState(() {
        _isARVisible = true;
      });
      log("App resumed. Rebuilding new AR surface.");
    }
  }

  Future<void> _checkPermissions() async {
    if (await Permission.camera.request().isGranted) {
      setState(() => _hasPermissions = true);
    } else {
      _showPermissionDeniedDialog();
    }
  }

  void _onARViewCreated(ARSessionManager sessionManager) {
    _arSessionManager = sessionManager;
    _startFrameCapture();
  }

  void _startFrameCapture() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      // Skip this tick if still waiting for the backend or AR view not ready
      if (!mounted || _arSessionManager == null || _isProcessingFrame) return;

      try {
        _isProcessingFrame = true;

        // Grab current frame
        final imageProvider = await _arSessionManager!.snapshot();

        await _processAndSendSnapshot(imageProvider);
      } catch (e) {
        log("KampAR capture error: $e");
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  Future<void> _processAndSendSnapshot(ImageProvider imageProvider) async {
    try {
      final Uint8List? imageBytes = await _imageProviderToBytes(imageProvider);
      if (imageBytes == null) return;

      if (!_hasReceivedFirstResponse) {
        if (mounted) {
          setState(() {
            _isWaitingForBackend = true;
            _loadingText = "Analyzing environment...";
          });
        }

        _coldStartTimer?.cancel();
        _coldStartTimer = Timer(const Duration(seconds: 5), () {
          if (mounted && !_hasReceivedFirstResponse) {
            setState(() {
              _loadingText =
                  "Waking up the server... this takes a few seconds!";
            });
          }
        });
      }

      final results = await _sendBytesToBackend(imageBytes, widget.placeId);

      if (!_hasReceivedFirstResponse) {
        _coldStartTimer?.cancel();
        if (mounted) {
          setState(() {
            _hasReceivedFirstResponse = true; 
            _isWaitingForBackend = false; 
          });
        }
      }

      if (mounted) {
        if (results.isNotEmpty) {
          setState(() => _prediction = results);
        }
        _clearDisplayTimer?.cancel();
        _clearDisplayTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _prediction = [];
            });
          }
        });
      }
    } catch (e) {
      log("Processing error: $e");
      // Safety net: Also cancel the timer if the network crashes
      _coldStartTimer?.cancel();
      if (mounted) setState(() => _isWaitingForBackend = false);
    }
  }

  // Helper to convert a Flutter ImageProvider into standard PNG bytes
  Future<Uint8List?> _imageProviderToBytes(ImageProvider provider) async {
    final completer = Completer<ui.Image>();
    final stream = provider.resolve(const ImageConfiguration());

    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        completer.complete(info.image);
        stream.removeListener(listener);
      },
      onError: (dynamic exception, StackTrace? stackTrace) {
        completer.completeError(exception);
        stream.removeListener(listener);
      },
    );

    stream.addListener(listener);
    final ui.Image image = await completer.future;

    // Convert to PNG format suitable for standard Python backend parsing
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    image.dispose();

    return byteData?.buffer.asUint8List();
  }

  Future<List<dynamic>> _sendBytesToBackend(
    Uint8List imageBytes,
    String place,
  ) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(
        'https://kampar-backend-830798580425.asia-southeast1.run.app/predict',
      ),
    );

    request.headers['User-Agent'] = 'KampAR-Client/1.0';

    // Attach the raw bytes as a file
    request.files.add(
      http.MultipartFile.fromBytes('file', imageBytes, filename: 'frame.png'),
    );
    request.fields['place'] = place;

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);
        return data['detections'] ?? [];
      }
    } catch (e) {
      log("Inference error: $e");
    }
    return [];
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
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _hasPermissions
          ? (_isARVisible
                ? Stack(
                    children: [
                      // 1. The main AR camera view
                      ARDisplay(
                        predictions: _prediction,
                        onARViewCreated: _onARViewCreated,
                      ),

                      // 2. The Loading Text Overlay
                      if (_isWaitingForBackend)
                        Positioned(
                          bottom:
                              50, 
                          left: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    _loadingText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  )
                : const Center(child: CircularProgressIndicator()))
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
