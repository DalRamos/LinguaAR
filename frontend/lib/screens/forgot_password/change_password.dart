import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lingua_arv1/repositories/change_password_repositories/reset_password_repository_impl.dart';
import '../../bloc/change_password/change_password_bloc.dart';
import '../authentication/login/login_page.dart';
import '../../validators/password_validator.dart';
import '../../widgets/toast.dart';

class ChangePasswordModal extends StatefulWidget {
  final String email;
  final String otp;

  ChangePasswordModal({required this.email, required this.otp});

  @override
  State<ChangePasswordModal> createState() => _ChangePasswordModalState();
}

class _ChangePasswordModalState extends State<ChangePasswordModal> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? newPasswordError;
  String? confirmPasswordError;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChangePasswordBloc(PasswordRepositoryImpl(),
          resetPasswordRepository: null),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: SafeArea(
          child: BlocConsumer<ChangePasswordBloc, ChangePasswordState>(
            listener: (context, state) {
              if (state is ChangePasswordSuccess) {
                TopToast.show(
                  context,
                  'Password changed successfully!',
                  type: ToastType.success,
                  duration: Duration(seconds: 2),
                );
                Future.delayed(Duration(milliseconds: 500), () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
                    (route) => false,
                  );
                });
              } else if (state is ChangePasswordFailure) {
                TopToast.show(
                  context,
                  'Failed to change password. Please try again.',
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
                        Icons.lock_outline,
                        color: Color(0xFF4A90E2),
                        size: 40,
                      ),
                    ),

                    SizedBox(height: 24),

                    // Title
                    Text(
                      'Create New Password',
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
                      child: Text(
                        'Create a strong new password for your account security',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onBackground
                              .withOpacity(0.7),
                        ),
                      ),
                    ),

                    SizedBox(height: 32),

                    // Password Input Fields
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // New Password Field
                          Container(
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
                              controller: newPasswordController,
                              obscureText: _obscurePassword,
                              style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.onBackground,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Enter New Password',
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
                                fillColor:
                                    Theme.of(context).colorScheme.surface,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 20),
                                prefixIcon: Container(
                                  margin: EdgeInsets.only(right: 12, left: 16),
                                  child: Icon(
                                    Icons.lock_outline,
                                    color: Color(0xFF4A90E2),
                                    size: 24,
                                  ),
                                ),
                                suffixIcon: Container(
                                  margin: EdgeInsets.only(right: 8),
                                  child: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() =>
                                          _obscurePassword = !_obscurePassword);
                                    },
                                  ),
                                ),
                                errorText: newPasswordError,
                              ),
                              validator: (value) {
                                final error =
                                    PasswordValidator.validate(value ?? '');
                                return error;
                              },
                              onChanged: (value) {
                                setState(() {
                                  newPasswordError =
                                      PasswordValidator.validate(value);
                                  if (confirmPasswordError != null &&
                                      value == confirmPasswordController.text) {
                                    confirmPasswordError = null;
                                  }
                                });
                              },
                            ),
                          ),

                          SizedBox(height: 16),

                          // Confirm Password Field
                          Container(
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
                              controller: confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.onBackground,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Confirm New Password',
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
                                fillColor:
                                    Theme.of(context).colorScheme.surface,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 20),
                                prefixIcon: Container(
                                  margin: EdgeInsets.only(right: 12, left: 16),
                                  child: Icon(
                                    Icons.lock_outline,
                                    color: Color(0xFF4A90E2),
                                    size: 24,
                                  ),
                                ),
                                suffixIcon: Container(
                                  margin: EdgeInsets.only(right: 8),
                                  child: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() => _obscureConfirmPassword =
                                          !_obscureConfirmPassword);
                                    },
                                  ),
                                ),
                                errorText: confirmPasswordError,
                              ),
                              validator: (value) {
                                if (value != newPasswordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                setState(() {
                                  confirmPasswordError =
                                      value == newPasswordController.text
                                          ? null
                                          : 'Passwords do not match';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32),

                    // Change Password Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state is ChangePasswordLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    newPasswordError =
                                        PasswordValidator.validate(
                                            newPasswordController.text.trim());
                                    confirmPasswordError =
                                        confirmPasswordController.text.trim() ==
                                                newPasswordController.text
                                                    .trim()
                                            ? null
                                            : 'Passwords do not match';
                                  });

                                  if (newPasswordError == null &&
                                      confirmPasswordError == null) {
                                    context
                                        .read<ChangePasswordBloc>()
                                        .add(ResetPasswordEvent(
                                          email: widget.email,
                                          otp: widget.otp,
                                          newPassword:
                                              newPasswordController.text.trim(),
                                        ));
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4A90E2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shadowColor: Color(0xFF4A90E2).withOpacity(0.3),
                        ),
                        child: state is ChangePasswordLoading
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
                                'Change Password',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
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
