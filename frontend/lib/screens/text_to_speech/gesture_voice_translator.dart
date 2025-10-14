import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:lingua_arv1/repositories/Config.dart';

class GestureVoiceTab extends StatefulWidget {
  final List<CameraDescription> cameras;
  final bool isActive;

  const GestureVoiceTab({
    required this.cameras,
    required this.isActive,
    Key? key,
  }) : super(key: key);

  @override
  _GestureVoiceTabState createState() => _GestureVoiceTabState();
}

class _GestureVoiceTabState extends State<GestureVoiceTab>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  int _cameraIndex = 1;
  String predictedCharacter = "";
  String lastSpokenCharacter = "";
  bool isPredicting = false;
  String url = BasicUrl.baseURL;
  bool _isFlipping = false;
  bool _isMounted = true;
  bool _stopPrediction = false;
  Timer? _predictionTimer;
  bool _isCameraReady = false;
  String? _clientId;

  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeTts();
    if (widget.isActive) {
      _initializeCamera();
    }
  }

  @override
  void didUpdateWidget(GestureVoiceTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _initializeCamera();
    } else if (!widget.isActive && oldWidget.isActive) {
      _stopCamera();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isMounted) return;

    if (state == AppLifecycleState.inactive) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed && widget.isActive) {
      _initializeCamera();
    }
  }

  Future<void> _initializeTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _stopCamera() async {
    _stopPrediction = true;
    _predictionTimer?.cancel();

    // Stop stream on server
    if (_clientId != null) {
      try {
        await http.post(
          Uri.parse('$url/gesture/stream/stop/$_clientId'),
        );
        print('🛑 Stream stopped on server');
      } catch (e) {
        print("Error stopping stream: $e");
      }
    }

    if (_cameraController != null) {
      await _cameraController?.dispose();
    }
    if (_isMounted) {
      setState(() {
        _isCameraReady = false;
        _clientId = null;
      });
    }
  }

  Future<void> _initializeCamera() async {
    if (!_isMounted || !widget.isActive) return;

    setState(() {
      _isFlipping = true;
      _stopPrediction = true;
      _isCameraReady = false;
    });

    try {
      if (_cameraController != null) {
        await _cameraController!.dispose();
      }

      // Use optimized resolution for faster processing
      _cameraController = CameraController(
        widget.cameras[_cameraIndex],
        ResolutionPreset.high, // Changed from high to medium for speed
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (!_isMounted || !widget.isActive) return;

      // Start streaming session with server
      await _startStreamingSession();

      setState(() {
        _isFlipping = false;
        _stopPrediction = false;
        _isCameraReady = true;
      });

      _startPredictionTimer();
    } catch (e) {
      print("❌ Camera initialization failed: $e");
      if (_isMounted) {
        setState(() {
          _isFlipping = false;
        });
        Future.delayed(Duration(seconds: 1), _initializeCamera);
      }
    }
  }

  Future<void> _startStreamingSession() async {
    try {
      final response = await http.post(
        Uri.parse('$url/gesture/stream/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'client_id': 'voice_${DateTime.now().millisecondsSinceEpoch}'}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _clientId = data['client_id'];
        print('✅ Voice streaming session started: $_clientId');
      } else {
        print('❌ Failed to start stream: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Failed to start streaming session: $e');
    }
  }

  void _startPredictionTimer() {
    _predictionTimer?.cancel();
    // Increased frequency for faster response
    _predictionTimer =
        Timer.periodic(Duration(milliseconds: 800), (timer) async {
      if (!_stopPrediction && _isMounted && widget.isActive) {
        await _predictGesture();
      }
    });
  }

  Future<void> _predictGesture() async {
    if (isPredicting ||
        !_isMounted ||
        !_isCameraReady ||
        _stopPrediction ||
        !widget.isActive ||
        _clientId == null) {
      return;
    }

    setState(() => isPredicting = true);

    try {
      XFile? imageFile = await _cameraController!.takePicture();
      Uint8List imageBytes = await imageFile.readAsBytes();

      var request = http.MultipartRequest(
          'POST', Uri.parse('$url/gesture/stream/frame/$_clientId'));

      request.files.add(http.MultipartFile.fromBytes('frame', imageBytes,
          filename: "gesture.jpg"));

      var response = await request.send();

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(await response.stream.bytesToString());
        String character = jsonResponse["predicted_character"] ?? "";
        double confidence = (jsonResponse["confidence"] ?? 0.0).toDouble();
        bool handDetected = jsonResponse["hand_detected"] ?? false;

        if (handDetected && character.isNotEmpty && _isMounted) {
          setState(() => predictedCharacter = character);

          // Optimized speaking logic - higher confidence threshold for stability
          if (character != lastSpokenCharacter && confidence > 0.75) {
            await flutterTts.stop();
            await flutterTts.speak(character);
            lastSpokenCharacter = character;
          }
        } else if (!handDetected && _isMounted) {
          setState(() => predictedCharacter = "");
          lastSpokenCharacter = "";
        }
      }
    } catch (e) {
      print("❌ Prediction error: $e");
    } finally {
      if (_isMounted) {
        setState(() => isPredicting = false);
      }
    }
  }

  Future<void> _flipCamera() async {
    if (_isFlipping || !_isMounted) return;

    setState(() => _cameraIndex = (_cameraIndex == 0) ? 1 : 0);
    await _initializeCamera();
  }

  @override
  void dispose() {
    _isMounted = false;
    WidgetsBinding.instance.removeObserver(this);
    _stopPrediction = true;
    _predictionTimer?.cancel();
    flutterTts.stop();
    _cameraController?.dispose().then((_) {
      _cameraController = null;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_isCameraReady && _cameraController != null)
          _buildFullscreenPreview(context)
        else
          const Center(child: CircularProgressIndicator()),
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Predicted Character:",
                    style: TextStyle(fontSize: 18, color: Colors.white)),
                const SizedBox(height: 8),
                Text(
                  predictedCharacter.isEmpty
                      ? "Show your hand"
                      : predictedCharacter,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: predictedCharacter.isEmpty
                          ? Colors.grey
                          : Colors.greenAccent),
                ),
                if (isPredicting)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Detecting...",
                      style: TextStyle(fontSize: 12, color: Colors.yellow),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white),
            onPressed: _flipCamera,
          ),
        ),
      ],
    );
  }

  Widget _buildFullscreenPreview(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final previewSize = _cameraController!.value.previewSize!;
    final previewRatio = previewSize.height / previewSize.width;
    final deviceRatio = size.width / size.height;
    final scale = previewRatio / deviceRatio;

    return Transform.scale(
      scale: scale,
      child: Center(
        child: AspectRatio(
          aspectRatio: previewRatio,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }
}
