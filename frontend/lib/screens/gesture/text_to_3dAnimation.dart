import 'package:flutter/material.dart';
import 'package:lingua_arv1/api/3d_models_mapping.dart';

class TextTo3DTab extends StatefulWidget {
  final bool isActive;
  const TextTo3DTab({super.key, required this.isActive});

  @override
  State<TextTo3DTab> createState() => _TextTo3DTabState();
}

class _TextTo3DTabState extends State<TextTo3DTab> {
  final TextEditingController _textController = TextEditingController();
  List<String> modelsToShow = [];
  int _currentModelIndex = 0;
  bool _isAnimating = false;

  void _translateText() {
    final inputText = _textController.text;
    final validModels = findMatchingModels(inputText);

    setState(() {
      modelsToShow = validModels;
      _currentModelIndex = 0;
    });

    // Stop any existing animation
    _stopLetterAnimation();
    
    // Start showing models one by one if we have multiple
    if (modelsToShow.length > 1) {
      _startLetterAnimation();
    }
  }

  void _startLetterAnimation() {
    _isAnimating = true;
    Future.delayed(const Duration(seconds: 5), () {
      if (_isAnimating && mounted) {
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

  @override
  void dispose() {
    _textController.dispose();
    _stopLetterAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 3D Model Viewing Area
        Expanded(
          flex: 7,
          child: modelsToShow.isEmpty
              ? Center(
                  child: Text(
                    'Type text and press Translate to view 3D models',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                )
              : Stack(
                  children: [
                    // Current model display
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
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                      child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.error,
                                            size: 48, color: Colors.red),
                                        SizedBox(height: 16),
                                        Text(
                                          'Error loading model',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Make sure to update the Google Drive URLs',
                                          style: TextStyle(color: Colors.white70),
                                          textAlign: TextAlign.center,
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
                    
                    // Model counter
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

        // Input Area
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.grey[900],
          child: Column(
            children: [
              TextField(
                controller: _textController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Enter text or words',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      _textController.clear();
                      _stopLetterAnimation();
                      setState(() {
                        modelsToShow = [];
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _translateText,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text(
                  'TRANSLATE',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<Widget> _loadModel(String modelKey) async {
    final url = letterModels[modelKey];
    
    // For GIF models
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
            SizedBox(height: 8),
            Text(
              'Check your Google Drive URL',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        );
      },
    );
  }
}