part of 'lesson_flow_bloc.dart';

abstract class LessonFlowEvent extends Equatable {
  const LessonFlowEvent();

  @override
  List<Object> get props => [];
}

class CompleteLesson extends LessonFlowEvent {
  final String userId;
  final String category;

  // Use positional constructor instead of named parameters
  const CompleteLesson(this.userId, this.category);

  @override
  List<Object> get props => [userId, category];
}

class LoadLessonStatus extends LessonFlowEvent {
  final String userId;
  final String category;

  // Use positional constructor instead of named parameters
  const LoadLessonStatus(this.userId, this.category);

  @override
  List<Object> get props => [userId, category];
}