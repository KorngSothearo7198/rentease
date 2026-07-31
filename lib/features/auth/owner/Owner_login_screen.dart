import 'package:flutter/material.dart';
import 'package:rentease/features/auth/owner/register_screen.dart';
import 'package:rentease/features/owner/screens/owner_home_screen.dart'; // adjust path
import '../../../services/auth_service.dart';
// import '../services/auth_service.dart';

class OwnerLoginScreen extends StatefulWidget {
  const OwnerLoginScreen({super.key});

  @override
  State<OwnerLoginScreen> createState() => _OwnerLoginScreenState();
}

class _OwnerLoginScreenState extends State<OwnerLoginScreen> {
  final AuthService authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool isLoading = false;

  Future<void> _handleLogin() async {
    if (emailController.text.trim().isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      String? role = await authService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;

      if (role == "owner") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OwnerHomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("This account is not an Owner")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Logo
              const Text(
                'Rentify',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B46C1),
                ),
              ),

              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B46C1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'OWNER PORTAL',
                  style: TextStyle(
                    color: Color(0xFF6B46C1),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                'Welcome Back, Host',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Log in to manage your properties & earnings',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Login Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email
                    const Text('Email Address', style: _labelStyle),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        hint: 'owner@rentify.com',
                        icon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Password', style: _labelStyle),
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Color(0xFF6B46C1),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration(
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        obscure: _obscurePassword,
                        onVisibilityTap: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B46C1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          'Sign In as Owner',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Divider
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR CONTINUE WITH',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Social
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.g_mobiledata, size: 28),
                            label: const Text('Google'),
                            style: _socialButtonStyle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.apple, size: 26),
                            label: const Text('Apple'),
                            style: _socialButtonStyle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Join as Owner
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an owner account? ",
                    style: TextStyle(color: Colors.black54),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const JoinAsOwnerScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Join as Owner',
                      style: TextStyle(
                        color: Color(0xFF6B46C1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// Helpers
const TextStyle _labelStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  color: Colors.black87,
);

InputDecoration _inputDecoration({
  required String hint,
  required IconData icon,
  bool isPassword = false,
  bool obscure = false,
  VoidCallback? onVisibilityTap,
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
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    filled: true,
    fillColor: const Color(0xFFF8F5FF),
  );
}

final ButtonStyle _socialButtonStyle = OutlinedButton.styleFrom(
  padding: const EdgeInsets.symmetric(vertical: 14),
  side: const BorderSide(color: Colors.grey),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);