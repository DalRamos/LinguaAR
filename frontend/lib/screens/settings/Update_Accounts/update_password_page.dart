import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lingua_arv1/Widgets/toast.dart';
import 'package:lingua_arv1/bloc/Change_password/change_password_bloc.dart';
import 'package:lingua_arv1/bloc/Otp/otp_bloc.dart';
import 'package:lingua_arv1/validators/password_validator.dart';
import 'package:lingua_arv1/validators/token.dart';
import 'package:shimmer/shimmer.dart';

class UpdatePasswordModal extends StatefulWidget {
  @override
  _UpdatePasswordModalState createState() => _UpdatePasswordModalState();
}

class _UpdatePasswordModalState extends State<UpdatePasswordModal> {
  int currentStep = 0;
  String userEmail = "Loading...";

  final TextEditingController codeController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  String? newPasswordError;
  String? confirmPasswordError;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = true;
  bool _isSendingCode = false;
  bool _isVerifyingCode = false;
  bool _isUpdatingPassword = false;

  Future<void> _loadUserEmail() async {
    String? fetchedEmail = await TokenService.getEmail();
    if (mounted) {
      setState(() {
        userEmail = fetchedEmail ?? "No Email Found";
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  void nextStep() {
    setState(() {
      if (currentStep < 2) {
        currentStep++;
      } else {
        Navigator.pop(context);
      }
    });
  }

  Widget _buildShimmerContent(bool isDarkMode, double screenWidth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Shimmer.fromColors(
          baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
          child: Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        SizedBox(height: 20),
        Shimmer.fromColors(
          baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerButton(bool isDarkMode) {
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildShimmerTextField(bool isDarkMode) {
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Calculate modal height based on keyboard visibility
    double getModalHeight() {
      final viewInsets = MediaQuery.of(context).viewInsets.bottom;
      if (viewInsets > 0) {
        // Keyboard is visible - taller height
        return screenHeight * 0.7;
      }
      // Keyboard is hidden - normal height
      return screenHeight * 0.35;
    }

    return BlocListener<OtpBloc, OtpState>(
      listener: (context, otpState) {
        if (otpState is OtpLoading) {
          setState(() => _isSendingCode = true);
        } else if (otpState is OtpSentSuccess) {
          setState(() => _isSendingCode = false);
          TopToast.show(
            context,
            'Verification code sent successfully!',
            type: ToastType.success,
          );
          nextStep();
        } else if (otpState is OtpSentFailure) {
          setState(() => _isSendingCode = false);
          TopToast.show(
            context,
            'Failed to send verification code. Please try again.',
            type: ToastType.error,
          );
        } else if (otpState is OtpVerifiedSuccess) {
          setState(() => _isVerifyingCode = false);
          TopToast.show(
            context,
            'Code verified successfully!',
            type: ToastType.success,
          );
          nextStep();
        } else if (otpState is OtpVerifiedFailure) {
          setState(() => _isVerifyingCode = false);
          TopToast.show(
            context,
            'Invalid verification code. Please try again.',
            type: ToastType.error,
          );
        }
      },
      child: BlocListener<ChangePasswordBloc, ChangePasswordState>(
        listener: (context, changeState) {
          if (changeState is ChangePasswordLoading) {
            setState(() => _isUpdatingPassword = true);
          } else if (changeState is ChangePasswordSuccess) {
            setState(() => _isUpdatingPassword = false);
            TopToast.show(
              context,
              'Password updated successfully!',
              type: ToastType.success,
            );
            Navigator.pop(context);
          } else if (changeState is ChangePasswordFailure) {
            setState(() => _isUpdatingPassword = false);
            TopToast.show(
              context,
              'Failed to update password. Please try again.',
              type: ToastType.error,
            );
          }
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          height: getModalHeight(),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode ? Color(0xFF273236) : Color(0xFFFEFFFE),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                _getStepTitle(currentStep),
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: _isLoading
                      ? _buildShimmerContent(isDarkMode, screenWidth)
                      : _buildStepContent(currentStep, isDarkMode, screenWidth),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Update Password';
      case 1:
        return 'Enter Verification Code';
      case 2:
        return 'Enter New Password';
      default:
        return 'Update Password';
    }
  }

  Widget _buildStepContent(int step, bool isDarkMode, double screenWidth) {
    switch (step) {
      case 0:
        return _buildStep1(isDarkMode, screenWidth);
      case 1:
        return _buildStep2(isDarkMode, screenWidth);
      case 2:
        return _buildStep3(isDarkMode, screenWidth);
      default:
        return _buildStep1(isDarkMode, screenWidth);
    }
  }

  Widget _buildStep1(bool isDarkMode, double screenWidth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? Color(0xFF191E20) : Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Current Email",
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white70 : Colors.grey[700],
                ),
              ),
              SizedBox(height: 4),
              Text(
                userEmail,
                style: TextStyle(
                  fontSize: screenWidth * 0.038,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        _isSendingCode
            ? _buildShimmerButton(isDarkMode)
            : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    context.read<OtpBloc>().add(SendOtpEvent(email: userEmail));
                  },
                  child: Text(
                    'Send Verification Code',
                    style: TextStyle(
                      fontSize: screenWidth * 0.038,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildStep2(bool isDarkMode, double screenWidth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _isVerifyingCode
            ? _buildShimmerTextField(isDarkMode)
            : TextField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: 'Enter 6-digit code',
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey[700],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0xFF4A90E2),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Color(0xFF191E20) : Colors.grey[100],
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: screenWidth * 0.038,
                ),
                textAlign: TextAlign.center,
                maxLength: 6,
                keyboardType: TextInputType.number,
              ),
        SizedBox(height: 20),
        _isVerifyingCode
            ? _buildShimmerButton(isDarkMode)
            : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    context.read<OtpBloc>().add(VerifyOtpEvent(
                        email: userEmail, otp: codeController.text));
                  },
                  child: Text(
                    'Verify Code',
                    style: TextStyle(
                      fontSize: screenWidth * 0.038,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildStep3(bool isDarkMode, double screenWidth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _isUpdatingPassword
            ? _buildShimmerTextField(isDarkMode)
            : TextField(
                controller: newPasswordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey[700],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0xFF4A90E2),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Color(0xFF191E20) : Colors.grey[100],
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  errorText: newPasswordError,
                ),
              ),
        SizedBox(height: 16),
        _isUpdatingPassword
            ? _buildShimmerTextField(isDarkMode)
            : TextField(
                controller: confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey[700],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0xFF4A90E2),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Color(0xFF191E20) : Colors.grey[100],
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  errorText: confirmPasswordError,
                ),
              ),
        SizedBox(height: 20),
        _isUpdatingPassword
            ? _buildShimmerButton(isDarkMode)
            : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final newPassword = newPasswordController.text.trim();
                    final confirmPassword =
                        confirmPasswordController.text.trim();

                    // Reset errors
                    setState(() {
                      newPasswordError = null;
                      confirmPasswordError = null;
                    });

                    // Validate new password
                    if (newPassword.isEmpty) {
                      setState(() {
                        newPasswordError = 'Please enter a new password.';
                      });
                    } else if (!PasswordValidator.isPasswordValid(
                        newPassword)) {
                      setState(() {
                        newPasswordError =
                            'Password must contain at least 1 uppercase letter,\n1 number, 1 special character, and be 8-12 characters long.';
                      });
                    }

                    // Validate confirm password
                    if (confirmPassword.isEmpty) {
                      setState(() {
                        confirmPasswordError = 'Please confirm your password.';
                      });
                    } else if (newPassword != confirmPassword) {
                      setState(() {
                        confirmPasswordError = 'Passwords do not match.';
                      });
                    }

                    // If no errors, proceed with password change
                    if (newPasswordError == null &&
                        confirmPasswordError == null) {
                      context.read<ChangePasswordBloc>().add(
                            ResetPasswordEvent(
                              email: userEmail,
                              otp: codeController.text,
                              newPassword: newPassword,
                            ),
                          );
                    }
                  },
                  child: Text(
                    'Update Password',
                    style: TextStyle(
                      fontSize: screenWidth * 0.038,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}
