import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lingua_arv1/bloc/Register/register_bloc.dart';
import 'package:lingua_arv1/repositories/register_repositories/register_repository_impl.dart';
import 'package:lingua_arv1/validators/password_validator.dart';
import 'login_page.dart';

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
  String? emailError; // Added for email validation

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RegisterBloc(RegisterRepositoryImpl()),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Registration Successful! Please log in.'),
                          ),
                        );
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                          (route) => false,
                        );
                      } else if (state is RegisterFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state.errorMessage)),
                        );
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
                                    ? Colors.white // Dark mode color
                                    : Color(0xFF273236), // Light mode color,
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
                            SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  final email = emailController.text.trim();
                                  final password =
                                      passwordController.text.trim();
                                  final confirmPassword =
                                      confirmPasswordController.text.trim();

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
                                  } else if (!email.contains('@')) {
                                    setState(() {
                                      emailError =
                                          'Please enter a valid email address.';
                                    });
                                  }

                                  // Password validation
                                  if (password.isEmpty) {
                                    setState(() {
                                      passwordError =
                                          'Please enter a new password.';
                                    });
                                  } else if (!PasswordValidator.isPasswordValid(
                                      password)) {
                                    setState(() {
                                      passwordError =
                                          'Password must contain at least 1 uppercase letter,\n1 number, 1 special character, and be 8-12 characters long.';
                                    });
                                  }

                                  // Confirm password validation
                                  if (confirmPassword.isEmpty) {
                                    setState(() {
                                      confirmPasswordError =
                                          'Please confirm your password.';
                                    });
                                  } else if (password != confirmPassword) {
                                    setState(() {
                                      confirmPasswordError =
                                          'Passwords do not match.';
                                    });
                                  }

                                  // If all validations pass, trigger the registration event
                                  if (emailError == null &&
                                      passwordError == null &&
                                      confirmPasswordError == null) {
                                    context.read<RegisterBloc>().add(
                                          RegisterButtonPressed(
                                              email: email, password: password),
                                        );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                              .brightness ==
                                          Brightness.dark
                                      ? Colors
                                          .white // White button in dark mode
                                      : Color(0xFF191E20),
                                  padding: EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: state is RegisterLoading
                                    ? CircularProgressIndicator(
                                        color: Colors.white)
                                    : Text(
                                        'Sign Up',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color:
                                                Theme.of(context).brightness ==
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
                                            ? Colors.white // Dark mode color
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
}
