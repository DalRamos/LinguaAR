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
  String url = Fsl.fslUrl;
  bool _isFlipping = false;
  bool _isMounted = true;
  bool _stopPrediction = false;
  Timer? _predictionTimer;
  bool _isCameraReady = false;
  bool _showCategoryModal = false;
  String _currentCategory = "Alphabets";

  // Word recognition session management
  String _sessionId = "";
  int _framesCollected = 0;
  int _framesRequired = 30;
  bool _sequenceReady = false;
  Timer? _wordStreamTimer;
  bool _isProcessingPrediction = false;

  final FlutterTts flutterTts = FlutterTts();

  // API endpoints for different categories
  String get _currentApiEndpoint {
    switch (_currentCategory) {
      case "Numbers":
        return '$url/gesture/numbers';
      case "Words":
        return '$url/gesture/words';
      case "Alphabets":
      default:
        return '$url/gesture/hands';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeTts();
    _generateSessionId();
    if (widget.isActive) {
      _initializeCamera();
    }
  }

  void _generateSessionId() {
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

    // Reset word session when stopping camera
    if (_currentCategory == "Words") {
      await _resetWordSession();
    }

    if (_cameraController != null) {
      await _cameraController?.dispose();
    }
    if (_isMounted) {
      setState(() {
        _isCameraReady = false;
      });
    }
  }

  Future<void> _resetWordSession() async {
    try {
      final response = await http.post(
        Uri.parse('$url/gesture/words/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'session_id': _sessionId}),
      );

      if (response.statusCode == 200) {
        print("✅ Word session reset successfully");
      }
    } catch (e) {
      print("❌ Error resetting word session: $e");
    }

    setState(() {
      _framesCollected = 0;
      _sequenceReady = false;
      _isProcessingPrediction = false;
      predictedCharacter = "Ready for word recognition";
      lastSpokenCharacter = "";
    });
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
    _wordStreamTimer?.cancel();

    if (_currentCategory == "Words") {
      // For words: continuous streaming every 0.5 seconds
      _wordStreamTimer =
          Timer.periodic(Duration(milliseconds: 500), (timer) async {
        if (!_stopPrediction &&
            _isMounted &&
            widget.isActive &&
            !_isProcessingPrediction) {
          await _predictWordGesture();
        }
      });
    } else {
      // For alphabets and numbers: single image every 3 seconds
      _predictionTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
        if (!_stopPrediction && _isMounted && widget.isActive) {
          await _predictStaticGesture();
        }
      });
    }
  }

  Future<void> _predictStaticGesture() async {
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

      var request =
          http.MultipartRequest('POST', Uri.parse(_currentApiEndpoint));
      request.files.add(http.MultipartFile.fromBytes('file', imageBytes,
          filename: "gesture.jpg"));

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseString = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseString);

        String character = "";

        if (_currentCategory == "Numbers") {
          if (jsonResponse["status"] == "success") {
            character = jsonResponse["predicted_character"] ?? "";
          } else {
            print("❌ Number API error: ${jsonResponse["message"]}");
            return;
          }
        } else if (_currentCategory == "Alphabets") {
          if (jsonResponse["status"] == "success") {
            character = jsonResponse["predicted_character"] ?? "";
          } else {
            print("❌ Alphabet API error: ${jsonResponse["message"]}");
            return;
          }
        }

        if (character.isNotEmpty &&
            character != predictedCharacter &&
            _isMounted) {
          setState(() => predictedCharacter = character);

          if (character != lastSpokenCharacter) {
            await flutterTts.stop();
            await flutterTts.speak(character);
            lastSpokenCharacter = character;
          }
        }
      } else {
        print("❌ API Error: ${response.statusCode}");
        print("❌ API Endpoint: $_currentApiEndpoint");

        if (response.statusCode == 404) {
          setState(() {
            predictedCharacter = "No hand detected";
          });
        } else if (response.statusCode == 500) {
          setState(() {
            predictedCharacter = "Server error";
          });
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

  Future<void> _predictWordGesture() async {
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

      var request =
          http.MultipartRequest('POST', Uri.parse(_currentApiEndpoint));
      request.fields['session_id'] = _sessionId;
      request.files.add(http.MultipartFile.fromBytes('file', imageBytes,
          filename: "gesture.jpg"));

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseString = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseString);

        if (jsonResponse["status"] == "success") {
          // Update sequence progress
          setState(() {
            _framesCollected = jsonResponse["frames_collected"] ?? 0;
            _sequenceReady = jsonResponse["sequence_ready"] ?? false;
          });

          // Handle predictions if sequence is ready
          if (_sequenceReady && jsonResponse["predictions"] != null) {
            var predictions = jsonResponse["predictions"];
            if (predictions is List && predictions.isNotEmpty) {
              String topWord = predictions[0]["word"] ?? "";
              double confidence = predictions[0]["confidence"] ?? 0.0;

              // Only update if confidence is reasonable
              if (confidence > 0.3 && topWord.isNotEmpty) {
                setState(() {
                  predictedCharacter =
                      "✅ $topWord (${(confidence * 100).toStringAsFixed(1)}%)";
                });

                if (topWord != lastSpokenCharacter) {
                  await flutterTts.stop();
                  await flutterTts.speak(topWord);
                  lastSpokenCharacter = topWord;
                }

                // ✅ AUTO-RESET: Reset sequence after successful prediction
                _isProcessingPrediction = true;
                await Future.delayed(
                    Duration(milliseconds: 2000)); // Show result for 2 seconds
                await _resetWordSession();
                _isProcessingPrediction = false;
              } else {
                // Low confidence - reset and try again
                setState(() {
                  predictedCharacter = "❌ Low confidence, try again";
                });
                await _resetWordSession();
              }
            }
          } else {
            // Show progress while collecting frames
            String progressText =
                "Collecting frames: $_framesCollected/$_framesRequired";
            if (_framesCollected >= _framesRequired) {
              progressText = "🔄 Processing...";
            }
            setState(() {
              predictedCharacter = progressText;
            });
          }
        } else {
          print("❌ Word API error: ${jsonResponse["message"]}");
          setState(() {
            predictedCharacter = "API Error: ${jsonResponse["message"]}";
          });
        }
      } else {
        print("❌ Word API Error: ${response.statusCode}");

        if (response.statusCode == 404) {
          setState(() {
            predictedCharacter = "👋 No hand detected";
          });
        } else if (response.statusCode == 500) {
          setState(() {
            predictedCharacter = "🔧 Server error";
          });
        } else {
          setState(() {
            predictedCharacter = "❌ Connection error ($response.statusCode)";
          });
        }
      }
    } catch (e) {
      print("❌ Word prediction error: $e");

      if (_isMounted) {
        setState(() {
          predictedCharacter = "🌐 Connection error";
        });
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
  }

  void _showCategorySelectionModal() {
    setState(() {
      _showCategoryModal = true;
    });

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
    });
  }

  void _selectCategory(String category) async {
    // Stop current prediction
    _stopPrediction = true;
    _predictionTimer?.cancel();
    _wordStreamTimer?.cancel();

    // Reset word session if switching from words
    if (_currentCategory == "Words") {
      await _resetWordSession();
    }

    // Generate new session ID for words
    if (category == "Words") {
      _generateSessionId();
    }

    setState(() {
      _currentCategory = category;
      predictedCharacter =
          category == "Words" ? "Ready for word recognition" : "";
      lastSpokenCharacter = "";
      _framesCollected = 0;
      _sequenceReady = false;
      _isProcessingPrediction = false;
    });

    Navigator.pop(context);

    // Restart prediction with new category
    if (_isMounted && widget.isActive) {
      _stopPrediction = false;
      _startPredictionTimer();
    }

    print("Selected category: $category");
    print("API Endpoint: $_currentApiEndpoint");
    if (category == "Words") {
      print("Session ID: $_sessionId");
    }
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
            subtitle: "1, 2, 3, ... (Single Image)",
            isSelected: _currentCategory == "Numbers",
            onTap: () => _selectCategory("Numbers"),
          ),

          _buildCategoryItem(
            icon: Icons.abc,
            title: "Alphabets",
            subtitle: "A, B, C, ... (Single Image)",
            isSelected: _currentCategory == "Alphabets",
            onTap: () => _selectCategory("Alphabets"),
          ),

          _buildCategoryItem(
            icon: Icons.text_fields,
            title: "Words",
            subtitle: "Complete words (Continuous Stream)",
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
    _wordStreamTimer?.cancel();
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

        // Category Button - Outside the prediction box
        Positioned(
          bottom: 120,
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
                if (_currentCategory == "Words")
                  Text(
                    "Frames: $_framesCollected/$_framesRequired",
                    style: TextStyle(
                      fontSize: 14,
                      color: _sequenceReady
                          ? Colors.greenAccent
                          : _framesCollected > 0
                              ? Colors.yellow
                              : Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 4),
                const Text(
                  "Predicted Character:",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  predictedCharacter,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
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

