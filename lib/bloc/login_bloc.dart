import 'package:bloc/bloc.dart';
import 'package:lingua_arv1/model/Authentication.dart';
import '../repositories/login_repositories/login_repository.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginRepository _loginRepository;

  LoginBloc(this._loginRepository) : super(LoginInitial()) {
    on<LoginEvent>((event, emit) async {
      if (event is LoginButtonPressed) {
        emit(LoginLoading());
        try {
          final authentication = await _loginRepository.login(event.email, event.password);
          emit(LoginSuccess(authentication)); 
        } catch (e) {
          emit(LoginFailure(e.toString()));
        }
      }
    });
  }
}
