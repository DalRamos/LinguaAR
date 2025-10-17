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
  DateTime? _lastToastTime;
  static const Duration _toastCooldown = Duration(seconds: 2);

  // Method to get modal height based on keyboard visibility
  double getModalHeight(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    return isKeyboardVisible ? 0.9 : 0.7;
  }

  void _showToastWithCooldown(
      BuildContext context, String message, ToastType type) {
    final now = DateTime.now();
    if (_lastToastTime == null ||
        now.difference(_lastToastTime!) > _toastCooldown) {
      _lastToastTime = now;
      TopToast.show(context, message, type: type);
    }
  }

  @override
  void initState() {
    super.initState();
    email = widget.email;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OtpBloc>().add(SendOtpEvent(email: email));
    });
  }

  void _showChangeEmailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.email_outlined,
                        color: Color(0xFF4A90E2), size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Change Email',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Color(0xFF273236),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _changeEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'New Email Address',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          BorderSide(color: Color(0xFF4A90E2), width: 2),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text('Cancel'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final newEmail = _changeEmailController.text.trim();
                        if (newEmail.isNotEmpty && newEmail.contains('@')) {
                          setState(() {
                            email = newEmail;
                          });
                          context
                              .read<OtpBloc>()
                              .add(SendOtpEvent(email: email));
                          Navigator.pop(context);
                          _showToastWithCooldown(
                            context,
                            'Email updated. OTP sent to $newEmail',
                            ToastType.success,
                          );
                          _changeEmailController.clear();
                        } else {
                          _showToastWithCooldown(
                            context,
                            'Enter a valid email address',
                            ToastType.error,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4A90E2),
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text('Confirm'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OtpBloc, OtpState>(
      listener: (context, state) {
        if (state is OtpSentSuccess) {
          _showToastWithCooldown(
            context,
            'OTP sent successfully! Check your email.',
            ToastType.success,
          );
        } else if (state is OtpSentFailure) {
          _showToastWithCooldown(
            context,
            'Failed to send OTP. Try again.',
            ToastType.error,
          );
        } else if (state is OtpVerifiedSuccess) {
          widget.onVerified();
          Navigator.of(context).pop();
        } else if (state is OtpVerifiedFailure) {
          _showToastWithCooldown(
            context,
            'Invalid OTP. Please try again.',
            ToastType.error,
          );
        }
      },
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.2),
        child: DraggableScrollableSheet(
          initialChildSize: getModalHeight(context),
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Color(0xFF1E1E1E)
                      : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Header
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Color(0xFF4A90E2).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.verified_user_outlined,
                              color: Color(0xFF4A90E2),
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Verify Your Email',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Color(0xFF273236),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Enter the 6-digit code sent to',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  email,
                                  style: TextStyle(
                                    color: Color(0xFF4A90E2),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 32),

                      // OTP Input Field
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 4,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          labelText: 'Enter OTP Code',
                          labelStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey[400]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: Color(0xFF4A90E2), width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                          counterText: '',
                          hintText: '000000',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      // Verify Button
                      BlocBuilder<OtpBloc, OtpState>(
                        builder: (context, state) {
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: state is OtpLoading
                                  ? null
                                  : () {
                                      final otp = otpController.text.trim();
                                      if (otp.length == 6) {
                                        context.read<OtpBloc>().add(
                                            VerifyOtpEvent(
                                                email: email, otp: otp));
                                      } else {
                                        _showToastWithCooldown(
                                          context,
                                          'Please enter a valid 6-digit OTP',
                                          ToastType.error,
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF4A90E2),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                                shadowColor: Color(0xFF4A90E2).withOpacity(0.3),
                              ),
                              child: state is OtpLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.verified_outlined, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Verify OTP',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                context
                                    .read<OtpBloc>()
                                    .add(SendOtpEvent(email: email));
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Color(0xFF4A90E2),
                                side: BorderSide(color: Color(0xFF4A90E2)),
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.refresh_outlined, size: 18),
                                  SizedBox(width: 6),
                                  Text('Resend OTP'),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _showChangeEmailDialog(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                side: BorderSide(color: Colors.grey[400]!),
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.email_outlined, size: 18),
                                  SizedBox(width: 6),
                                  Text('Change Email'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).viewInsets.bottom > 0
                              ? 16
                              : 0),
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

  @override
  void dispose() {
    otpController.dispose();
    _changeEmailController.dispose();
    super.dispose();
  }
}
