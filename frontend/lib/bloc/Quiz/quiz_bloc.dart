import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:lingua_arv1/api/basic_phrases.dart';
import 'package:lingua_arv1/repositories/Config.dart';
import 'package:lingua_arv1/model/Quiz_result.dart';
import 'quiz_event.dart';
import 'quiz_state.dart';

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final List<Map<String, String>> quizData;
  final String category; // Add category field
  final Map<String, String> _gifCache = {}; // Caching GIFs
  int currentIndex = 0;
  int correctCount = 0;
  int wrongCount = 0;
  bool isAnswered = false;

  QuizBloc({required this.quizData, required this.category}) : super(QuizInitial()) {
    // Validate quizData before starting
    if (quizData.isEmpty) {
      emit(QuizError(message: "No quiz data available for category: $category"));
    } else {
      on<NextQuestion>(_handleNextQuestion);
      on<CheckAnswer>(_handleCheckAnswer);
      on<FetchGif>(_handleFetchGif);

      // Start the quiz by fetching the first GIF
      add(FetchGif(
        phrase: quizData[currentIndex]['phrase']!,
        publicId: quizData[currentIndex]['gifPath'] ?? "",
      ));
    }
  }

  void _handleNextQuestion(NextQuestion event, Emitter<QuizState> emit) {
    if (currentIndex < quizData.length - 1) {
      currentIndex++;
      isAnswered = false;

      emit(QuizLoading());

      // Fetch new GIF based on the new question
      String phrase = quizData[currentIndex]['phrase']!;
      add(FetchGif(phrase: phrase, publicId: quizData[currentIndex]['gifPath'] ?? ""));
    } else {
      // ✅ Emit QuizCompleted state with the result and category
      emit(QuizCompleted(
        result: QuizResult(
          correctAnswers: correctCount,
          wrongAnswers: wrongCount,
          category: category, // Pass the category
        ),
      ));
    }
  }

  void _handleCheckAnswer(CheckAnswer event, Emitter<QuizState> emit) {
    if (isAnswered) return;
    isAnswered = true;

    bool isCorrect = event.selectedAnswer == quizData[currentIndex]['correct'];

    if (isCorrect) {
      correctCount++; // ✅ Increase correct answer count
    } else {
      wrongCount++; // ✅ Increase wrong answer count
    }

    if (state is QuestionLoaded) {
      emit(QuestionLoaded(
        gifUrl: (state as QuestionLoaded).gifUrl,
        question: quizData[currentIndex],
        isCorrect: isCorrect,
      ));
    }
  }

  Future<void> _handleFetchGif(FetchGif event, Emitter<QuizState> emit) async {
    if (_gifCache.containsKey(event.publicId)) {
      emit(QuestionLoaded(
        gifUrl: _gifCache[event.publicId]!,
        question: quizData[currentIndex],
        isCorrect: null,
      ));
      return;
    }

    emit(QuizLoading());
    String url = "${Cloud_url.baseURL}?public_id=${event.publicId}";

    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        String gifUrl = jsonResponse['gif_url'];

        _gifCache[event.publicId] = gifUrl; // ✅ Cache GIF

        emit(QuestionLoaded(
          gifUrl: gifUrl,
          question: quizData[currentIndex],
          isCorrect: null,
        ));
      } else {
        emit(QuizError(message: 'Failed to fetch GIF from server.'));
      }
    } catch (error) {
      emit(QuizError(message: 'Error occurred: $error'));
    }
  }
}