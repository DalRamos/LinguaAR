import 'package:lingua_arv1/model/lesson_progress.dart';

abstract class LessonRepository {
  Future<LessonProgress> completeLesson(String userId, String category);
  Future<LessonProgress> getLessonStatus(String userId, String category);
}
