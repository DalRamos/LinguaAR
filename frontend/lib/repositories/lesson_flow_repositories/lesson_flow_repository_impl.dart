import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lingua_arv1/model/lesson_progress.dart';
import 'package:lingua_arv1/repositories/Config.dart';
import 'lesson_flow_repository.dart';

class LessonRepositoryImpl implements LessonRepository {
  final String baseUrl = BasicUrl.baseURL;

  @override
  Future<LessonProgress> completeLesson(String userId, String category) async {
    print('🚀 API Call: Completing lesson - User: $userId, Category: $category');
    
    final response = await http.post(
      Uri.parse('$baseUrl/lessonflow/lessons/complete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'category': category,
      }),
    );

    print('📡 API Response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return LessonProgress(
        userId: userId,
        category: category,
        completedAt: DateTime.now(),
        completed: data['completed'] ?? true, // Use the completed status from API
      );
    } else {
      throw Exception("Failed to complete lesson: ${response.statusCode} - ${response.body}");
    }
  }

  @override
  Future<LessonProgress> getLessonStatus(String userId, String category) async {
    print('🚀 API Call: Checking lesson status - User: $userId, Category: $category');
    
    // URL encode the category to handle spaces and special characters
    final encodedCategory = Uri.encodeComponent(category);
    final url = '$baseUrl/lessonflow/lessons/status?userId=$userId&category=$encodedCategory';
    
    print('🔗 URL: $url');
    
    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    print('📡 API Response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return LessonProgress(
        userId: userId,
        category: category,
        completedAt: data['completedAt'] != null 
            ? DateTime.parse(data['completedAt'])
            : DateTime.now(),
        completed: data['completed'] ?? false, // Use the completed status from API
      );
    } else {
      throw Exception("Failed to fetch lesson status: ${response.statusCode} - ${response.body}");
    }
  }
}