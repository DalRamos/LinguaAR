// repositories/disability_repositories/disability_repository_impl.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lingua_arv1/repositories/Config.dart';
import 'disability_repository.dart';

class DisabilityRepositoryImpl implements DisabilityRepository {
  String url = BasicUrl.baseURL;

  @override
  Future<Map<String, dynamic>> setDisability(String token, String disability) async {
    print("Setting disability for user");
    
    final response = await http.post(
      Uri.parse('$url/api/disability/set'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'disability': disability}),
    );

    print("Set Disability Response Code: ${response.statusCode}");
    print("Set Disability Response Body: ${response.body}");

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to set disability: ${response.statusCode}');
    }
  }

  @override
  Future<Map<String, dynamic>> getDisability(String token) async {
    final response = await http.get(
      Uri.parse('$url/api/disability/get'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print("Get Disability Response Code: ${response.statusCode}");
    print("Get Disability Response Body: ${response.body}");

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get disability: ${response.statusCode}');
    }
  }

  @override
  Future<bool> checkFirstTime(String token) async {
    final response = await http.get(
      Uri.parse('$url/api/disability/check-first-time'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print("Check First Time Response Code: ${response.statusCode}");
    print("Check First Time Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['is_first_time'];
    } else {
      throw Exception('Failed to check first time status: ${response.statusCode}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getDisabilityOptions() async {
    final response = await http.get(
      Uri.parse('$url/api/disability/options'),
    );

    print("Get Disability Options Response Code: ${response.statusCode}");
    print("Get Disability Options Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['options']);
    } else {
      throw Exception('Failed to get disability options: ${response.statusCode}');
    }
  }
}