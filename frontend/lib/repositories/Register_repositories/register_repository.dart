import 'package:lingua_arv1/model/Authentication.dart';

abstract class RegisterRepository {
  Future<Authentication> register(String email, String password);
}
