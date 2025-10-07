abstract class DisabilityRepository {
  Future<Map<String, dynamic>> setDisability(String token, String disability);
  Future<Map<String, dynamic>> getDisability(String token);
  Future<bool> checkFirstTime(String token);
  Future<List<Map<String, dynamic>>> getDisabilityOptions();
}