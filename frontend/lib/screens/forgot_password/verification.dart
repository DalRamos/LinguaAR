import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lingua_arv1/repositories/otp_repositories/otp_repository_impl.dart';
import 'package:lingua_arv1/screens/forgot_password/change_password.dart';
import '../../bloc/otp/otp_bloc.dart';
import '../../widgets/toast.dart';

class OtpVerificationModal extends StatefulWidget {
  final String email;

  OtpVerificationModal({required this.email});

  @override
  State<OtpVerificationModal> createState() => _OtpVerificationModalState();
}

class _OtpVerificationModalState extends State<OtpVerificationModal> {
  final TextEditingController otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OtpBloc(OtpRepositoryImpl()),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: SafeArea(
          child: BlocConsumer<OtpBloc, OtpState>(
            listener: (context, state) {
              if (state is OtpVerifiedSuccess) {
                TopToast.show(
                  context,
                  'OTP verified successfully!',
                  type: ToastType.success,
                  duration: Duration(seconds: 2),
                );
                Future.delayed(Duration(milliseconds: 500), () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => ChangePasswordModal(
                        email: widget.email, otp: otpController.text.trim()),
                  );
                });
              } else if (state is OtpVerifiedFailure) {
                TopToast.show(
                  context,
                  'Invalid OTP. Please try again.',
                  type: ToastType.error,
                  duration: Duration(seconds: 2),
                );
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
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 48,
                      height: 4,
                      margin: EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Header icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Color(0xFF4A90E2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.verified_user,
                        color: Color(0xFF4A90E2),
                        size: 40,
                      ),
                    ),

                    SizedBox(height: 24),

                    // Title
                    Text(
                      'Verify Your Email',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),

                    SizedBox(height: 16),

                    // Description text
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Text(
                            'Enter the 6-digit code sent to',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onBackground
                                  .withOpacity(0.7),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            widget.email,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4A90E2),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32),

                    // OTP Input Field
                    Form(
                      key: _formKey,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onBackground,
                            letterSpacing: 6,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Enter OTP Code',
                            labelStyle: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onBackground
                                  .withOpacity(0.6),
                              fontSize: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Color(0xFF4A90E2),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 20, horizontal: 20),
                            prefixIcon: Container(
                              margin: EdgeInsets.only(right: 12, left: 16),
                              child: Icon(
                                Icons.sms_outlined,
                                color: Color(0xFF4A90E2),
                                size: 24,
                              ),
                            ),
                            counterText: '',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter OTP';
                            }
                            if (value.length != 6) {
                              return 'OTP must be 6 digits';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: 32),

                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state is OtpLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<OtpBloc>().add(VerifyOtpEvent(
                                      email: widget.email,
                                      otp: otpController.text.trim()));
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4A90E2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shadowColor: Color(0xFF4A90E2).withOpacity(0.3),
                        ),
                        child: state is OtpLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                'Verify OTP',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Resend OTP
                    TextButton(
                      onPressed: state is OtpLoading
                          ? null
                          : () {
                              context
                                  .read<OtpBloc>()
                                  .add(SendOtpEvent(email: widget.email));
                            },
                      style: TextButton.styleFrom(
                        foregroundColor: Color(0xFF4A90E2),
                      ),
                      child: Text(
                        "Didn't receive code? Resend OTP",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
