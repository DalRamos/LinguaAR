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
  bool _showCategoryModal = false;
  String _currentCategory = "Alphabets"; // Default category

  final FlutterTts flutterTts = FlutterTts();

  // API endpoints for different categories
  String get _currentApiEndpoint {
    switch (_currentCategory) {
      case "Numbers":
        return '$url/gesture/numbers'; // API for numbers
      case "Words":
        return '$url/gesture/words'; // API for words
      case "Alphabets":
      default:
        return '$url/gesture/hands'; // API for alphabets (default)
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeTts();
    if (widget.isActive) {
      _initializeCamera();
    }
    // Print initial API endpoint
    print("🎯 Initial API Endpoint: $_currentApiEndpoint");
    print("🎯 Current Category: $_currentCategory");
  }

  @override
  void didUpdateWidget(GestureVoiceTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _initializeCamera();
      // Print API when tab becomes active
      print("🎯 Tab Activated - API Endpoint: $_currentApiEndpoint");
      print("🎯 Current Category: $_currentCategory");
    } else if (!widget.isActive && oldWidget.isActive) {
      _stopCamera();
      print("🎯 Tab Deactivated");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isMounted) return;

    if (state == AppLifecycleState.inactive) {
      _stopCamera();
      print("🎯 App Inactive");
    } else if (state == AppLifecycleState.resumed && widget.isActive) {
      _initializeCamera();
      // Print API when app resumes
      print("🎯 App Resumed - API Endpoint: $_currentApiEndpoint");
      print("🎯 Current Category: $_currentCategory");
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
    if (_cameraController != null) {
      await _cameraController?.dispose();
    }
    if (_isMounted) {
      setState(() {
        _isCameraReady = false;
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

      _cameraController = CameraController(
        widget.cameras[_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
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
      print("❌ Camera initialization failed: $e");
      if (_isMounted) {
        setState(() {
          _isFlipping = false;
        });
        Future.delayed(Duration(seconds: 1), _initializeCamera);
      }
    }
  }

  void _startPredictionTimer() {
    _predictionTimer?.cancel();
    _predictionTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
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
        !widget.isActive) {
      return;
    }

    setState(() => isPredicting = true);

    try {
      XFile? imageFile = await _cameraController!.takePicture();
      Uint8List imageBytes = await imageFile.readAsBytes();

      // Print API endpoint before making request
      print("🔄 Making API call to: $_currentApiEndpoint");
      print("📊 Category: $_currentCategory");

      // Use the current API endpoint based on selected category
      var request =
          http.MultipartRequest('POST', Uri.parse(_currentApiEndpoint));
      request.files.add(http.MultipartFile.fromBytes('file', imageBytes,
          filename: "gesture.jpg"));

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseString = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseString);

        // Handle different response formats for different endpoints
        String character = "";

        if (_currentCategory == "Numbers") {
          // Number endpoint response format
          if (jsonResponse["status"] == "success") {
            character = jsonResponse["predicted_character"] ?? "";
            print("✅ Number Prediction: $character");
          } else {
            print("❌ Number API error: ${jsonResponse["message"]}");
            return;
          }
        } else if (_currentCategory == "Alphabets") {
          // Alphabet endpoint response format
          if (jsonResponse["status"] == "success") {
            character = jsonResponse["predicted_character"] ?? "";
            print("✅ Alphabet Prediction: $character");
          } else {
            print("❌ Alphabet API error: ${jsonResponse["message"]}");
            return;
          }
        } else if (_currentCategory == "Words") {
          // Word endpoint response format (placeholder)
          character = jsonResponse["message"] ?? "Words feature coming soon";
          print("ℹ️ Words API: $character");
        }

        if (character.isNotEmpty &&
            character != predictedCharacter &&
            _isMounted) {
          setState(() => predictedCharacter = character);

          if (character != lastSpokenCharacter) {
            await flutterTts.stop();
            await flutterTts.speak(character);
            lastSpokenCharacter = character;
            print("🔊 TTS Speaking: $character");
          }
        }
      } else {
        print("❌ API Error: ${response.statusCode}");
        print("❌ API Endpoint: $_currentApiEndpoint");

        // Handle different error cases
        if (response.statusCode == 404) {
          setState(() {
            predictedCharacter = "No hand detected";
          });
          print("❌ No hand detected in image");
        } else if (response.statusCode == 500) {
          setState(() {
            predictedCharacter = "Server error";
          });
          print("❌ Server error occurred");
        } else if (response.statusCode == 501) {
          setState(() {
            predictedCharacter = "Feature coming soon";
          });
          print("ℹ️ Words feature not implemented yet");
        }
      }
    } catch (e) {
      print("❌ Prediction error: $e");
      print("❌ API Endpoint: $_currentApiEndpoint");

      if (_isMounted) {
        setState(() {
          predictedCharacter = "Connection error";
        });
      }

      if (_isMounted && !_stopPrediction && widget.isActive) {
        await _initializeCamera();
      }
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
    print("📷 Camera flipped to: ${_cameraIndex == 0 ? 'Front' : 'Back'}");
  }

  void _showCategorySelectionModal() {
    setState(() {
      _showCategoryModal = true;
    });

    print("📱 Opening category selection modal");
    print("🎯 Current API before selection: $_currentApiEndpoint");

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _buildCategoryModal();
      },
    ).then((_) {
      setState(() {
        _showCategoryModal = false;
      });
      print("📱 Category modal closed");
    });
  }

  void _selectCategory(String category) {
    String oldCategory = _currentCategory;
    String oldApi = _currentApiEndpoint;

    setState(() {
      _currentCategory = category;
      predictedCharacter = ""; // Clear previous prediction
      lastSpokenCharacter = ""; // Clear last spoken
    });
    Navigator.pop(context);

    print("🔄 Category changed:");
    print("   From: $oldCategory ($oldApi)");
    print("   To: $_currentCategory ($_currentApiEndpoint)");
    print("🎯 New API Endpoint: $_currentApiEndpoint");
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
            offset: const Offset(0, 10),
          ),
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
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: const Text(
              "Choose a category",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Categories
          _buildCategoryItem(
            icon: Icons.numbers,
            title: "Numbers",
            subtitle: "1, 2, 3, ...",
            isSelected: _currentCategory == "Numbers",
            onTap: () => _selectCategory("Numbers"),
          ),

          _buildCategoryItem(
            icon: Icons.abc,
            title: "Alphabets",
            subtitle: "A, B, C, ...",
            isSelected: _currentCategory == "Alphabets",
            onTap: () => _selectCategory("Alphabets"),
          ),

          _buildCategoryItem(
            icon: Icons.text_fields,
            title: "Words",
            subtitle: "Complete words",
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
          color: isSelected ? Colors.blue.shade700 : Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
        ),
      ),
      trailing: isSelected
          ? Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.check, color: Colors.blue.shade700, size: 20),
            )
          : Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_forward_ios,
                  color: Colors.grey.shade600, size: 16),
            ),
      onTap: onTap,
    );
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
    print("🎯 GestureVoiceTab disposed");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Print when widget builds (when you're in the tab)
    print("🎯 Building GestureVoiceTab - Current API: $_currentApiEndpoint");

    return Stack(
      children: [
        if (_isCameraReady && _cameraController != null)
          _buildFullscreenPreview(context)
        else
          const Center(child: CircularProgressIndicator()),

        // Category Button - Outside the prediction box
        Positioned(
          bottom: 120, // Positioned above the prediction box
          right: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white,
                width: 3.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showCategorySelectionModal,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.category, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _currentCategory,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Prediction Display Box
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
                const Text("Predicted Character:",
                    style: TextStyle(fontSize: 18, color: Colors.white)),
                const SizedBox(height: 8),
                Text(predictedCharacter,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent)),
              ],
            ),
          ),
        ),

        // Camera Flip Button
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
