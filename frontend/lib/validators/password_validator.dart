class PasswordValidator {
  static final _passwordRegex = RegExp(
    r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+])[A-Za-z\d!@#$%^&*()_+]{8,12}$',
  );

  static bool isPasswordValid(String password) {
    return _passwordRegex.hasMatch(password);
  }

  /// Returns null if valid, or error message string if invalid
  static String? validate(String password) {
    if (password.isEmpty) {
      return 'Please enter a new password.';
    }
    if (!_passwordRegex.hasMatch(password)) {
      return 'Password must contain at least 1 uppercase letter,\n1 number, 1 special character, and be 8-12 characters long.';
    }
    return null; // Valid password
  }
  // validators/password_validator.dart
  static bool PasswordValid(String password) {
    // Your existing validation logic
    if (password.length < 8 || password.length > 12) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    return true;
  }

  static List<Map<String, dynamic>> getPasswordRequirements(String password) {
    return [
      {
        'message': '8-12 characters long',
        'isMet': password.length >= 8 && password.length <= 12,
      },
      {
        'message': 'At least 1 uppercase letter (A-Z)',
        'isMet': password.contains(RegExp(r'[A-Z]')),
      },
      {
        'message': 'At least 1 number (0-9)',
        'isMet': password.contains(RegExp(r'[0-9]')),
      },
      {
        'message': 'At least 1 special character (!@#\$%^&* etc.)',
        'isMet': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
      },
    ];
  }
}
