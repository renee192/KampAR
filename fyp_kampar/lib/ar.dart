// import 'package:flutter/material.dart';

// // Explicit ar_flutter_plugin imports
// import 'package:ar_flutter_plugin/widgets/ar_view.dart';
// import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
// import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
// import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
// import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
// import 'package:ar_flutter_plugin/models/ar_anchor.dart';
// import 'package:ar_flutter_plugin/models/ar_node.dart';
// import 'package:ar_flutter_plugin/datatypes/node_types.dart';
// import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';

// import 'package:vector_math/vector_math_64.dart' as vm;

// class ARFloatingLabelPage extends StatefulWidget {
//   final String label;
//   const ARFloatingLabelPage({super.key, required this.label});

//   @override
//   State<ARFloatingLabelPage> createState() => _ARFloatingLabelPageState();
// }

// class _ARFloatingLabelPageState extends State<ARFloatingLabelPage> {
//   ARSessionManager? sessionManager;
//   ARObjectManager? objectManager;
//   ARAnchorManager? anchorManager;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('AR Spot: ${widget.label}')),
//       body: ARView(
//         planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
//         onARViewCreated: (ARSessionManager s, ARObjectManager o, ARAnchorManager a, ARLocationManager l) async {
//           sessionManager = s;
//           objectManager  = o;
//           anchorManager  = a;
          
//           await sessionManager!.onInitialize(
//             showPlanes: true,
//             showWorldOrigin: false,
//             handleTaps: true,                 // we’ll use tap-to-place (works everywhere)
//           );
//           await objectManager!.onInitialize();

//           // Tap anywhere on a detected plane to place the “button/label”
//           sessionManager!.onPlaneOrPointTap = (hits) async {
//             if (hits.isEmpty) return;
//             final anchor = ARPlaneAnchor(transformation: hits.first.worldTransform);
//             final ok = await anchorManager!.addAnchor(anchor);
//             if (ok != true) return;

//             final node = ARNode(
//               name: 'spotNode',
//               type: NodeType.localGLTF2,
//               uri: 'assets/models/label_card.glb', // flat card model
//               scale: vm.Vector3(0.05, 0.05, 0.05),
//             );
//             await objectManager!.addNode(node, planeAnchor: anchor);
//           };

//           // Tap the node -> navigate
//           objectManager!.onNodeTap = (names) {
//             if (names.contains('spotNode')) {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => InfoPage(title: widget.label),
//                 ),
//               );
//             }
//           };
//         },
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     sessionManager?.dispose();
//     super.dispose();
//   }
// }

// class InfoPage extends StatelessWidget {
//   final String title;
//   const InfoPage({super.key, required this.title});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(title)),
//       body: Center(child: Text('Info about $title', style: const TextStyle(fontSize: 18))),
//     );
//   }
// }

//.yaml
  // ar_flutter_plugin:
  //   git:
  //     url: https://github.com/renee192/ar_flutter_plugin.git
  //     ref: main
  // vector_math: ^2.1.4
