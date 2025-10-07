// bloc/Disability/disability_event.dart
part of 'disability_bloc.dart';

@immutable
abstract class DisabilityEvent {}

class SetDisabilityEvent extends DisabilityEvent {
  final String token;
  final String disability;

  SetDisabilityEvent({required this.token, required this.disability});
}

class GetDisabilityEvent extends DisabilityEvent {
  final String token;

  GetDisabilityEvent({required this.token});
}

class CheckFirstTimeEvent extends DisabilityEvent {
  final String token;

  CheckFirstTimeEvent({required this.token});
}

class GetDisabilityOptionsEvent extends DisabilityEvent {}