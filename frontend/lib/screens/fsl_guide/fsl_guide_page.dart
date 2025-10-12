import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lingua_arv1/screens/fsl_guide/daily_communication/alphabet_numbers_page.dart';
import 'package:lingua_arv1/screens/fsl_guide/daily_communication/pronouns_page.dart';
import 'package:lingua_arv1/screens/fsl_guide/daily_communication/common_expressions_page.dart';
import 'package:lingua_arv1/screens/fsl_guide/daily_communication/basic_phrases_page.dart';
import 'package:lingua_arv1/screens/fsl_guide/family_relationships/family_friends_page.dart';
import 'package:lingua_arv1/screens/fsl_guide/family_relationships/relationships_page.dart';
import 'package:lingua_arv1/screens/fsl_guide/learning_work_technology/education_page.dart';
import 'package:lingua_arv1/screens/fsl_guide/learning_work_technology/technology_page.dart';
import 'package:lingua_arv1/screens/fsl_guide/learning_work_technology/work_profession_page.dart';
import 'package:lingua_arv1/screens/fsl_guide/travel_food_environment/food_drinks_page.dart';
import 'package:lingua_arv1/screens/fsl_guide/travel_food_environment/nature_environment_page.dart';
import 'package:lingua_arv1/screens/fsl_guide/travel_food_environment/transportation_page.dart';
import 'package:lingua_arv1/screens/fsl_guide/interactive_learning_emergency/shape_colors_page.dart';
import 'package:lingua_arv1/widgets/grid_view.dart';
import 'package:lingua_arv1/widgets/card_tile.dart';
import 'package:lingua_arv1/widgets/section_title.dart';
import 'package:lingua_arv1/screens/fsl_guide/fsl_sign_search.dart';
import 'package:lingua_arv1/api/combined_mappings.dart';
import 'package:lingua_arv1/bloc/Gif/gif_bloc.dart';
import 'package:lingua_arv1/bloc/Gif/gif_event.dart';
import 'package:lingua_arv1/bloc/Gif/gif_state.dart';
import 'package:lingua_arv1/validators/token.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';

class FSLGuidePage extends StatefulWidget {
  @override
  _FSLGuidePageState createState() => _FSLGuidePageState();
}

