import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  CameraScreen({required this.camera});

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
      ResolutionPreset.high,
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
      // Carrega o modelo TFLite
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
      print(_interpreter);

      // Carrega os rótulos
      final labelData = await rootBundle.loadString('assets/labelmap.txt');
      _labels = labelData.split('\n');

      setState(() {
        _detectionResult = "Ready for Detection!";
      });
    } catch (e) {
      print("Erro ao carregar o modelo ou os rótulos: $e");
      setState(() {
        _detectionResult = "Failed to Load Model";
      });
    }
  }

  Future<void> _runModel(CameraImage image) async {
    try {
      // Prepara os dados da imagem
      final input = _preprocessImage(image);

      // Cria uma matriz para a saída do modelo
      final output = List.generate(1, (i) => List.filled(_labels.length, 0.0));

      // Executa a inferência
      _interpreter.run(input, output);

      // Processa os resultados
      final result = _postProcessOutput(output[0]);
      setState(() {
        _detectionResult = result;
      });
    } catch (e) {
      print("Erro ao executar o modelo: $e");
    }
  }

  Uint8List _preprocessImage(CameraImage image) {
    // Converte a imagem para um formato compatível com o modelo
    final inputSize = 224; // Tamanho esperado pelo modelo
    final planes = image.planes;

    // Redimensiona e normaliza a imagem (exemplo genérico)
    // Aqui você deve adaptar de acordo com o modelo
    return Uint8List.fromList(planes[0].bytes);
  }

  String _postProcessOutput(List<double> output) {
    final topPrediction = output.asMap().entries.reduce((a, b) =>
        a.value > b.value ? a : b); // Encontra a classe com maior confiança

    final label = _labels[topPrediction.key];
    final confidence = topPrediction.value;

    if (confidence > 0.5) {
      if (label == "Class 1") {
        return "Box";
      } else if (label == "Class 2") {
        return "Nothing";
      }
    }

    return "Not Detected";
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
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Live Detection'),
        leading: BackButton(),
      ),
      body: Stack(
        children: [
          // Exibe a câmera
          RotatedBox(
            quarterTurns: 1,
            child: SizedBox.expand(
              child: CameraPreview(_controller),
            ),
          ),
          // Texto de status da detecção
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: EdgeInsets.all(8),
              color: _detectionResult == "Box" ? Colors.green : Colors.red,
              child: Text(
                _detectionResult,
                style: TextStyle(
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
