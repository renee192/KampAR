import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class ARDisplay extends StatefulWidget {
  final List<dynamic> predictions;
  final Function(ARSessionManager) onARViewCreated;

  const ARDisplay({
    super.key,
    required this.predictions,
    required this.onARViewCreated,
  });

  @override
  State<ARDisplay> createState() => _ARDisplayState();
}

class _ARDisplayState extends State<ARDisplay> {
  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;

  void _onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    _arSessionManager = arSessionManager;
    _arObjectManager = arObjectManager;

    _arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: false,
      showWorldOrigin: false,
      showAnimatedGuide: false,
    );
    _arObjectManager!.onInitialize();

    widget.onARViewCreated(_arSessionManager!);
  }

  @override
  void dispose() {
    _arSessionManager?.dispose();
    super.dispose();
  }

  Widget _buildHybridOverlay(BoxConstraints constraints) {
    if (widget.predictions.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: widget.predictions.map((det) {
        try {
          final box = det['box'];
          final String label = det['label']?.toString() ?? 'Unknown';
          final String targetUrl = det['url']?.toString() ?? '';

          // 1. SAFELY PARSE NUMBERS (Prevents silent UI crashes)
          double rawTop = (box[1] as num).toDouble() * constraints.maxHeight;
          double left = (box[0] as num).toDouble() * constraints.maxWidth;

          // 2. STOP HIDING OBJECTS AT THE TOP (Removed the 100.0 limit)
          double safeTop = rawTop - 40;
          if (safeTop < 10.0) safeTop = 10.0; // Just keep it 10px from the absolute top edge

          return Positioned(
            left: left,
            top: safeTop,
            // 3. REMOVED the 'width: width' parameter entirely so the text can size itself!
            child: GestureDetector(
              onTap: () async {
                if (targetUrl.isNotEmpty) {
                  final Uri url = Uri.parse(targetUrl);
                  if (!await launchUrl(url, mode: LaunchMode.inAppBrowserView)) {
                    debugPrint("Could not launch $url");
                  }
                } else {
                  debugPrint("No URL attached to this attraction");
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min, 
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 12, 56, 113),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14, // Bumped size slightly
                        fontWeight: FontWeight.bold,
                        fontFamily: "Montserrat",                    
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Color.fromARGB(255, 12, 56, 113),
                    size: 28, // Made pointer a bit more visible
                  ),
                ],
              ),
            ),
          );
        } catch (e) {
          debugPrint("UI CRASHED DRAWING LABEL: $e");
          return const SizedBox.shrink();
        }
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            ARView(
              onARViewCreated: _onARViewCreated,
              planeDetectionConfig: PlaneDetectionConfig.none,
            ),
            _buildHybridOverlay(constraints),
          ],
        );
      },
    );
  }
}