class _FSLGuidePageState extends State<FSLGuidePage> {
  late ScrollController _scrollController;
  Color appBarColor = Color(0xFFFEFFFE);
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  Map<String, bool> favorites = {};
  bool _isDialogOpen = false;
  bool _isLoadingFavorites = true;

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
    _loadFavorites();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    String? userId = await TokenService.getUserId();
    if (userId != null) {
      // Simulate loading delay
      await Future.delayed(Duration(milliseconds: 1000));
      // In real implementation, fetch favorites from API
      setState(() {
        favorites = {}; // Initialize with fetched favorites
        _isLoadingFavorites = false;
      });
    } else {
      setState(() => _isLoadingFavorites = false);
    }
  }

  void _showGifDialog(
      BuildContext context, String phrase, String gifUrl) async {
    _isDialogOpen = true;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
    _isDialogOpen = false;
    context.read<GifBloc>().add(ResetGifState());
  }

  Widget _buildShimmerGrid(int itemCount, bool isDarkMode) {
    Color baseColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300;
    Color highlightColor =
        isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100;

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(),
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
      child: BlocListener<GifBloc, GifState>(
        listener: (context, state) {
          if (state is GifLoaded && !_isDialogOpen) {
            _showGifDialog(context, state.phrase, state.gifUrl);
          }
        },
        child: Scaffold(
          backgroundColor: isDarkMode ? Color(0xFF273236) : Color(0xFFFEFFFE),
          body: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: appBarColor,
                elevation: 4,
                expandedHeight: kToolbarHeight,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    'Filipino Sign Language Guides',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      color: isDarkMode
                          ? Colors.white
                          : (appBarColor == const Color(0xFFFEFFFE)
                              ? Colors.black
                              : Colors.white),
                    ),
                  ),
                ),
              ),
            ],
            body: Padding(
              padding: EdgeInsets.all(screenWidth * 0.02),
              child: ListView(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search sign words...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor:
                            isDarkMode ? Color(0xFF191E20) : Colors.grey[200],
                      ),
                      onChanged: (value) {
                        setState(() => searchQuery = value.trim());
                      },
                    ),
                  ),
                  if (_isLoadingFavorites)
                    _buildShimmerGrid(6, isDarkMode)
                  else if (searchQuery.isNotEmpty)
                    SignSearchList(
                      mappings: combinedMappings,
                      favorites: favorites,
                      searchQuery: searchQuery,
                      onFavoriteChanged: (phrase) => setState(() {}),
                    )
                  else ...[
                    SectionTitle(title: 'Family, Relationships & Social Life'),
                    GridViewBuilder.build(context, [
                      CardTile(
                          icon: Icons.family_restroom,
                          text: 'Family & Friends',
                          nextPage: FamilyFriendsPage(),
                          iconColor: isDarkMode
                              ? Color(0xFF191E20)
                              : Color(0xFFACCFFB)),
                      CardTile(
                          icon: Icons.favorite,
                          text: 'Relationships',
                          nextPage: RelationshipsPage(),
                          iconColor:
                              isDarkMode ? Colors.grey : Color(0xFFFEE6DF)),
                    ]),
                    SectionTitle(title: 'Learning & Work'),
                    GridViewBuilder.build(context, [
                      CardTile(
                          icon: Icons.school,
                          text: 'Education',
                          nextPage: EducationPage(),
                          iconColor:
                              isDarkMode ? Colors.grey : Color(0xFFFEE6DF)),
                      CardTile(
                          icon: Icons.work,
                          text: 'Work & Profession',
                          nextPage: WorkProfessionPage(),
                          iconColor: isDarkMode
                              ? Color(0xFF191E20)
                              : Color(0xFFC3CDD1)),
                    ]),
                    SectionTitle(title: 'Food & Environment'),
                    GridViewBuilder.build(context, [
                      CardTile(
                          icon: Icons.local_dining,
                          text: 'Food & Drinks',
                          nextPage: FoodDrinksPage(),
                          iconColor: isDarkMode
                              ? Color(0xFF191E20)
                              : Color(0xFFACCFFB)),
                      CardTile(
                          icon: Icons.park,
                          text: 'Emergency and Nature',
                          nextPage: NatureEnvironmentPage(),
                          iconColor:
                              isDarkMode ? Colors.grey : Color(0xFFF4ABAA)),
                    ]),
                    SectionTitle(title: 'Transportation & Technology'),
                    GridViewBuilder.build(context, [
                      CardTile(
                          icon: Icons.directions_bus,
                          text: 'Transportation',
                          nextPage: TransportationPage(),
                          iconColor:
                              isDarkMode ? Colors.grey : Color(0xFFFEE6DF)),
                      CardTile(
                          icon: Icons.computer,
                          text: 'Technology',
                          nextPage: TechnologyPage(),
                          iconColor: isDarkMode
                              ? Color(0xFF191E20)
                              : Color(0xFFC3CDD1)),
                    ]),
                    SectionTitle(title: 'Daily Communication'),
                    GridViewBuilder.build(context, [
                      CardTile(
                          icon: Icons.language,
                          text: 'Pronouns',
                          nextPage: PronounsPage(),
                          iconColor: isDarkMode
                              ? Color(0xFF191E20)
                              : Color(0xFFC3CDD1)),
                      CardTile(
                          icon: Icons.chat,
                          text: 'Basic Phrases',
                          nextPage: BasicPhrasesPage(),
                          iconColor:
                              isDarkMode ? Colors.grey : Color(0xFFACCFFB)),
                    ]),
                    SectionTitle(title: 'Interactive Learning & Emergency'),
                    GridViewBuilder.build(context, [
                      CardTile(
                          icon: Icons.palette,
                          text: 'Shape & Colors',
                          nextPage: ShapeColorsPage(),
                          iconColor:
                              isDarkMode ? Colors.grey : Color(0xFFF4ABAA)),
                      CardTile(
                          icon: Icons.numbers,
                          text: 'Alphabet & Numbers',
                          nextPage: AlphabetNumbersPage(),
                          iconColor: isDarkMode
                              ? Color(0xFF191E20)
                              : Color(0xFFFEE6DF)),
                    ]),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
