import 'package:flutter/material.dart';
import 'package:lingua_arv1/Widgets/ChapterTimelineList.dart';
import 'package:lingua_arv1/Widgets/unitHeader.dart';
import 'package:lingua_arv1/screens/fsl_Quiz/lesson_flow_page.dart';
import 'package:lingua_arv1/services/progress_store.dart';
import 'package:lingua_arv1/repositories/lesson_flow_repositories/lesson_flow_repository_impl.dart';
import 'package:lingua_arv1/validators/token.dart';

class FslLessonsSection extends StatefulWidget {
  final String trackKey;
  final String headerTitle;
  final Color? progressColor;
  final List<Map<String, dynamic>> topics;

  const FslLessonsSection({
    super.key,
    required this.trackKey,
    required this.topics,
    this.headerTitle = ' Chapter: Filipino Sign Language Lessons',
    this.progressColor,
  });

  @override
  State<FslLessonsSection> createState() => _FslLessonsSectionState();
}

class _FslLessonsSectionState extends State<FslLessonsSection> {
  int _currentIndex = 0;
  String? _userId;
  final LessonRepositoryImpl _repository = LessonRepositoryImpl();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserAndProgress();
  }

  Future<void> _loadUserAndProgress() async {
    setState(() {
      _isLoading = true;
    });

    _userId = await TokenService.getUserId();

    print('🔍 Loading progress for user: $_userId');

    final localIndex = await ProgressStore.getCurrentIndex(widget.trackKey);
    int finalIndex = localIndex;

    if (_userId != null) {
      try {
        final backendIndex = await _getLastCompletedLessonIndex();
        print(
            '📊 Local progress: $localIndex, Backend progress: $backendIndex');

        // If backend has more progress, use backend progress + 1 (next available lesson)
        if (backendIndex > localIndex) {
          finalIndex = backendIndex +
              1; 
          print('🔄 Backend has more progress, updating to: $finalIndex');
        } else if (backendIndex >= 0) {
          finalIndex =
              localIndex > backendIndex + 1 ? localIndex : backendIndex + 1;
          print('⚡ Adjusted final index to: $finalIndex');
        }

        finalIndex = finalIndex.clamp(0, widget.topics.length - 1);

        if (finalIndex != localIndex) {
          await ProgressStore.setCurrentIndex(widget.trackKey, finalIndex);
          print('💾 Updated local storage from $localIndex to $finalIndex');
        }
      } catch (e) {
        print('❌ Error syncing with backend, using local progress: $e');
        finalIndex = localIndex;
      }
    } else {
      finalIndex = localIndex;
    }

    if (mounted) {
      setState(() {
        _currentIndex = finalIndex;
        _isLoading = false;
      });
    }

    print('✅ Final current index: $_currentIndex');
  }

  Future<int> _getLastCompletedLessonIndex() async {
    if (_userId == null) return -1;

    int lastCompletedIndex = -1;

    print('🔄 Checking backend progress for user: $_userId');
    print('📚 Total lessons to check: ${widget.topics.length}');

    // Check each lesson in order to find the last completed one
    for (int i = 0; i < widget.topics.length; i++) {
      final topic = widget.topics[i];
      final category = _extractCategoryFromTopic(topic);

      if (category != null) {
        try {
          print('🔍 Checking lesson $i: $category');
          final progress =
              await _repository.getLessonStatus(_userId!, category);

          if (progress.completed) {
            lastCompletedIndex = i;
            print('✅ Lesson $i ($category) is COMPLETED in backend');
          } else {
            print('❌ Lesson $i ($category) is NOT completed in backend');
          }
        } catch (e) {
          print('⚠️ Error checking lesson $i ($category): $e');
        }
      }
    }

    print('📊 Last completed lesson index from backend: $lastCompletedIndex');
    return lastCompletedIndex;
  }

  Future<void> _saveLessonCompletionToDatabase(int lessonIndex) async {
    if (_userId == null) {
      print('❌ User not logged in, skipping database save');
      return;
    }

    try {
      final topic = widget.topics[lessonIndex];
      final category = _extractCategoryFromTopic(topic);

      if (category != null) {
        print('💾 Saving lesson to database: $category');
        await _repository.completeLesson(_userId!, category);
        print('✅ Lesson "$category" saved to database');
      }
    } catch (e) {
      print('❌ Error saving lesson to database: $e');
    }
  }

  String? _extractCategoryFromTopic(Map<String, dynamic> topic) {
    final page = topic['page'];
    if (page is LessonFlowPage) {
      return page.category;
    }
    return null;
  }

  void _showLockedSnack() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Finish the previous lesson to unlock this one.'),
        duration: Duration(milliseconds: 1400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      children: [
        UnitHeader(
          title: widget.headerTitle,
          currentIndex: _currentIndex,
          total: widget.topics.length,
          dense: true,
          progressColor: widget.progressColor ?? const Color(0xFF4A90E2),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ChapterTimelineList(
              topics: widget.topics,
              currentIndex: _currentIndex,
              onOpen: (index, topic) async {
                if (index > _currentIndex) {
                  _showLockedSnack();
                  return;
                }

                final bool? completed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => topic['page'] as Widget),
                );

                if (completed == true) {
                  await _saveLessonCompletionToDatabase(index);

                  final nextIndex = (_currentIndex < widget.topics.length - 1)
                      ? _currentIndex + 1
                      : _currentIndex;

                  if (nextIndex != _currentIndex) {
                    await ProgressStore.setCurrentIndex(
                        widget.trackKey, nextIndex);

                    if (mounted) {
                      setState(() {
                        _currentIndex = nextIndex;
                      });
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Lesson completed! Next lesson unlocked.'),
                        duration: Duration(milliseconds: 1400),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
