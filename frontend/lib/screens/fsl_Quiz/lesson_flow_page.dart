import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lingua_arv1/api/quiz_mappings.dart';
import 'package:lingua_arv1/bloc/Quiz/quiz_bloc.dart';
import 'package:lingua_arv1/bloc/Quiz/quiz_event.dart';
import 'package:lingua_arv1/screens/fsl_Quiz/answerFeedback_page.dart';
import 'package:lingua_arv1/screens/fsl_Quiz/LearningCardPage.dart';
import 'package:lingua_arv1/screens/fsl_Quiz/lessontitle.dart';
import 'package:lingua_arv1/repositories/lesson_flow_repositories/lesson_flow_repository_impl.dart';
import 'package:lingua_arv1/validators/token.dart';

class LessonFlowPage extends StatefulWidget {
  final String category;
  const LessonFlowPage({super.key, required this.category});

  @override
  State<LessonFlowPage> createState() => _LessonFlowPageState();
}

class _LessonFlowPageState extends State<LessonFlowPage> {
  late String? _userId;
  final LessonRepositoryImpl _repository = LessonRepositoryImpl();

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    _userId = await TokenService.getUserId();
    print('📱 LessonFlowPage - User ID: $_userId');
  }

  Future<void> _saveCompletionToDatabase() async {
    final isLoggedIn = await TokenService.isUserLoggedIn();
    
    if (!isLoggedIn || _userId == null) {
      print('❌ User not logged in, cannot save to database');
      return;
    }
    
    try {
      print('💾 Saving lesson completion: ${widget.category}');
      await _repository.completeLesson(_userId!, widget.category);
      print('✅ Lesson "${widget.category}" saved to database for user $_userId');
    } catch (e) {
      print('❌ Error saving to database: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizData = generateQuizData(widget.category);

    if (quizData.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lesson')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No quiz data available for this category.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      );
    }

    final first = quizData.first;
    final title = titleForCategory(widget.category);

    Future<void> onNext() async {
      final bloc = QuizBloc(quizData: quizData, category: widget.category);
      bloc.add(ProceedToQuiz());

      final bool? completed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: bloc,
            child: const AnswerFeedbackPage(),
          ),
        ),
      );


      if (completed == true) {
        await _saveCompletionToDatabase();
      }

      await bloc.close();
      

      if (mounted) {
        Navigator.of(context).pop(completed ?? false);
      }
    }

    return Learningcardpage(
      title: title,
      phrase: first['phrase']!,
      gifPath: first['gifPath']!,
      onNext: onNext,
    );
  }
}