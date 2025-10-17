import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lingua_arv1/repositories/otp_repositories/otp_repository_impl.dart';
import 'package:lingua_arv1/screens/forgot_password/verification.dart';
import '../../bloc/otp/otp_bloc.dart';
import '../../widgets/toast.dart';

class ForgotPasswordSheet extends StatefulWidget {
  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  final TextEditingController emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OtpBloc(OtpRepositoryImpl()),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: BlocConsumer<OtpBloc, OtpState>(
          listener: (context, state) {
            if (state is OtpSentSuccess) {
              TopToast.show(
                context,
                'OTP sent successfully!',
                type: ToastType.success,
                duration: Duration(seconds: 2),
              );
              Future.delayed(Duration(milliseconds: 500), () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) =>
                      OtpVerificationModal(email: emailController.text.trim()),
                );
              });
            } else if (state is OtpSentFailure) {
              TopToast.show(
                context,
                'Failed to send OTP. Please try again.',
                type: ToastType.error,
                duration: Duration(seconds: 2),
              );
            }
          },
          builder: (context, state) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle
                      Container(
                        width: 48,
                        height: 4,
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Header icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Color(0xFF4A90E2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.lock_reset,
                          color: Color(0xFF4A90E2),
                          size: 32,
                        ),
                      ),

                      SizedBox(height: 20),

                      // Title
                      Text(
                        'Reset Your Password',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),

                      SizedBox(height: 12),

                      // Description text with line break
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Text(
                              'Enter your email address to receive',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onBackground
                                    .withOpacity(0.7),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'password reset instructions',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onBackground
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Email Input Field
                      Form(
                        key: _formKey,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onBackground,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Enter Email Address',
                              labelStyle: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onBackground
                                    .withOpacity(0.6),
                                fontSize: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Color(0xFF4A90E2),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 16),
                              prefixIcon: Container(
                                margin: EdgeInsets.only(right: 8, left: 12),
                                child: Icon(
                                  Icons.email_outlined,
                                  color: Color(0xFF4A90E2),
                                  size: 20,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),

                      SizedBox(height: 24),

                      // Send OTP Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: state is OtpLoading
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    context.read<OtpBloc>().add(SendOtpEvent(
                                        email: emailController.text.trim()));
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4A90E2),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: state is OtpLoading
                              ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  'Send OTP',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(
                          height:
                              MediaQuery.of(context).viewInsets.bottom + 16),
                    ],
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
