// token.dart - Keep only one version
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'auth_user_id';
  static const String _emailKey = 'auth_email';
  static const String disabilityKey = 'auth_disability';

  /// Save the JWT token and extract user ID, email, and disability
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);

    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    print("Decoded Token: $decodedToken");

    String? userId = decodedToken['_id'];
    String? email = decodedToken['email'];
    String? disability = decodedToken['disability']?.toString().trim();

    if (userId != null) {
      await prefs.setString(_userIdKey, userId);
      print("User ID Saved: $userId");
    } else {
      print("Error: _id not found in token!");
    }

    if (email != null) {
      await prefs.setString(_emailKey, email);
      print("Email Saved: $email");
    }

    if (disability != null) {
      await prefs.setString(disabilityKey, disability);
      print("Disability Saved: $disability");
    }
  }

  /// Get the stored email
  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  /// Get the stored user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// Get the stored disability
  static Future<String?> getDisability() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(disabilityKey);
  }

  /// Save disability locally - KEEP ONLY THIS ONE
  static Future<void> saveDisability(String? disability) async {
    final prefs = await SharedPreferences.getInstance();
    if (disability != null) {
      await prefs.setString(disabilityKey, disability);
      print("Disability saved locally: $disability");
    } else {
      await prefs.remove(disabilityKey);
      print("Disability removed locally");
    }
  }

  /// Logout - Clear all stored user data
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_emailKey);
    await prefs.remove(disabilityKey);
    print("User logged out, all data cleared.");
  }

  /// Get the stored JWT token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Check if user is logged in
  static Future<bool> isUserLoggedIn() async {
    final token = await getToken();
    return token != null && !JwtDecoder.isExpired(token);
  }

  /// Get all user data at once
  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString(_tokenKey),
      'userId': prefs.getString(_userIdKey),
      'email': prefs.getString(_emailKey),
      'disability': prefs.getString(disabilityKey),
    };
  }
}