import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'camera_screen.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa a lista de câmeras
  try {
    cameras = await availableCameras();
  } catch (e) {
    print("Erro ao inicializar as câmeras: $e");
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Box Detector',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Verifica e solicita permissões
    var cameraStatus = await Permission.camera.status;

    if (!cameraStatus.isGranted) {
      cameraStatus = await Permission.camera.request();
    }

    if (cameraStatus.isGranted) {
      setState(() {
        _permissionsGranted = true;
      });
    } else {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permissão Necessária'),
        content: Text('A permissão para acessar a câmera é necessária para usar o aplicativo.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
            child: Text('Configurações'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Box Detector App'),
        centerTitle: true,
      ),
      body: _permissionsGranted
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Box Detector',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Este app detecta caixas ao vivo em uma transmissão da câmera.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      if (cameras.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CameraScreen(camera: cameras.first),
                          ),
                        );
                      } else {
                        print("Nenhuma câmera encontrada");
                      }
                    },
                    child: Text('Iniciar Detecção'),
                  ),
                ],
              ),
            )
          : Center(
              child: Text(
                'Permissões necessárias para usar a câmera.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
    );
  }
}
