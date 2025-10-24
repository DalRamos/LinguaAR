import 'dart:async';
import 'dart:convert';
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

  String url = Fsl.fslUrl;

  bool _isFlipping = false;
  bool _isMounted = true;
  bool _stopPrediction = false;
  Timer? _predictionTimer;
  bool _isCameraReady = false;

  bool _showCategoryModal = false;
  String _currentCategory = "Alphabets";

  // Word recognition session
  String _sessionId = "";
  bool _isProcessingPrediction = false;
  Timer? _wordStreamTimer;

  // request gating
  bool _shotInFlight = false;
  DateTime _lastStaticShot = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastWordShot = DateTime.fromMillisecondsSinceEpoch(0);

  // cadence (sync with hybrid)
  static const _minStaticInterval = Duration(milliseconds: 2200);
  static const _minWordInterval = Duration(milliseconds: 450);

  // thresholds (sync with API)
  static const double _staticMinConf = 0.55; // used for Numbers only

  final FlutterTts flutterTts = FlutterTts();

  String get _staticApi => '$url/gesture/static';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeTts();
    _newSession();
    if (widget.isActive) {
      _initializeCamera();
    }
  }

  void _newSession() {
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
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
    _wordStreamTimer?.cancel();
    if (_cameraController != null) {
      await _cameraController?.dispose();
    }
    if (_isMounted) {
      setState(() => _isCameraReady = false);
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
      await _cameraController?.dispose();
      _cameraController = CameraController(
        widget.cameras[_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _cameraController!.initialize();

      if (!_isMounted || !widget.isActive) return;

      setState(() {
        _isFlipping = false;
        _stopPrediction = false;
        _isCameraReady = true;
      });

      _startPredictionTimer();
    } catch (e) {
      debugPrint("❌ Camera init failed: $e");
      if (_isMounted) {
        setState(() => _isFlipping = false);
        Future.delayed(const Duration(seconds: 1), _initializeCamera);
      }
    }
  }

  void _startPredictionTimer() {
    _predictionTimer?.cancel();
    _wordStreamTimer?.cancel();

    if (_currentCategory == "Words") {
      predictedCharacter = "Listening…";
      _wordStreamTimer = Timer.periodic(_minWordInterval, (_) async {
        if (!_stopPrediction &&
            _isMounted &&
            widget.isActive &&
            !_isProcessingPrediction) {
          await _simulateWordPrediction();
        }
      });
    } else {
      _predictionTimer = Timer.periodic(_minStaticInterval, (_) async {
        if (!_stopPrediction && _isMounted && widget.isActive) {
          await _predictStaticGesture();
        }
      });
    }
  }

  bool _canShoot({required bool isWord}) {
    if (_shotInFlight ||
        !_isMounted ||
        !_isCameraReady ||
        _stopPrediction ||
        !widget.isActive) return false;
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return false;
    final now = DateTime.now();
    if (isWord) {
      if (now.difference(_lastWordShot) < _minWordInterval) return false;
    } else {
      if (now.difference(_lastStaticShot) < _minStaticInterval) return false;
    }
    return true;
  }

  Future<void> _predictStaticGesture() async {
    if (!_canShoot(isWord: false)) return;

    setState(() {
      isPredicting = true;
      _shotInFlight = true;
    });
    _lastStaticShot = DateTime.now();

    try {
      final imageFile = await _cameraController!.takePicture();
      final bytes = await imageFile.readAsBytes();

      final request = http.MultipartRequest('POST', Uri.parse(_staticApi));
      final category = _currentCategory == "Numbers" ? "number" : "alphabet";
      request.fields['category'] = category;
      request.files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: "frame.jpg"));

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final j = jsonDecode(body);
        final ch = (j["predicted_character"] ?? "").toString();
        final conf = (j["confidence"] ?? 1.0).toDouble();

        if (ch.isEmpty) return;
        final ok =
            (_currentCategory == "Numbers") ? (conf >= _staticMinConf) : true;
        if (!ok) return;

        if (_isMounted && ch != predictedCharacter) {
          setState(() => predictedCharacter = ch);
          if (ch != lastSpokenCharacter) {
            try {
              await flutterTts.stop();
              await flutterTts.speak(ch);
            } catch (_) {}
            lastSpokenCharacter = ch;
          }
        }
      } else if (_isMounted) {
        setState(() {
          predictedCharacter =
              response.statusCode == 404 ? "No hand detected" : "Server error";
        });
      }
    } catch (e) {
      debugPrint("❌ Static prediction error: $e");
      if (_isMounted) setState(() => predictedCharacter = "Connection error");
    } finally {
      if (_isMounted)
        setState(() {
          isPredicting = false;
          _shotInFlight = false;
        });
    }
  }

  Future<void> _simulateWordPrediction() async {
    if (!_canShoot(isWord: true) || _isProcessingPrediction) return;

    setState(() {
      isPredicting = true;
      _shotInFlight = true;
      predictedCharacter = "Processing…";
    });
    _lastWordShot = DateTime.now();

    try {
      // Simulate 3 second delay
      await Future.delayed(const Duration(seconds: 3));
      
      if (_isMounted) {
        setState(() => predictedCharacter = "pakiusap");
        if ("pakiusap" != lastSpokenCharacter) {
          try {
            await flutterTts.stop();
            await flutterTts.speak("pakiusap");
          } catch (_) {}
          lastSpokenCharacter = "pakiusap";
        }
      }

      // Reset after speaking
      _isProcessingPrediction = true;
      await Future.delayed(const Duration(milliseconds: 1200));
      _isProcessingPrediction = false;
      
      if (_isMounted) {
        setState(() => predictedCharacter = "Listening…");
      }
    } catch (e) {
      debugPrint("❌ Word simulation error: $e");
      if (_isMounted) setState(() => predictedCharacter = "Error");
    } finally {
      if (_isMounted)
        setState(() {
          isPredicting = false;
          _shotInFlight = false;
        });
    }
  }

  Future<void> _flipCamera() async {
    if (_isFlipping || !_isMounted) return;
    setState(() => _cameraIndex = (_cameraIndex == 0) ? 1 : 0);
    await _initializeCamera();
  }

  void _showCategorySelectionModal() {
    setState(() => _showCategoryModal = true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _buildCategoryModal(),
    ).then((_) => setState(() => _showCategoryModal = false));
  }

  Future<void> _selectCategory(String category) async {
    _stopPrediction = true;
    _predictionTimer?.cancel();
    _wordStreamTimer?.cancel();

    if (category == "Words") {
      _newSession();
    }

    setState(() {
      _currentCategory = category;
      predictedCharacter = category == "Words" ? "Listening…" : "";
      lastSpokenCharacter = "";
    });

    Navigator.pop(context);

    if (_isMounted && widget.isActive) {
      _stopPrediction = false;
      _startPredictionTimer();
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    WidgetsBinding.instance.removeObserver(this);
    _stopPrediction = true;
    _predictionTimer?.cancel();
    _wordStreamTimer?.cancel();
    flutterTts.stop();
    _cameraController?.dispose().then((_) => _cameraController = null);
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

        // Category Button
        Positioned(
          bottom: 120,
          right: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4))
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showCategorySelectionModal,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.category, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(_currentCategory,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Prediction Display
        Positioned(
          bottom: 5,
          left: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Prediction:",
                    style: TextStyle(fontSize: 18, color: Colors.white)),
                const SizedBox(height: 8),
                Text(
                  predictedCharacter,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        // Flip Button
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

  Widget _buildCategoryModal() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: const Text("Choose a category",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
                textAlign: TextAlign.center),
          ),

          _buildCategoryItem(
            icon: Icons.numbers,
            title: "Numbers",
            subtitle: "1, 2, 3… (Single Image)",
            isSelected: _currentCategory == "Numbers",
            onTap: () => _selectCategory("Numbers"),
          ),
          _buildCategoryItem(
            icon: Icons.abc,
            title: "Alphabets",
            subtitle: "A, B, C… (Single Image)",
            isSelected: _currentCategory == "Alphabets",
            onTap: () => _selectCategory("Alphabets"),
          ),
          _buildCategoryItem(
            icon: Icons.text_fields,
            title: "Words",
            subtitle: "Continuous stream (Realtime)",
            isSelected: _currentCategory == "Words",
            onTap: () => _selectCategory("Words"),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCategoryItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade600 : Colors.blue.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon,
            color: isSelected ? Colors.white : Colors.blue.shade700, size: 28),
      ),
      title: Text(
        title,
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.blue.shade700 : Colors.black),
      ),
      subtitle: Text(subtitle,
          style: TextStyle(
              fontSize: 14,
              color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600)),
      trailing: isSelected
          ? Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.check, color: Colors.blue.shade700, size: 20),
            )
          : Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.arrow_forward_ios,
                  color: Colors.grey.shade600, size: 16),
            ),
      onTap: onTap,
    );
  }
}