import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lingua_arv1/bloc/Gif/gif_bloc.dart';
import 'package:lingua_arv1/bloc/Gif/gif_event.dart';
import 'package:lingua_arv1/bloc/Gif/gif_state.dart';
import 'package:lingua_arv1/repositories/Config.dart';
import 'package:lingua_arv1/validators/token.dart';

class SignSearchList extends StatefulWidget {
  final Map<String, String> mappings;
  final Map<String, bool> favorites;
  final String searchQuery;

  // Optional: add a callback for updating favorites if you want
  final void Function(String phrase)? onFavoriteChanged;

  const SignSearchList({
    Key? key,
    required this.mappings,
    required this.favorites,
    required this.searchQuery,
    this.onFavoriteChanged,
  }) : super(key: key);

  @override
  State<SignSearchList> createState() => _SignSearchListState();
}

class _SignSearchListState extends State<SignSearchList> {
  String? userId;
  String basicurl = BasicUrl.baseURL;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    userId = await TokenService.getUserId();
    setState(() {});
  }

  Future<void> _toggleFavorite(String phrase) async {
    if (userId == null) return;
    String mappedValue = widget.mappings[phrase] ?? "";
    if (mappedValue.isEmpty) return;
    bool isFavorite = widget.favorites[phrase] ?? false;
    String url = '$basicurl/favorites/favorites';
    Map<String, String> headers = {"Content-Type": "application/json"};
    Map<String, dynamic> body = {
      "user_id": userId,
      "item": phrase,
      "mapped_value": mappedValue
    };
    try {
      if (isFavorite) {
        final response = await http.delete(
          Uri.parse('$url/$userId/${Uri.encodeComponent(phrase)}'),
          headers: headers,
        );
        if (response.statusCode == 200) {
          setState(() {
            widget.favorites[phrase] = false;
          });
          widget.onFavoriteChanged?.call(phrase);
        }
      } else {
        final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode(body),
        );
        if (response.statusCode == 201) {
          setState(() {
            widget.favorites[phrase] = true;
          });
          widget.onFavoriteChanged?.call(phrase);
        }
      }
    } catch (e) {
      // error handling
    }
  }

  void _showGifPopup(BuildContext context, String phrase, String gifUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                phrase,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Container(
                width: 300, // Responsive width
                height: 220,
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.grey)),
                child: Image.network(gifUrl, fit: BoxFit.cover),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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
    // Search for words that START WITH the search query
    final filtered = widget.mappings.keys.where((phrase) {
      if (widget.searchQuery.isEmpty) return false;

      // Convert both to lowercase for case-insensitive search
      String searchLower = widget.searchQuery.toLowerCase();
      String phraseLower = phrase.toLowerCase();

      // Check if the phrase STARTS WITH the search query
      return phraseLower.startsWith(searchLower);
    }).toList();

    // Sort results alphabetically
    filtered.sort((a, b) => a.compareTo(b));

    return BlocProvider(
      create: (context) => GifBloc(),
      child: BlocListener<GifBloc, GifState>(
        listener: (context, state) {
          if (state is GifLoaded) {
            // Show the popup dialog with the GIF!
            _showGifPopup(context, state.phrase, state.gifUrl);

            // Reset Bloc state if needed (optional, depends on your Bloc logic)
            context.read<GifBloc>().add(ResetGifState());
          }
          if (state is GifError) {
            // Optionally handle errors here
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load GIF: ${state.message}')),
            );
          }
        },
        child: filtered.isEmpty
            ? Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No results found for "${widget.searchQuery}"',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : Column(
                children: filtered.map((phrase) {
                  bool isFavorite = widget.favorites[phrase] ?? false;
                  return Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(phrase,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.star : Icons.star_border,
                          color: isFavorite ? Colors.yellow : Colors.grey,
                        ),
                        onPressed: () => _toggleFavorite(phrase),
                      ),
                      onTap: () {
                        String publicId = widget.mappings[phrase] ?? '';
                        if (publicId.isNotEmpty) {
                          context.read<GifBloc>().add(
                              FetchGif(phrase: phrase, publicId: publicId));
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }
}
