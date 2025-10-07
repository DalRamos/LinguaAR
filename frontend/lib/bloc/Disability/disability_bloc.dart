import 'package:bloc/bloc.dart';
import 'package:lingua_arv1/repositories/disability_repositories/disability_repository_impl.dart';
import 'package:meta/meta.dart';

part 'disability_event.dart';
part 'disability_state.dart';

class DisabilityBloc extends Bloc<DisabilityEvent, DisabilityState> {
  final DisabilityRepositoryImpl disabilityRepository;

  DisabilityBloc({required this.disabilityRepository}) : super(DisabilityInitial()) {
    on<SetDisabilityEvent>(_onSetDisability);
    on<GetDisabilityEvent>(_onGetDisability);
    on<CheckFirstTimeEvent>(_onCheckFirstTime);
    on<GetDisabilityOptionsEvent>(_onGetDisabilityOptions);
  }

  Future<void> _onSetDisability(SetDisabilityEvent event, Emitter<DisabilityState> emit) async {
    emit(DisabilityLoading());
    try {
      final response = await disabilityRepository.setDisability(event.token, event.disability);
      emit(DisabilitySetSuccess(response: response));
    } catch (e) {
      emit(DisabilityFailure(errorMessage: e.toString()));
    }
  }

  Future<void> _onGetDisability(GetDisabilityEvent event, Emitter<DisabilityState> emit) async {
    emit(DisabilityLoading());
    try {
      final disabilityData = await disabilityRepository.getDisability(event.token);
      emit(DisabilityGetSuccess(disabilityData: disabilityData));
    } catch (e) {
      emit(DisabilityFailure(errorMessage: e.toString()));
    }
  }

  Future<void> _onCheckFirstTime(CheckFirstTimeEvent event, Emitter<DisabilityState> emit) async {
    emit(DisabilityLoading());
    try {
      final isFirstTime = await disabilityRepository.checkFirstTime(event.token);
      emit(FirstTimeChecked(isFirstTime: isFirstTime));
    } catch (e) {
      emit(DisabilityFailure(errorMessage: e.toString()));
    }
  }

  Future<void> _onGetDisabilityOptions(GetDisabilityOptionsEvent event, Emitter<DisabilityState> emit) async {
    emit(DisabilityLoading());
    try {
      final options = await disabilityRepository.getDisabilityOptions();
      emit(DisabilityOptionsLoaded(options: options));
    } catch (e) {
      emit(DisabilityFailure(errorMessage: e.toString()));
    }
  }
}