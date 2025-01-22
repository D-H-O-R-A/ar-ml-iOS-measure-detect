import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class ObjectDetector {
  Interpreter? _interpreter;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('model.tflite');
      print("Model loaded successfully.");
    } catch (e) {
      print("Failed to load model: $e");
    }
  }

  Future<List<Map<String, dynamic>>> detectObjects(CameraImage image) async {
    if (_interpreter == null) {
      print("Interpreter not initialized.");
      return [];
    }

    try {
      final input = await _convertToByteList(image);
      final output = List.generate(10, (index) => List.filled(4, 0.0));
      _interpreter!.run(input, output);

      return output.map((box) {
        return {
          'x': box[0],
          'y': box[1],
          'width': box[2],
          'height': box[3],
        };
      }).toList();
    } catch (e) {
      print("Error during object detection: $e");
      return [];
    }
  }

  Future<Uint8List> _convertToByteList(CameraImage image) async {
    try {
      // Converte a imagem para um formato compatível com a biblioteca de manipulação de imagem
      final img.Image convertedImage = _convertCameraImageToImage(image);

      // Redimensiona a imagem para o tamanho esperado pelo modelo (exemplo: 300x300)
      final img.Image resizedImage = img.copyResize(
        convertedImage,
        width: 300, // Tamanho compatível com seu modelo
        height: 300,
      );

      // Normaliza os pixels (exemplo: escala de 0 a 1, dependendo do modelo)
      final Float32List input = Float32List(300 * 300 * 3);
      for (int y = 0; y < 300; y++) {
        for (int x = 0; x < 300; x++) {
          // Obtém o pixel no formato esperado
          final pixel = resizedImage.getPixel(x, y);

          // Converte o valor do pixel para os componentes R, G e B
          final r = pixel.r / 255.0;
          final g = pixel.g / 255.0;
          final b = pixel.b / 255.0;

          final index = (y * 300 + x) * 3;
          input[index] = r;
          input[index + 1] = g;
          input[index + 2] = b;
        }
      }

      return input.buffer.asUint8List();
    } catch (e) {
      print("Error during image conversion: $e");
      return Uint8List(0);
    }
  }

  img.Image _convertCameraImageToImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final img.Image convertedImage = img.Image(width: width, height: height);

    // Processa os planos YUV para obter os canais RGB
    final Plane yPlane = image.planes[0];
    final Plane uPlane = image.planes[1];
    final Plane vPlane = image.planes[2];

    final int yRowStride = yPlane.bytesPerRow;
    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel!;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * yRowStride + x;

        final int uvIndex =
            (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        final int yValue = yPlane.bytes[yIndex];
        final int uValue = uPlane.bytes[uvIndex];
        final int vValue = vPlane.bytes[uvIndex];

        // Converte YUV para RGB
        final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
        final g = (yValue -
                0.344136 * (uValue - 128) -
                0.714136 * (vValue - 128))
            .clamp(0, 255)
            .toInt();
        final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();

        // Define os valores no formato de pixel da biblioteca image
        convertedImage.setPixelRgb(x, y, r, g, b);
      }
    }

    return convertedImage;
  }
}
