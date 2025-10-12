import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:lingua_arv1/api/3d_models_mapping.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class TextTo3DTab extends StatefulWidget {
  final List<CameraDescription> cameras;
  final bool isActive;
  const TextTo3DTab({super.key, required this.cameras, required this.isActive});

  @override
  State<TextTo3DTab> createState() => _TextTo3DTabState();
}

class _TextTo3DTabState extends State<TextTo3DTab> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _textController = TextEditingController();
  List<String> modelsToShow = [];
  int _currentModelIndex = 0;
  bool _isAnimating = false;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isMale = true;
  
  // IDINAGDAG - Speech and TTS variables
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  String _recognizedText = '';
  late AnimationController _animationController;
  bool _isMaleVoice = true;
  bool _isMounted = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isActive) {
      _initializeCamera();
    }
    _initializeSpeech();
    _initializeTts();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
  }

  @override
  void didUpdateWidget(TextTo3DTab oldWidget) {
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

  Future<void> _stopCamera() async {
    if (_cameraController != null) {
      await _cameraController?.dispose();
      _cameraController = null;
    }
    if (_isMounted) {
      setState(() {
        _isCameraInitialized = false;
      });
    }
  }

  Future<void> _initializeCamera() async {
    if (!_isMounted || !widget.isActive) return;

    try {
      if (_cameraController != null) {
        await _cameraController!.dispose();
      }

      _cameraController = CameraController(
        widget.cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      if (!_isMounted || !widget.isActive) return;

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print('Camera error: $e');
      if (_isMounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  // IDINAGDAG - Speech initialization
  void _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) => debugPrint('Speech status: $status'),
      onError: (error) => debugPrint('Speech error: $error'),
    );
    if (!available) {
      debugPrint('Speech-to-Text not available');
    }
  }

  // IDINAGDAG - TTS initialization
  void _initializeTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    _setVoice();
  }

  // IDINAGDAG - Set voice based on gender
  void _setVoice() async {
    List<dynamic> voices = await _flutterTts.getVoices;
    if (voices.isEmpty) return;

    String? selectedVoice =
        _isMaleVoice ? "fil-ph-x-fie-local" : "fil-ph-x-fic-local";

    await _flutterTts.setVoice({"name": selectedVoice, "locale": "fil-PH"});
  }

  // IDINAGDAG - Speak text
  void _speakText(String text) async {
    _setVoice();
    await _flutterTts.speak(text);
  }

  // IDINAGDAG - Start listening
  void _startListening() async {
    if (_isListening) return;
    bool available = await _speech.initialize();
    if (!available) return;

    setState(() => _isListening = true);
    _speech.listen(
      onResult: (result) => setState(() {
        _recognizedText = result.recognizedWords;
        _refreshModelsFromText(_recognizedText);
      }),
    );
    _animationController.repeat(reverse: true);
  }

  // IDINAGDAG - Stop listening
  void _stopListening() async {
    if (!_isListening) return;
    setState(() => _isListening = false);
    _speech.stop();
    _animationController.stop();
    _animationController.reset();
  }

  // IDINAGDAG - Refresh models from recognized text
  void _refreshModelsFromText(String text) {
    _textController.text = text;
    _translateText();
  }

  void _translateText() {
    final inputText = _textController.text;
    final validModels = findMatchingModels(inputText);

    setState(() {
      modelsToShow = validModels;
      _currentModelIndex = 0;
    });

    _stopLetterAnimation();
    
    if (modelsToShow.length > 1) {
      _startLetterAnimation();
    }
  }

  void _startLetterAnimation() {
    _isAnimating = true;
    Future.delayed(const Duration(seconds: 5), () {
      if (_isAnimating && _isMounted) {
        setState(() {
          _currentModelIndex = (_currentModelIndex + 1) % modelsToShow.length;
        });
        _startLetterAnimation();
      }
    });
  }

  void _stopLetterAnimation() {
    _isAnimating = false;
  }

  // IDINAGDAG - Updated text to speech function
  void _textToSpeech() {
    if (_textController.text.isNotEmpty) {
      _speakText(_textController.text);
    }
  }

  // IDINAGDAG - Updated speech to text function
  void _speechToText() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  // IDINAGDAG - Toggle gender function
  void _toggleGender() {
    setState(() {
      _isMale = !_isMale;
      _isMaleVoice = _isMale;
      _setVoice();
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    _stopLetterAnimation();
    _cameraController?.dispose();
    _animationController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera Background (AR) - BINAGO: Proper camera handling
        if (_isCameraInitialized && _cameraController != null && widget.isActive)
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: CameraPreview(_cameraController!),
          )
        else
          Container(color: Colors.black),

        Column(
          children: [
            // 3D Model Viewing Area
            Expanded(
              flex: 7,
              child: modelsToShow.isEmpty
                  ? Center(
                      child: Text(
                        'Type or speak to view 3D sign language models',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    )
                  : Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                modelsToShow[_currentModelIndex],
                                style: TextStyle(
                                  fontSize: 24, 
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                height: 300,
                                width: 300,
                                child: FutureBuilder(
                                  future: _loadModel(modelsToShow[_currentModelIndex]),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return Center(child: CircularProgressIndicator());
                                    } else if (snapshot.hasError) {
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.error, size: 48, color: Colors.red),
                                            SizedBox(height: 16),
                                            Text(
                                              'Error loading model',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      return snapshot.data as Widget;
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        if (modelsToShow.length > 1)
                          Positioned(
                            top: 20,
                            right: 20,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_currentModelIndex + 1}/${modelsToShow.length}',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),

            // Icons Row - BINAGO: Single gender toggle icon
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.black.withOpacity(0.7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Text-to-speech icon (kaliwa)
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: Colors.white),
                    onPressed: _textToSpeech,
                  ),
                  
                  // Speech-to-text icon with animation (gitna)
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.red : Colors.white,
                          size: _isListening ? 24 + (_animationController.value * 8) : 24,
                        ),
                        onPressed: _speechToText,
                      );
                    },
                  ),
                  
                  // Gender toggle icon (kanan) - BINAGO: Single icon na nagto-toggle
                  IconButton(
                    icon: Icon(
                      _isMale ? Icons.male : Icons.female,
                      color: _isMale ? Colors.blue : Colors.pink,
                      size: 32,
                    ),
                    onPressed: _toggleGender,
                  ),
                ],
              ),
            ),

            // Input Area (Automatic Translate - No Button)
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.black.withOpacity(0.8),
              child: TextField(
                controller: _textController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Enter text or words',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'e.g., rex, hello, mahal kita',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.6),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      _textController.clear();
                      _stopLetterAnimation();
                      setState(() {
                        modelsToShow = [];
                        _recognizedText = '';
                      });
                    },
                  ),
                ),
                onChanged: (text) {
                  // AUTOMATIC TRANSLATE
                  if (text.isNotEmpty) {
                    _translateText();
                  } else {
                    setState(() {
                      modelsToShow = [];
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<Widget> _loadModel(String modelKey) async {
    final url = letterModels[modelKey];
    
    return Image.network(
      url!,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Failed to load model',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'Model: $modelKey',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        );
      },
    );
  }
}