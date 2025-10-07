// bloc/Disability/disability_state.dart
part of 'disability_bloc.dart';

@immutable
abstract class DisabilityState {}

class DisabilityInitial extends DisabilityState {}

class DisabilityLoading extends DisabilityState {}

class DisabilitySetSuccess extends DisabilityState {
  final Map<String, dynamic> response;

  DisabilitySetSuccess({required this.response});
}

class DisabilityGetSuccess extends DisabilityState {
  final Map<String, dynamic> disabilityData;

  DisabilityGetSuccess({required this.disabilityData});
}

class FirstTimeChecked extends DisabilityState {
  final bool isFirstTime;

  FirstTimeChecked({required this.isFirstTime});
}

class DisabilityOptionsLoaded extends DisabilityState {
  final List<Map<String, dynamic>> options;

  DisabilityOptionsLoaded({required this.options});
}

class DisabilityFailure extends DisabilityState {
  final String errorMessage;

  DisabilityFailure({required this.errorMessage});
}