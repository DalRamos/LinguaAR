import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lingua_arv1/Widgets/fsl_lesson_section.dart';
import 'package:lingua_arv1/screens/fsl_Quiz/lesson_flow_page.dart';
import 'package:shimmer/shimmer.dart';

void main() {
  runApp(MaterialApp(
    home: HomePage(),
    debugShowCheckedModeBanner: false,
  ));
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _trackKey = 'fsl_translate_track';
  bool _isLoading = true;

  final List<Map<String, dynamic>> topics = const [
    {
      'title': 'Daily Communication',
      'description': 'Essential phrases for everyday conversations.',
      'page': LessonFlowPage(category: "Daily Communication & Basic Phrases"),
    },
    {
      'title': 'Family',
      'description': 'Connect with loved ones.',
      'page': LessonFlowPage(category: "Family"),
    },
    {
      'title': 'Relationships',
      'description': 'Express feelings.',
      'page': LessonFlowPage(category: "Relationships"),
    },
    {
      'title': 'Travel, Food, and Environment',
      'description': 'Essential phrases for Travel',
      'page': LessonFlowPage(category: "Travel, Food, and Environment"),
    },
    {
      'title': 'Learning, Work, and Technology',
      'description':
          'Communicate in academic, professional, and digital settings.',
      'page': LessonFlowPage(category: "Learning, Work & Technology"),
    },
    {
      'title': 'Colors, numbers & Alphabet',
      'description': 'Basics of FSL.',
      'page': LessonFlowPage(category: "Colors, numbers & Alphabet"),
    },
    {
      'title': 'Interactive Learning and Emergency',
      'description':
          'Engage in learning activities and handle urgent situations.',
      'page': LessonFlowPage(category: "Emergency"),
    },
  ];

  @override
  void initState() {
    super.initState();
    // Simulate loading
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF273236) : const Color(0xFFFEFFFE),
      body: SafeArea(
        child: _isLoading
            ? _buildShimmerList()
            : FslLessonsSection(
                trackKey: _trackKey,
                topics: topics,
                progressColor: const Color(0xFF4A90E2),
              ),
      ),
    );
  }
}
