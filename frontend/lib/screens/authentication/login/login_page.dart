import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lingua_arv1/Widgets/toast.dart';
import 'package:lingua_arv1/bloc/Login/login_bloc.dart';
import 'package:lingua_arv1/bloc/Login/login_event.dart';
import 'package:lingua_arv1/bloc/Login/login_state.dart';
import 'package:lingua_arv1/screens/authentication/sign_up/signup_page.dart';
import 'package:lingua_arv1/screens/forgot_password/forgot_password_sheet.dart';
import 'package:lingua_arv1/repositories/login_repositories/login_repository_impl.dart';
import 'package:lingua_arv1/screens/get_started/disability_setup_page.dart';
import 'package:lingua_arv1/screens/get_started/get_started_page2.dart';
import 'package:lingua_arv1/screens/home/home_screen.dart';
import 'package:lingua_arv1/validators/token.dart';
import 'package:lingua_arv1/bloc/Disability/disability_bloc.dart';
import 'package:lingua_arv1/repositories/disability_repositories/disability_repository_impl.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? emailError;
  String? passwordError;

  void _navigateBasedOnFirstTimeStatus(BuildContext context) async {
    try {
      final token = await TokenService.getToken();
      if (token != null) {
        // Check if it's user's first time login
        final isFirstTime =
            await DisabilityRepositoryImpl().checkFirstTime(token);

        if (isFirstTime) {
          print("First time user - navigating to disability setup");
          // Navigate to disability setup page
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => DisabilitySetupPage()),
            (route) => false,
          );
        } else {
          print("Returning user - navigating directly to home");
          // Navigate directly to home screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print('Error checking first time status: $e');
      // Show error toast
      TopToast.show(
        context,
        'Error checking user status',
        type: ToastType.error,
      );
      // If there's an error, proceed to home screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) => false,
      );
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Color(0xFF273236)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Color(0xFF4A90E2), size: 60),
                SizedBox(height: 16),
                Text('Successful Login',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Color(0xFF273236))),
                SizedBox(height: 8),
                Text('You have successfully logged in.',
                    style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.grey[600]),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(Duration(seconds: 2), () {
      Navigator.pop(context); // Close the dialog
      _navigateBasedOnFirstTimeStatus(
          context); // Navigate based on first-time status
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginBloc(LoginRepositoryImpl()),
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
                  child: BlocConsumer<LoginBloc, LoginState>(
                    listener: (context, state) async {
                      if (state is LoginLoading) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) =>
                              Center(child: CircularProgressIndicator()),
                        );
                      } else if (state is LoginSuccess) {
                        Navigator.pop(context);

                        // Show success toast
                        TopToast.show(
                          context,
                          'Login successful!',
                          type: ToastType.success,
                        );

                        await TokenService.saveToken(
                            state.authentication.token);

                        try {
                          final token = await TokenService.getToken();
                          final isFirstTime = await DisabilityRepositoryImpl()
                              .checkFirstTime(token!);

                          if (isFirstTime) {
                            // First-time user: Go to disability setup
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DisabilitySetupPage()),
                              (route) => false,
                            );
                          } else {
                            // Returning user: Go directly to home
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HomeScreen()),
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          print('Error checking first time: $e');
                          // Show error toast
                          TopToast.show(
                            context,
                            'Error checking user preferences',
                            type: ToastType.error,
                          );
                          // Fallback: Go to home screen
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HomeScreen()),
                            (route) => false,
                          );
                        }
                      } else if (state is LoginFailure) {
                        Navigator.pop(context); // Close loading dialog

                        // Show error toast
                        TopToast.show(
                          context,
                          state.errorMessage,
                          type: ToastType.error,
                        );

                        setState(() {
                          emailError = state.errorMessage.contains('email')
                              ? 'Invalid email or password'
                              : null;
                          passwordError =
                              state.errorMessage.contains('password')
                                  ? 'Invalid email or password'
                                  : null;
                        });
                      }
                    },
                    builder: (context, state) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 80),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome Back!',
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
                              'Please log in to your account',
                              style: TextStyle(
                                  fontSize: 16, color: Color(0xFF4A90E2)),
                            ),
                            SizedBox(height: 32),
                            TextField(
                              controller: emailController,
                              decoration: InputDecoration(
                                labelText: 'Username or Email',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 16),
                              ),
                            ),
                            if (emailError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(emailError!,
                                    style: TextStyle(
                                        color: Colors.red, fontSize: 12)),
                              ),
                            SizedBox(height: 20),
                            TextField(
                              controller: passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 16),
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
                              ),
                            ),
                            if (passwordError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(passwordError!,
                                    style: TextStyle(
                                        color: Colors.red, fontSize: 12)),
                              ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(20))),
                                    builder: (context) => ForgotPasswordSheet(),
                                  );
                                },
                                child: Text('Forgot password?',
                                    style: TextStyle(color: Color(0xFF4A90E2))),
                              ),
                            ),
                            SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  final email = emailController.text.trim();
                                  final password =
                                      passwordController.text.trim();

                                  // Validate fields
                                  if (email.isEmpty || password.isEmpty) {
                                    // Show warning toast for empty fields
                                    if (email.isEmpty && password.isEmpty) {
                                      TopToast.show(
                                        context,
                                        'Please enter email and password',
                                        type: ToastType.warning,
                                      );
                                    } else if (email.isEmpty) {
                                      TopToast.show(
                                        context,
                                        'Please enter your email',
                                        type: ToastType.warning,
                                      );
                                    } else {
                                      TopToast.show(
                                        context,
                                        'Please enter your password',
                                        type: ToastType.warning,
                                      );
                                    }

                                    setState(() {
                                      emailError = email.isEmpty
                                          ? 'Email is required'
                                          : null;
                                      passwordError = password.isEmpty
                                          ? 'Password is required'
                                          : null;
                                    });
                                    return;
                                  }

                                  BlocProvider.of<LoginBloc>(context).add(
                                      LoginButtonPressed(
                                          email: email, password: password));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Color(0xFF191E20),
                                  padding: EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text('Login',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Color(0xFF273236)
                                            : Colors.white)),
                              ),
                            ),
                            SizedBox(height: 24),
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Don't have an account? ",
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Color(0xFF273236))),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  SignUpPage()));
                                    },
                                    child: Text('Sign up',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF4A90E2),
                                            fontWeight: FontWeight.bold)),
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
