import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:lingua_arv1/api/family_friends.dart';
import 'package:lingua_arv1/bloc/Gif/gif_bloc.dart';
import 'package:lingua_arv1/bloc/Gif/gif_event.dart';
import 'package:lingua_arv1/bloc/Gif/gif_state.dart';
import 'package:lingua_arv1/repositories/Config.dart';
import 'package:lingua_arv1/validators/token.dart';
import 'package:shimmer/shimmer.dart';

class FamilyFriendsPage extends StatefulWidget {
  @override
  _FamilyFriendsPageState createState() => _FamilyFriendsPageState();
}

class _FamilyFriendsPageState extends State<FamilyFriendsPage> {
  final List<String> phrases = familyFriendsMappings.keys.toList();
  String? userId;
  Map<String, bool> favorites = {};
  String basicurl = BasicUrl.baseURL;
  bool _isLoadingFavorites = true;

  late ScrollController _scrollController;
  Color appBarColor = Color(0xFFFEFFFE);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
      setState(() {
        appBarColor = _scrollController.offset > 50
            ? const Color(0xFF4A90E2)
            : (isDarkMode ? Color(0xFF273236) : const Color(0xFFFEFFFE));
      });
    });
    _loadUserId();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    userId = await TokenService.getUserId();
    if (userId != null) await _fetchFavorites();

    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _isLoadingFavorites = false);
  }

  Future<void> _fetchFavorites() async {
    if (userId == null) return;
    try {
      final response =
          await http.get(Uri.parse('$basicurl/favorites/favorites/$userId'));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          favorites = {for (var fav in data) fav['item']: true};
        });
      } else {
        setState(() => favorites = {});
      }
    } catch (e) {
      print("Exception fetching favorites: $e");
    }
  }

  Future<void> _toggleFavorite(String phrase) async {
    if (userId == null) return;

    String mappedValue = familyFriendsMappings[phrase] ?? "";
    if (mappedValue.isEmpty) return;

    bool isFavorite = favorites[phrase] ?? false;
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
        if (response.statusCode == 200)
          setState(() => favorites[phrase] = false);
      } else {
        final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode(body),
        );
        if (response.statusCode == 201)
          setState(() => favorites[phrase] = true);
      }
    } catch (e) {
      print("Exception in _toggleFavorite: $e");
    }
  }

  void _showGifPopup(BuildContext context, String phrase, String gifUrl) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(phrase,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Container(
              width: 500,
              height: 410,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: Image.network(gifUrl, fit: BoxFit.cover),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList(bool isDarkMode) {
    Color baseColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300;
    Color highlightColor =
        isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100;

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Card(
            elevation: 5,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Container(height: 16, width: 120, color: Colors.white),
              trailing: Icon(Icons.star, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_scrollController.hasClients && _scrollController.offset > 50) {
      appBarColor = const Color(0xFF4A90E2);
    } else {
      appBarColor = isDarkMode
          ? const Color.fromARGB(255, 29, 29, 29)
          : const Color(0xFFFEFFFE);
    }

    return BlocProvider(
      create: (_) => GifBloc(),
      child: Scaffold(
        backgroundColor:
            isDarkMode ? Color(0xFF273236) : const Color(0xFFFEFFFE),
        body: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: true,
                backgroundColor: appBarColor,
                elevation: 4,
                expandedHeight: kToolbarHeight,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    'Family and Friends',
                    style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        color: isDarkMode
                            ? Colors.white
                            : (appBarColor == const Color(0xFFFEFFFE)
                                ? Colors.black
                                : Colors.white)),
                  ),
                ),
              ),
            ];
          },
          body: _isLoadingFavorites
              ? _buildShimmerList(isDarkMode)
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: phrases.length,
                  itemBuilder: (context, index) {
                    String phrase = phrases[index];
                    bool isFavorite = favorites[phrase] ?? false;
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
                          String publicId = familyFriendsMappings[phrase] ?? '';
                          if (publicId.isNotEmpty) {
                            context.read<GifBloc>().add(
                                FetchGif(phrase: phrase, publicId: publicId));
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
        bottomSheet: BlocBuilder<GifBloc, GifState>(
          builder: (context, state) {
            if (state is GifLoading)
              return Center(child: CircularProgressIndicator());
            if (state is GifLoaded) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showGifPopup(context, state.phrase, state.gifUrl);
                context.read<GifBloc>().add(ResetGifState());
              });
            }
            if (state is GifError) {
              return Center(
                  child:
                      Text(state.message, style: TextStyle(color: Colors.red)));
            }
            return SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
