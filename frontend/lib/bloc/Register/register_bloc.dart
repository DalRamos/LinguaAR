import 'package:bloc/bloc.dart';
import 'package:lingua_arv1/model/Authentication.dart';
import 'package:lingua_arv1/repositories/Register_repositories/register_repository.dart';
part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final RegisterRepository _registerRepository;

  RegisterBloc(this._registerRepository) : super(RegisterInitial()) {
    on<RegisterButtonPressed>((event, emit) async {
      emit(RegisterLoading());
      print("Registering user with email: ${event.email}");

      try {
        final authentication = await _registerRepository.register(
          event.email,
          event.password,
        );

        print("Registration Successful: Message = ${authentication.message}");
        emit(RegisterSuccess(authentication));
      } catch (e) {
        print("Registration Failed: $e");
        emit(RegisterFailure(e.toString()));
      }
    });
  }
}