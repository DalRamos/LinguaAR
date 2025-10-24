import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lingua_arv1/repositories/Api_repository.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:lingua_arv1/services/model_service.dart';

class TextTo3DTab extends StatefulWidget {
  final List<CameraDescription> cameras;
  final bool isActive;
  const TextTo3DTab({super.key, required this.cameras, required this.isActive});

  @override
  State<TextTo3DTab> createState() => _TextTo3DTabState();
}

class _TextTo3DTabState extends State<TextTo3DTab>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _textController = TextEditingController();
  List<String> modelsToShow = [];
  int _currentModelIndex = 0;
  bool _isAnimating = false;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isMale = true;

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  String _recognizedText = '';
  late AnimationController _animationController;
  bool _isMaleVoice = true;
  bool _isMounted = true;

  Timer? _animationTimer;
  Timer? _debounceTimer;
  Map<String, bool> _modelLoadingStates = {};
  bool _areAllModelsLoaded = false;

  late final GeminiService _geminiService;
  late final ModelService _modelService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _geminiService = GeminiService();
    _modelService = ModelService(_geminiService);

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
      debugPrint('Camera error: $e');
      if (_isMounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  void _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) => debugPrint('Speech status: $status'),
      onError: (error) => debugPrint('Speech error: $error'),
    );
    if (!available) {
      debugPrint('Speech-to-Text not available');
    }
  }

  void _initializeTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    _setVoice();
  }

  void _setVoice() async {
    List<dynamic> voices = await _flutterTts.getVoices;
    if (voices.isEmpty) return;

    String? selectedVoice =
        _isMaleVoice ? "fil-ph-x-fie-local" : "fil-ph-x-fic-local";

    await _flutterTts.setVoice({"name": selectedVoice, "locale": "fil-PH"});
  }

  void _speakText(String text) async {
    _setVoice();
    await _flutterTts.speak(text);
  }

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

  void _stopListening() async {
    if (!_isListening) return;
    setState(() => _isListening = false);
    _speech.stop();
    _animationController.stop();
    _animationController.reset();
  }

  void _refreshModelsFromText(String text) {
    _textController.text = text;
    _translateText();
  }

  void _translateText() {
    final inputText = _textController.text.trim();

    print('\n🎬 TRANSLATION FLOW STARTED');
    print('📝 USER INPUT: "$inputText"');

    if (inputText.isEmpty) {
      _stopLetterAnimation();
      setState(() {
        modelsToShow = [];
        _areAllModelsLoaded = false;
        _modelLoadingStates = {};
      });
      print('🛑 EMPTY INPUT: Cleared all models');
      print('🎬 TRANSLATION FLOW ENDED (Empty Input)\n');
      return;
    }

    // Use async/await to handle the Future from findMatchingModels
    _modelService.findMatchingModels(inputText).then((validModels) {
      print('📊 FINAL MODELS: $validModels');
      setState(() {
        modelsToShow = validModels;
        _currentModelIndex = 0;
        _areAllModelsLoaded = false;
        _modelLoadingStates = {};
        for (final m in validModels) {
          _modelLoadingStates[m] = false;
        }
      });

      _stopLetterAnimation();

      _preloadAllModels().then((_) {
        if (_isMounted && modelsToShow.length > 1 && _areAllModelsLoaded) {
          print('✨ ANIMATION: Starting sequential animation');
          _startSequentialAnimation();
        } else {
          print('ℹ️ ANIMATION: Single model or preload incomplete');
        }
        print('🎬 TRANSLATION FLOW COMPLETED\n');
      });
    }).catchError((error) {
      print('❌ TRANSLATION ERROR: $error');
      // If Gemini fails, show empty models
      setState(() {
        modelsToShow = [];
        _areAllModelsLoaded = false;
        _modelLoadingStates = {};
      });
      _stopLetterAnimation();
    });
  }

  Future<void> _preloadAllModels() async {
    if (modelsToShow.isEmpty) return;

    print('🔄 PRELOAD: Starting preload of ${modelsToShow.length} models');
    final completer = Completer<void>();
    int loadedCount = 0;

    for (final model in modelsToShow) {
      try {
        final url = _modelService.getModelUrl(model);
        if (url == null) {
          print('⚠️ PRELOAD: Model "$model" has no URL');
          setState(() {
            _modelLoadingStates[model] = true;
          });
          loadedCount++;
          if (loadedCount == modelsToShow.length &&
              !_areAllModelsLoaded &&
              _isMounted) {
            setState(() => _areAllModelsLoaded = true);
            if (!completer.isCompleted) completer.complete();
          }
          continue;
        }

        final image = Image.network(
          url,
          fit: BoxFit.contain,
        );

        final stream = image.image.resolve(ImageConfiguration.empty);
        late ImageStreamListener listener;
        listener = ImageStreamListener(
          (imageInfo, synchronousCall) {
            if (!_isMounted) return;
            setState(() {
              _modelLoadingStates[model] = true;
              loadedCount++;
            });
            print(
                '✅ PRELOAD: Loaded model "$model" ($loadedCount/${modelsToShow.length})');
            stream.removeListener(listener);
            if (loadedCount == modelsToShow.length &&
                !_areAllModelsLoaded &&
                _isMounted) {
              setState(() => _areAllModelsLoaded = true);
              print('🎉 PRELOAD: All models loaded successfully');
              if (!completer.isCompleted) completer.complete();
            }
          },
          onError: (exception, stackTrace) {
            if (!_isMounted) return;
            setState(() {
              _modelLoadingStates[model] = true;
              loadedCount++;
            });
            print('❌ PRELOAD: Failed to load model "$model"');
            stream.removeListener(listener);
            if (loadedCount == modelsToShow.length &&
                !_areAllModelsLoaded &&
                _isMounted) {
              setState(() => _areAllModelsLoaded = true);
              if (!completer.isCompleted) completer.complete();
            }
          },
        );

        stream.addListener(listener);
      } catch (e) {
        if (!_isMounted) return;
        setState(() {
          _modelLoadingStates[model] = true;
          loadedCount++;
        });
        if (loadedCount == modelsToShow.length &&
            !_areAllModelsLoaded &&
            _isMounted) {
          setState(() => _areAllModelsLoaded = true);
        }
      }
    }

    Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted && _isMounted) {
        setState(() {
          _areAllModelsLoaded = true;
        });
        print('⏰ PRELOAD: Timeout reached, forcing completion');
        if (!completer.isCompleted) completer.complete();
      }
    });

    return completer.future;
  }

  void _startSequentialAnimation() {
    if (!_areAllModelsLoaded || modelsToShow.isEmpty) return;

    print(
        '🎬 ANIMATION: Starting sequential display of ${modelsToShow.length} models');
    _isAnimating = true;

    void showNextModel(int index) {
      if (!_isAnimating || !_isMounted || index >= modelsToShow.length) {
        _isAnimating = false;
        print('🛑 ANIMATION: Ended at index $index');
        return;
      }

      setState(() {
        _currentModelIndex = index;
      });
      print(
          '🔄 ANIMATION: Showing model ${index + 1}/${modelsToShow.length}: ${modelsToShow[index]}');

      _animationTimer = Timer(const Duration(seconds: 3), () {
        showNextModel(index + 1);
      });
    }

    showNextModel(0);
  }

  void _replayAnimation() {
    if (modelsToShow.length > 1 && _areAllModelsLoaded) {
      print('🔁 ANIMATION: Replaying animation');
      _stopLetterAnimation();
      setState(() {
        _currentModelIndex = 0;
      });
      _startSequentialAnimation();
    }
  }

  void _stopLetterAnimation() {
    _isAnimating = false;
    _animationTimer?.cancel();
    _animationTimer = null;
    print('⏹️ ANIMATION: Stopped');
  }

  void _textToSpeech() {
    if (_textController.text.isNotEmpty) {
      _speakText(_textController.text);
    }
  }

  void _speechToText() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

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
    _debounceTimer?.cancel();
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
        if (_isCameraInitialized &&
            _cameraController != null &&
            widget.isActive)
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: CameraPreview(_cameraController!),
          )
        else
          Container(color: Colors.black),
        Column(
          children: [
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
                              if (!_areAllModelsLoaded &&
                                  modelsToShow.length > 1)
                                Column(
                                  children: [
                                    Text(
                                      'Loading models...',
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 20),
                                    CircularProgressIndicator(),
                                    SizedBox(height: 10),
                                    Text(
                                      '${_modelLoadingStates.values.where((loaded) => loaded).length}/${modelsToShow.length} models loaded',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.white70),
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  children: [
                                    Text(
                                      modelsToShow[_currentModelIndex],
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                    const SizedBox(height: 20),
                                    Container(
                                      height: 300,
                                      width: 300,
                                      child: _loadModel(
                                          modelsToShow[_currentModelIndex]),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        if (modelsToShow.length > 1 && _areAllModelsLoaded)
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
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.black.withOpacity(0.7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: Colors.white),
                    onPressed: _textToSpeech,
                  ),
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.red : Colors.white,
                          size: _isListening
                              ? 24 + (_animationController.value * 8)
                              : 24,
                        ),
                        onPressed: _speechToText,
                      );
                    },
                  ),
                  if (modelsToShow.length > 1 && _areAllModelsLoaded)
                    IconButton(
                      icon: Icon(
                        Icons.replay,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: _replayAnimation,
                    )
                  else if (modelsToShow.length > 1)
                    IconButton(
                      icon: Icon(
                        Icons.replay,
                        color: Colors.grey,
                        size: 28,
                      ),
                      onPressed: null,
                    )
                  else
                    const SizedBox(width: 48),
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
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.black.withOpacity(0.8),
              child: TextField(
                controller: _textController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Enter text or words',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'e.g., hello, mahal kita, rex',
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
                        _areAllModelsLoaded = false;
                        _modelLoadingStates = {};
                      });
                    },
                  ),
                ),
                onChanged: (text) {
                  // Cancel previous timer
                  _debounceTimer?.cancel();

                  // Set new timer with 500ms delay
                  _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                    if (text.isNotEmpty) {
                      _translateText();
                    } else {
                      _stopLetterAnimation();
                      setState(() {
                        modelsToShow = [];
                        _areAllModelsLoaded = false;
                        _modelLoadingStates = {};
                      });
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _loadModel(String modelKey) {
    final url = _modelService.getModelUrl(modelKey);

    if (url == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Model not found',
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            'Model: $modelKey',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      );
    }

    return Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
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
