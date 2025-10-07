// screens/authentication/sign_up/signup_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lingua_arv1/bloc/Otp/otp_bloc.dart';
import 'package:lingua_arv1/bloc/Register/register_bloc.dart';
import 'package:lingua_arv1/repositories/Register_repositories/register_repository_impl.dart';
import 'package:lingua_arv1/repositories/otp_repositories/otp_repository_impl.dart';
import 'package:lingua_arv1/screens/authentication/login/login_page.dart';
import 'package:lingua_arv1/screens/authentication/sign_up/widgets/signup_dialog.dart';
import 'package:lingua_arv1/screens/verification/verification_email.dart';
import 'package:lingua_arv1/validators/password_validator.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  String? passwordError;
  String? confirmPasswordError;
  String? emailError;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isVerified = false;
  bool _isRegistering = false;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RegisterBloc>(
          create: (context) => RegisterBloc(RegisterRepositoryImpl()),
        ),
        BlocProvider<OtpBloc>(
          create: (context) => OtpBloc(OtpRepositoryImpl()),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: BlocConsumer<RegisterBloc, RegisterState>(
                    listener: (context, state) {
                      if (state is RegisterSuccess) {
                        setState(() {
                          _isRegistering = false;
                        });
                        // Show success toast at top
                        TopToast.show(
                          context,
                          'Registration successful!',
                          type: ToastType.success,
                        );
                        // Navigate to login page
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                          (route) => false,
                        );
                      } else if (state is RegisterFailure) {
                        setState(() {
                          _isRegistering = false;
                        });
                        // Handle duplicate email error
                        if (state.errorMessage
                            .toLowerCase()
                            .contains("exists")) {
                          setState(() {
                            emailError =
                                "Email already exists. Please use another email.";
                          });
                        } else {
                          // Show error toast at top
                          TopToast.show(
                            context,
                            state.errorMessage,
                            type: ToastType.error,
                          );
                        }
                      }
                    },
                    builder: (context, state) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create an Account',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Color(0xFF273236),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Please fill in the details below',
                              style: TextStyle(
                                  fontSize: 16, color: Color(0xFF4A90E2)),
                            ),
                            SizedBox(height: 32),
                            TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 16),
                                errorText: emailError,
                              ),
                            ),
                            SizedBox(height: 20),
                            TextField(
                              controller: passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 16),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                errorText: passwordError,
                              ),
                            ),
                            SizedBox(height: 20),
                            TextField(
                              controller: confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 16),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                                errorText: confirmPasswordError,
                              ),
                            ),

                            // Show verification status
                            if (_isVerified) ...[
                              SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.verified, 
                                         color: Colors.green, size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Email verified successfully! Press "Complete Sign Up" to finish registration.',
                                        style: TextStyle(
                                          color: Colors.green[700],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            
                            SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isRegistering ? null : () {
                                  _handleSignUp(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Color(0xFF191E20),
                                  padding: EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isRegistering
                                    ? CircularProgressIndicator(
                                        color: Colors.white)
                                    : Text(
                                        _isVerified ? 'Complete Sign Up' : 'Verify Email & Sign Up',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Theme.of(context)
                                                        .brightness ==
                                                    Brightness.dark
                                                ? Color(0xFF273236)
                                                : Colors.white),
                                      ),
                              ),
                            ),
                            SizedBox(height: 24),
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Already have an account? ",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Color(0xFF273236),
                                      )),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => LoginPage()),
                                      );
                                    },
                                    child: Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF4A90E2),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleSignUp(BuildContext context) {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    setState(() {
      emailError = null;
      passwordError = null;
      confirmPasswordError = null;
    });

    // Email validation
    if (email.isEmpty) {
      setState(() {
        emailError = 'Please enter your email.';
      });
      return;
    } else if (!email.contains('@')) {
      setState(() {
        emailError = 'Please enter a valid email address.';
      });
      return;
    }

    // Password validation
    if (password.isEmpty) {
      setState(() {
        passwordError = 'Please enter a new password.';
      });
      return;
    } else if (!PasswordValidator.isPasswordValid(password)) {
      setState(() {
        passwordError =
            'Password must contain at least 1 uppercase letter,\n1 number, 1 special character, and be 8-12 characters long.';
      });
      return;
    }

    // Confirm password validation
    if (confirmPassword.isEmpty) {
      setState(() {
        confirmPasswordError = 'Please confirm your password.';
      });
      return;
    } else if (password != confirmPassword) {
      setState(() {
        confirmPasswordError = 'Passwords do not match.';
      });
      return;
    }

    // If user is already verified, proceed with registration
    if (_isVerified) {
      setState(() {
        _isRegistering = true;
      });
      context.read<RegisterBloc>().add(
            RegisterButtonPressed(
              email: email,
              password: password,
            ),
          );
      return;
    }

    // If not verified, show OTP verification modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EmailVerificationModal(
        email: email,
        onVerified: () {
          // Only mark as verified, don't register yet
          setState(() {
            _isVerified = true;
          });
          // Show success toast at top
          TopToast.show(
            context,
            'Email verified successfully!',
            type: ToastType.success,
          );
        },
      ),
    );
  }
}