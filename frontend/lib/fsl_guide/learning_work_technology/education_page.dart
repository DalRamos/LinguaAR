import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // For CancelToken

class EducationPage extends StatefulWidget {
  @override
  State<EducationPage> createState() => _EducationPageState();
}

class _EducationPageState extends State<EducationPage> {
  String _gifUrl = '';
  bool _isLoading = false;
  String _errorMessage = '';
  String _currentPhrase = ''; // New variable to store the current phrase
  http.Client? _httpClient;

  final List<String> phrases = [
    "Krayola",
    "Pambura",
    "Gunting",
    "Bag",
    "Papel",
    "Sapatos",
    "Uniporme",
    "Paaralan",
    "Itim na Pisara",
    "Upuan",
    "Watawat",
    "Silid Aralan",
    "Itim na Sapatos",
    "Lapis",
  ];

  @override
  void dispose() {
    // Cancel any ongoing requests
    _httpClient?.close();
    super.dispose();
  }

  Future<void> _fetchGif(String phrase) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _gifUrl = ''; // Clear previous GIF
      _currentPhrase = phrase; // Set the current phrase
    });

    String url = '';
    String publicId = '';
    String imageUrl = '';

    switch (phrase) {
      case "Krayola":
        imageUrl =
            "https://res.cloudinary.com/dqthtm7gt/image/upload/v1739467789/LinguaAR/Anthony/Relasyon/Valentines-book.gif";
        publicId = "LinguaAR/Zhyrex/Education/crayons";
        break;
      case "Pambura":
        imageUrl =
            "https://res.cloudinary.com/dqthtm7gt/image/upload/v1739467811/LinguaAR/Anthony/Relasyon/Valentines-card.gif";
        publicId = "LinguaAR/Zhyrex/Education/pambura";
        break;
      case "Gunting":
        imageUrl =
            "https://res.cloudinary.com/dqthtm7gt/image/upload/v1739467846/LinguaAR/Anthony/Relasyon/Valentines-day.gif";
        publicId = "LinguaAR/Zhyrex/Education/gunting";
        break;
      case "Bag":
        imageUrl =
            "https://res.cloudinary.com/dqthtm7gt/image/upload/v1739467884/LinguaAR/Anthony/Relasyon/Bulaklak.gif";
        publicId = "LinguaAR/Zhyrex/Education/bag";
        break;
      case "Papel":
        imageUrl =
            "https://res.cloudinary.com/dqthtm7gt/image/upload/v1739467903/LinguaAR/Anthony/Relasyon/Halik.gif";
        publicId = "LinguaAR/Zhyrex/Education/papel";
        break;
      case "Sapatos":
        imageUrl =
            "https://res.cloudinary.com/dqthtm7gt/image/upload/v1739467827/LinguaAR/Anthony/Relasyon/Nobyo.gif";
        publicId = "LinguaAR/Zhyrex/Education/sapatos";
        break;
      case "Uniporme":
        imageUrl =
            "https://res.cloudinary.com/dqthtm7gt/image/upload/v1739467925/LinguaAR/Anthony/Relasyon/Nobya.gif";
        publicId = "LinguaAR/Zhyrex/Education/uniforme";
        break;
      case "Paaralan":
        imageUrl =
            "https://res.cloudinary.com/dqthtm7gt/image/upload/v1739467925/LinguaAR/Anthony/Relasyon/Nobya.gif";
        publicId = "LinguaAR/Zhyrex/Education/paaralan";
        break;
      case "Itim na Pisara":
        imageUrl =
            "https://res.cloudinary.com/dqthtm7gt/image/upload/v1739467940/LinguaAR/Anthony/Relasyon/Mahal-kita.gif";
        publicId = "LinguaAR/Zhyrex/Education/blackborad";
        break;
      case "Upuan":
        imageUrl =
            "https://res.cloudinary.com/dqthtm7gt/image/upload/v1739467940/LinguaAR/Anthony/Relasyon/Mahal-kita.gif";
        publicId = "LinguaAR/Zhyrex/Education/upuan";
        break;
      case "Watawat":
        imageUrl =
            "https://res.cloudinary.com/dqthtm7gt/image/upload/v1739467940/LinguaAR/Anthony/Relasyon/Mahal-kita.gif";
        publicId = "LinguaAR/Zhyrex/Education/watawat";
        break;
      case "Silid Aralan":
        imageUrl =
            "https://res.cloudinary.com/dqthtm7gt/image/upload/v1739467940/LinguaAR/Anthony/Relasyon/Mahal-kita.gif";
        publicId = "LinguaAR/Zhyrex/Education/silidaralan";
        break;
      case "Itim na Sapatos":
        imageUrl =
            "https://res.cloudinary.com/dqthtm7gt/image/upload/v1739467940/LinguaAR/Anthony/Relasyon/Mahal-kita.gif";
        publicId = "LinguaAR/Zhyrex/Education/balckshoes";
        break;
      case "Lapis":
        imageUrl =
            "https://res.cloudinary.com/dqthtm7gt/image/upload/v1739467940/LinguaAR/Anthony/Relasyon/Mahal-kita.gif";
        publicId = "LinguaAR/Zhyrex/Education/lapis";
        break;
      default:
        setState(() {
          _isLoading = false;
          _errorMessage = 'No GIF found for this phrase.';
        });
        return;
    }

    if (publicId.isNotEmpty) {
      url = 'http://192.168.157.7:5000/cloudinary/get_gif?public_id=$publicId';
    } else if (imageUrl.isNotEmpty) {
      url = 'http://192.168.157.7:5000/cloudinary/get_gif?url=$imageUrl';
    }

    _httpClient = http.Client(); // Initialize HTTP client

    try {
      final response = await _httpClient!.get(Uri.parse(url)).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        setState(() {
          _gifUrl = jsonResponse['gif_url'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to fetch GIF from server.';
        });
      }
    } catch (error) {
      if (error is TimeoutException) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Request timed out. Please try again.';
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error occurred: $error';
        });
      }
    } finally {
      _httpClient?.close(); // Close the HTTP client
    }
  }

  void _showGifPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min, // Use minimum space
            children: [
              // Text above the container
              Text(
                _currentPhrase,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10), // Add some spacing
              // Container for the GIF
              Container(
                width: 500, // Fixed width for the container
                height: 410, // Fixed height for the container
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_gifUrl.isNotEmpty)
                      Image.network(
                        _gifUrl,
                        fit: BoxFit
                            .cover, // Ensure the GIF fits inside the container
                      ),
                    if (_isLoading)
                      CircularProgressIndicator(), // Show loading indicator
                    if (_errorMessage.isNotEmpty)
                      Center(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    if (_gifUrl.isEmpty && !_isLoading && _errorMessage.isEmpty)
                      Center(
                        child: Text(
                          'GIF will appear here',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the pop-up
              },
              child: Text('Back'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Education'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Cancel ongoing requests and pop the page
            _httpClient?.close();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: ListView.builder(
        itemCount: phrases.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(phrases[index]),
            onTap: () async {
              await _fetchGif(phrases[index]); // Fetch the GIF
              _showGifPopup(context); // Show the pop-up
            },
          );
        },
      ),
    );
  }
}
