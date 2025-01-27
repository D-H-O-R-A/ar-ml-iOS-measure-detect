import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';

class ArMeasureScreen extends StatefulWidget {
  const ArMeasureScreen({Key? key}) : super(key: key);

  @override
  _ArMeasureScreenState createState() => _ArMeasureScreenState();
}

class _ArMeasureScreenState extends State<ArMeasureScreen> {
  late ARSessionManager arSessionManager;
  late ARObjectManager arObjectManager;
  String volumeInfo = "Detectando volume...";
  bool planeDetected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Medição de Volume em AR"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
          ),
          if (!planeDetected)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "Aponte para uma superfície plana para iniciar",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                volumeInfo,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onARViewCreated(
      ARSessionManager sessionManager, ARObjectManager objectManager) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;

    // Configurações do AR
    arSessionManager.onPlaneDetected = onPlaneDetected;
    arSessionManager.onSessionError = onSessionError;
    arSessionManager.onSessionEnded = onSessionEnded;

    arObjectManager.onNodeTapped = onNodeTapped;

    arSessionManager.startSession(
      planeDetectionConfig: PlaneDetectionConfig.horizontal,
    );
  }

  void onPlaneDetected(ARPlaneAnchor planeAnchor) {
    setState(() {
      planeDetected = true;
      final width = planeAnchor.extent.x;
      final height = planeAnchor.extent.z;
      final volume = (width * height * 0.3).toStringAsFixed(2); // Altura estimada

      volumeInfo =
          "Plano detectado!\n\nLargura: ${width.toStringAsFixed(2)}m\n"
          "Altura: ${height.toStringAsFixed(2)}m\n"
          "Volume estimado: ${volume}m³";
    });
  }

  void onNodeTapped(String nodeName) {
    setState(() {
      volumeInfo = "Você interagiu com: $nodeName";
    });
  }

  void onSessionError(String error) {
    setState(() {
      volumeInfo = "Erro: $error";
    });
  }

  void onSessionEnded(String reason) {
    setState(() {
      volumeInfo = "Sessão finalizada: $reason";
    });
  }

  @override
  void dispose() {
    arSessionManager.dispose();
    arObjectManager.dispose();
    super.dispose();
  }
}
