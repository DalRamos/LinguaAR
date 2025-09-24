class LessonProgress {
  final String userId;
  final String category;
  final DateTime completedAt;
  final bool completed;

  LessonProgress({
    required this.userId,
    required this.category,
    required this.completedAt,
    required this.completed,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> json) {
    return LessonProgress(
      userId: json['userId']?.toString() ?? '',
      category: json['category'] ?? '',
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'])
          : DateTime.now(),
      completed: json['completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'category': category,
      'completedAt': completedAt.toIso8601String(),
      'completed': completed,
    };
  }
}