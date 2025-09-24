part of 'lesson_flow_bloc.dart';

abstract class LessonFlowState extends Equatable {
  const LessonFlowState();

  @override
  List<Object> get props => [];
}

class LessonFlowInitial extends LessonFlowState {}

class LessonFlowLoading extends LessonFlowState {}

class LessonFlowSuccess extends LessonFlowState {
  final LessonProgress progress;

  const LessonFlowSuccess(this.progress);

  @override
  List<Object> get props => [progress];
}

class LessonFlowError extends LessonFlowState {
  final String error;  // Make sure this property exists

  const LessonFlowError(this.error);

  @override
  List<Object> get props => [error];
}