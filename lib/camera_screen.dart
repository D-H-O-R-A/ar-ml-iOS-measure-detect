import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  String? _capturedImagePath;

  @override
  void initState() {
    super.initState();
    if (widget.cameras.isNotEmpty) {
      _initializeCamera(widget.cameras[0]);
    } else {
      debugPrint("Nenhuma câmera foi encontrada.");
    }
  }

  Future<void> _initializeCamera(CameraDescription cameraDescription) async {
    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
    );

    try {
      await _cameraController.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint("Erro ao inicializar a câmera: $e");
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (!_cameraController.value.isInitialized) {
      debugPrint("Câmera não está inicializada.");
      return;
    }

    try {
      final XFile file = await _cameraController.takePicture();
      setState(() {
        _capturedImagePath = file.path;
      });
      debugPrint("Imagem capturada: ${file.path}");
    } catch (e) {
      debugPrint("Erro ao capturar a imagem: $e");
    }
  }

  Future<void> _startVideoRecording() async {
    if (!_cameraController.value.isInitialized || _isRecording) return;

    try {
      await _cameraController.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      debugPrint("Erro ao iniciar gravação de vídeo: $e");
    }
  }

  Future<void> _stopVideoRecording() async {
    if (!_cameraController.value.isInitialized || !_isRecording) return;

    try {
      final XFile file = await _cameraController.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _capturedImagePath = file.path;
      });
      debugPrint("Vídeo gravado: ${file.path}");
    } catch (e) {
      debugPrint("Erro ao parar gravação de vídeo: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Câmera"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          if (_isCameraInitialized)
            Expanded(
              child: CameraPreview(_cameraController),
            )
          else
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          if (_capturedImagePath != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.file(
                File(_capturedImagePath!),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.camera, size: 32),
                color: Colors.blue,
                onPressed: _captureImage,
              ),
              IconButton(
                icon: Icon(
                  _isRecording ? Icons.videocam_off : Icons.videocam,
                  size: 32,
                ),
                color: Colors.red,
                onPressed:
                    _isRecording ? _stopVideoRecording : _startVideoRecording,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
