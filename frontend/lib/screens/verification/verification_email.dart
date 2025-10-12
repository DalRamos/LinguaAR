import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lingua_arv1/bloc/Otp/otp_bloc.dart';
import 'package:lingua_arv1/repositories/otp_repositories/otp_repository_impl.dart';
import 'package:lingua_arv1/Widgets/toast.dart';

class EmailVerificationModal extends StatefulWidget {
  final String email;
  final VoidCallback onVerified;

  const EmailVerificationModal({
    Key? key,
    required this.email,
    required this.onVerified,
  }) : super(key: key);

  @override
  _EmailVerificationModalState createState() => _EmailVerificationModalState();
}

class _EmailVerificationModalState extends State<EmailVerificationModal> {
  late String email;
  final TextEditingController otpController = TextEditingController();
  final TextEditingController _changeEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    email = widget.email;
    // Send OTP when modal opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OtpBloc>().add(SendOtpEvent(email: email));
    });
  }

  void _showChangeEmailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Change Email'),
          content: TextField(
            controller: _changeEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'New Email',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newEmail = _changeEmailController.text.trim();
                if (newEmail.isNotEmpty && newEmail.contains('@')) {
                  setState(() {
                    email = newEmail;
                  });
                  context.read<OtpBloc>().add(SendOtpEvent(email: email));
                  Navigator.pop(context);
                  TopToast.show(
                    context,
                    'Email updated. OTP sent to $newEmail',
                    type: ToastType.success,
                  );
                  _changeEmailController.clear();
                } else {
                  TopToast.show(
                    context,
                    'Enter a valid email address',
                    type: ToastType.error,
                  );
                }
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OtpBloc, OtpState>(
      listener: (context, state) {
        if (state is OtpSentSuccess) {
          TopToast.show(
            context,
            'OTP sent successfully! Check your email.',
            type: ToastType.success,
          );
        } else if (state is OtpSentFailure) {
          TopToast.show(
            context,
            'Failed to send OTP. Try again.',
            type: ToastType.error,
          );
        } else if (state is OtpVerifiedSuccess) {
          // Call the callback to update verification status in SignUpPage
          widget.onVerified();
          // Close the modal but stay on SignUpPage
          Navigator.of(context).pop();
        } else if (state is OtpVerifiedFailure) {
          TopToast.show(
            context,
            'Invalid OTP. Please try again.',
            type: ToastType.error,
          );
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Enter the OTP sent to $email',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'OTP',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              BlocBuilder<OtpBloc, OtpState>(
                builder: (context, state) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state is OtpLoading
                          ? null
                          : () {
                              final otp = otpController.text.trim();
                              if (otp.isNotEmpty) {
                                context.read<OtpBloc>().add(
                                    VerifyOtpEvent(email: email, otp: otp));
                              } else {
                                TopToast.show(
                                  context,
                                  'Please enter the OTP.',
                                  type: ToastType.error,
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: state is OtpLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Verify OTP'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      context.read<OtpBloc>().add(SendOtpEvent(email: email));
                    },
                    child: const Text('Resend OTP'),
                  ),
                  TextButton(
                    onPressed: () => _showChangeEmailDialog(context),
                    child: const Text('Change Email'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    otpController.dispose();
    _changeEmailController.dispose();
    super.dispose();
  }
}