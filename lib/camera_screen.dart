import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({Key? key, required this.camera}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Interpreter _interpreter;
  late List<String> _labels;
  bool _isDetecting = false;
  String _detectionResult = "Initializing...";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModelAndLabels();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller.initialize();
    await _controller.lockCaptureOrientation(DeviceOrientation.portraitUp);

    if (mounted) {
      setState(() {});
    }

    _controller.startImageStream((CameraImage image) {
      if (!_isDetecting) {
        _isDetecting = true;
        _runModel(image).then((_) {
          _isDetecting = false;
        });
      }
    });
  }

  Future<void> _loadModelAndLabels() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');

      final labelData = await rootBundle.loadString('assets/labelmap.txt');
      _labels = labelData.split('\n').where((label) => label.isNotEmpty).toList();

      setState(() {
        _detectionResult = "Model loaded. Ready for detection!";
      });
    } catch (e) {
      print("Error loading model or labels: $e");
      setState(() {
        _detectionResult = "Error loading model.";
      });
    }
  }

  Future<void> _runModel(CameraImage image) async {
    try {
      final input = _preprocessImage(image);

      final reshapedInput = input.reshape([1, 300, 300, 3]);

      final output = List.generate(1, (_) => List.generate(_labels.length, (_) => 0.0));

      _interpreter.run(reshapedInput, output);

      final result = _postProcessOutput(output[0]);
      setState(() {
        _detectionResult = result;
      });
    } catch (e) {
      print("Error during inference: $e");
    }
  }

  Float32List _preprocessImage(CameraImage image) {
    final img.Image convertedImage = _convertYUV420ToImage(image);

    final img.Image resizedImage = img.copyResize(
      convertedImage,
      width: 300,
      height: 300,
    );

    final input = Float32List(300 * 300 * 3);
    for (int y = 0; y < 300; y++) {
      for (int x = 0; x < 300; x++) {
        final pixel = resizedImage.getPixel(x, y) as img.PixelUint8;
        print("Pixel:"+(pixel).toString());
        final r = pixel.r; // Extrai o canal vermelho
        final g = pixel.g;  // Extrai o canal verde
        final b = pixel.b;         // Extrai o canal azul
        final index = (y * 300 + x) * 3;
        input[index] = r / 255.0;
        input[index + 1] = g / 255.0;
        input[index + 2] = b / 255.0;
      }
    }

    return input;
  }

  img.Image _convertYUV420ToImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    final Uint8List yPlane = image.planes[0].bytes;

    final img.Image grayscaleImage = img.Image(width: width, height: height);

    for (int i = 0; i < yPlane.length; i++) {
      final int pixelValue = yPlane[i];
      grayscaleImage.setPixelRgb(
        i % width,
        i ~/ width,
        pixelValue,
        pixelValue,
        pixelValue,
      );
    }

    return grayscaleImage;
  }

  String _postProcessOutput(List<double> output) {
    final maxIndex = output.indexWhere((value) => value == output.reduce((a, b) => a > b ? a : b));
    final confidence = output[maxIndex];

    if (confidence > 0.5) {
      return "Detected: ${_labels[maxIndex]} (${(confidence * 100).toStringAsFixed(2)}%)";
    }

    return "No objects detected.";
  }

  @override
  void dispose() {
    _controller.dispose();
    _interpreter.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Detection'),
        leading: const BackButton(),
      ),
      body: Stack(
        children: [
          RotatedBox(
            quarterTurns: 1,
            child: SizedBox.expand(
              child: CameraPreview(_controller),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: _detectionResult.startsWith("Detected") ? Colors.green : Colors.red,
              child: Text(
                _detectionResult,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
