import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lingua_arv1/model/lesson_progress.dart';
import 'package:lingua_arv1/repositories/lesson_flow_repositories/lesson_flow_repository.dart';

part 'lesson_flow_event.dart';
part 'lesson_flow_state.dart';

class LessonFlowBloc extends Bloc<LessonFlowEvent, LessonFlowState> {
  final LessonRepository repository;

  LessonFlowBloc(this.repository) : super(LessonFlowInitial()) {
    on<CompleteLesson>(_onCompleteLesson);
    on<LoadLessonStatus>(_onLoadLessonStatus);
  }

  Future<void> _onCompleteLesson(
      CompleteLesson event, Emitter<LessonFlowState> emit) async {
    emit(LessonFlowLoading());
    try {
      final progress = await repository.completeLesson(
        event.userId,
        event.category,
      );
      emit(LessonFlowSuccess(progress));
    } catch (e) {
      emit(LessonFlowError(e.toString()));  // This creates LessonFlowError with error message
    }
  }

  Future<void> _onLoadLessonStatus(
      LoadLessonStatus event, Emitter<LessonFlowState> emit) async {
    emit(LessonFlowLoading());
    try {
      final progress = await repository.getLessonStatus(
        event.userId,
        event.category,
      );
      emit(LessonFlowSuccess(progress));
    } catch (e) {
      emit(LessonFlowError(e.toString()));  // This creates LessonFlowError with error message
    }
  }
}