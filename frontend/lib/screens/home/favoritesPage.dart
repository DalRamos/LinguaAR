import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:lingua_arv1/home/favorites/FavoritesList.dart';
import 'package:lingua_arv1/repositories/Config.dart';
import 'package:lingua_arv1/validators/token.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Map<String, dynamic>> _favorites = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final userId = await TokenService.getUserId();
      if (!mounted) return;

      if (userId == null) {
        setState(() {
          _error = 'No user id';
          _loading = false;
        });
        return;
      }

      final res = await http.get(
        Uri.parse('${BasicUrl.baseURL}/favorites/favorites/$userId'),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        setState(() {
          _favorites = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      } else {
        setState(() {
          _error = '${res.statusCode}: ${res.body}';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF273236) : const Color(0xFFFEFFFE),
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: isDark ? const Color(0xFF1D1D1D) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    'Failed to load favorites.\n$_error',
                    textAlign: TextAlign.center,
                  ),
                )
              : _favorites.isEmpty
                  ? const Center(child: Text('No favorites yet.'))
                  : FavoritesList(favorites: _favorites),
    );
  }
}
