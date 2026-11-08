import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService authService = AuthService();

  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool codeChecked = false;

  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;

  String? resetCode;
  String? resetEmail;

  // ============================================================
  // SEND RESET EMAIL
  // ============================================================

  Future<void> _sendResetEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showMessage('Please enter your email address.');
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage('Please enter a valid email address.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await authService.sendPasswordResetCode(email: email);

      if (!mounted) return;

      resetEmail = email;

      _showMessage('Reset code sent to your email. Please check your inbox.');

      setState(() {
        codeChecked = false;
      });
    } catch (e) {
      debugPrint('SEND RESET CODE ERROR: $e');

      if (!mounted) return;

      _showMessage(_resetErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // CHECK CODE
  // ============================================================

  Future<void> _checkCode() async {
    final code = codeController.text.trim();

    if (code.isEmpty) {
      _showMessage('Please enter the reset code from your email.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final email = await authService.verifyPasswordResetCode(code: code);

      resetCode = code;

      if (email.isNotEmpty) {
        resetEmail = email;
      }

      if (!mounted) return;

      setState(() {
        codeChecked = true;
      });

      _showMessage('Code verified successfully.');
    } catch (e) {
      debugPrint('VERIFY RESET CODE ERROR: $e');

      if (!mounted) return;

      setState(() {
        codeChecked = false;
        resetCode = null;
      });

      _showMessage(_resetErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================

  Future<void> _resetPassword() async {
    if (!codeChecked || resetCode == null) {
      _showMessage('Please verify the code first.');
      return;
    }

    final password = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (password.isEmpty) {
      _showMessage('Please enter your new password.');
      return;
    }

    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters.');
      return;
    }

    if (confirmPassword.isEmpty) {
      _showMessage('Please confirm your new password.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final email = await authService.confirmPasswordReset(
        code: resetCode!,
        newPassword: password,
      );

      debugPrint('PASSWORD RESET SUCCESS: $email');

      if (!mounted) return;

      _showMessage('Password changed successfully.');

      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      debugPrint('CONFIRM PASSWORD RESET ERROR: $e');

      if (!mounted) return;

      _showMessage(_resetErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // EMAIL VALIDATION
  // ============================================================

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  // ============================================================
  // FIREBASE ERROR
  // ============================================================

  String _firebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'user-not-found':
        return 'No account found with this email.';

      case 'too-many-requests':
        return 'Too many requests. Please try again later.';

      default:
        return e.message ?? 'Something went wrong.';
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ==================================================
              // ICON
              // ==================================================
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF00C2FF)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Center(
                child: Text(
                  'Reset Your Password',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Center(
                child: Text(
                  "Enter the email address registered with your Rentify account.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 15),
                ),
              ),

              const SizedBox(height: 32),

              // ==================================================
              // EMAIL
              // ==================================================
              const Text('Email Address', style: _labelStyle),

              const SizedBox(height: 8),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !codeChecked,
                decoration: _inputDecoration(
                  hint: 'name@example.com',
                  icon: Icons.email_outlined,
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // SEND EMAIL
              // ==================================================
              if (!codeChecked)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _sendResetEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B46C1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Send Reset Code',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

              // ==================================================
              // CODE
              // ==================================================
              if (!codeChecked) ...[
                const SizedBox(height: 28),

                const Text('Paste reset code from email', style: _labelStyle),

                const SizedBox(height: 8),

                TextField(
                  controller: codeController,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.none,
                  decoration: _inputDecoration(
                    hint: 'Paste the code from your email',
                    icon: Icons.verified_user_outlined,
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: isLoading ? null : _checkCode,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF6B46C1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Verify Code',
                      style: TextStyle(
                        color: Color(0xFF6B46C1),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],

              // ==================================================
              // NEW PASSWORD
              // ==================================================
              if (codeChecked) ...[
                const SizedBox(height: 28),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Email code verified. You can now create a new password.',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text('New Password', style: _labelStyle),

                const SizedBox(height: 8),

                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  decoration: _inputDecoration(
                    hint: 'Enter new password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    obscure: obscureNewPassword,
                    onVisibilityTap: () {
                      setState(() {
                        obscureNewPassword = !obscureNewPassword;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),

                const Text('Confirm New Password', style: _labelStyle),

                const SizedBox(height: 8),

                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: _inputDecoration(
                    hint: 'Confirm new password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    obscure: obscureConfirmPassword,
                    onVisibilityTap: () {
                      setState(() {
                        obscureConfirmPassword = !obscureConfirmPassword;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B46C1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Reset Password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _resetErrorMessage(Object error) {
    final message = error.toString();

    if (message.contains('EMAIL_NOT_FOUND')) {
      return 'No account found with this email.';
    }

    if (message.contains('INVALID_OOB_CODE')) {
      return 'The reset code is invalid.';
    }

    if (message.contains('EXPIRED_OOB_CODE')) {
      return 'The reset code has expired. Please request a new one.';
    }

    if (message.contains('WEAK_PASSWORD')) {
      return 'Password must be at least 6 characters.';
    }

    if (message.contains('TOO_MANY_ATTEMPTS_TRY_LATER')) {
      return 'Too many attempts. Please try again later.';
    }

    if (message.contains('INVALID_EMAIL')) {
      return 'Please enter a valid email address.';
    }

    return 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }
}

const TextStyle _labelStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  color: Colors.black87,
);

InputDecoration _inputDecoration({
  required String hint,
  required IconData icon,
  bool isPassword = false,
  VoidCallback? onVisibilityTap,
  bool obscure = false,
}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: Colors.grey),
    suffixIcon: isPassword
        ? IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: onVisibilityTap,
          )
        : null,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    filled: true,
    fillColor: const Color(0xFFF8F5FF),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}
