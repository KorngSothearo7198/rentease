import 'package:flutter/material.dart';

class JoinAsOwnerScreen extends StatefulWidget {
  const JoinAsOwnerScreen({super.key});

  @override
  State<JoinAsOwnerScreen> createState() => _JoinAsOwnerScreenState();
}

class _JoinAsOwnerScreenState extends State<JoinAsOwnerScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Join as Owner',
          style: TextStyle(
            color: Color(0xFF6B46C1),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Title
              const Text(
                'Start Your Hosting\nJourney',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Join thousands of owners earning passive\nincome with Rentify.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),

              // Form Card
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
                    // Full Name
                    const Text('Full Name', style: _labelStyle),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: _inputDecoration(
                        hint: 'John Doe',
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Email
                    const Text('Email Address', style: _labelStyle),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        hint: 'john@example.com',
                        icon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Phone
                    const Text('Phone Number', style: _labelStyle),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(
                        hint: '+1 (555) 000-0000',
                        icon: Icons.phone_outlined,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password
                    const Text('Password', style: _labelStyle),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration(
                        hint: 'Min. 8 characters',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        obscure: _obscurePassword,
                        onVisibilityTap: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () {
                          // TODO: Register as Owner logic
                        },
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
                          'Register as Owner',
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

                    // Social Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: Image.asset(
                              'assets/google.png', // add your asset
                              height: 22,
                              errorBuilder: (_, __, ___) =>
                              const Icon(Icons.g_mobiledata, size: 28),
                            ),
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

              const SizedBox(height: 28),

              // Already have account
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: Colors.black54),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: Color(0xFF6B46C1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Terms
              Text(
                'By registering, you agree to our Terms of Service and\nPrivacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 30),
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