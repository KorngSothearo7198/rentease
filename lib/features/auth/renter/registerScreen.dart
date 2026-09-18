import 'package:flutter/material.dart';
import 'package:rentease/services/auth_service.dart';

enum RegisterType { renter, owner }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  final AuthService _authService = AuthService();

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  RegisterType selectedRegisterType = RegisterType.renter;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool isLoading = false;

  Future<void> register() async {
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    if (!isValidEmail(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid email format")));
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Password does not match")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final role = selectedRegisterType == RegisterType.owner
          ? "owner"
          : "renter";

      final user = await _authService.register(
        fullName: fullName,
        email: email,
        password: password,
        phone: "",
        role: role, // ← now uses selected role
      );

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              selectedRegisterType == RegisterType.owner
                  ? "Owner account created successfully"
                  : "Renter account created successfully",
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _selectRegisterType(RegisterType type) {
    setState(() => selectedRegisterType = type);
  }

  // ============================================================
  // SEGMENTED CONTROL (same style as Login)
  // ============================================================
  Widget _buildRegisterTypeSelector() {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ========== RENTER ==========
          Expanded(
            child: GestureDetector(
              onTap: () => _selectRegisterType(RegisterType.renter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: selectedRegisterType == RegisterType.renter
                      ? const Color(0xFF3B82F6)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_rounded,
                      size: 20,
                      color: selectedRegisterType == RegisterType.renter
                          ? Colors.white
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Renter',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: selectedRegisterType == RegisterType.renter
                            ? Colors.white
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ========== OWNER ==========
          Expanded(
            child: GestureDetector(
              onTap: () => _selectRegisterType(RegisterType.owner),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: selectedRegisterType == RegisterType.owner
                      ? const Color(0xFF3B82F6)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.apartment_rounded,
                      size: 20,
                      color: selectedRegisterType == RegisterType.owner
                          ? Colors.white
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Owner',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: selectedRegisterType == RegisterType.owner
                            ? Colors.white
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonText = selectedRegisterType == RegisterType.owner
        ? "Create Owner Account"
        : "Create Renter Account";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Logo / Brand
              const Text(
                "Rentify",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B46C1),
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Choose your account type to get started",
                style: TextStyle(color: Colors.black54, fontSize: 15),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // ========== ROLE SELECTOR ==========
              _buildRegisterTypeSelector(),

              const SizedBox(height: 28),

              // ========== FORM CARD ==========
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
                    const Text("Full Name", style: _labelStyle),
                    const SizedBox(height: 8),
                    TextField(
                      controller: fullNameController,
                      decoration: _inputDecoration(hint: "John Doe"),
                    ),

                    const SizedBox(height: 20),
                    const Text("Email Address", style: _labelStyle),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(hint: "name@gmail.com"),
                    ),

                    const SizedBox(height: 20),
                    const Text("Password", style: _labelStyle),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration(
                        hint: "••••••••",
                        isPassword: true,
                        obscure: _obscurePassword,
                        onVisibilityTap: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text("Confirm Password", style: _labelStyle),
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: _inputDecoration(
                        hint: "••••••••",
                        isPassword: true,
                        obscure: _obscureConfirmPassword,
                        onVisibilityTap: () {
                          setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Create Account Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B46C1),
                          disabledBackgroundColor: const Color(0xFFB8A8E8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                buttonText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(color: Colors.black54),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            "Sign in",
                            style: TextStyle(
                              color: Color(0xFF6B46C1),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HELPERS
// ============================================================
const TextStyle _labelStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  color: Colors.black87,
);

InputDecoration _inputDecoration({
  required String hint,
  bool isPassword = false,
  VoidCallback? onVisibilityTap,
  bool obscure = false,
}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(
      isPassword ? Icons.lock_outline : Icons.person_outline,
      color: Colors.grey,
    ),
    suffixIcon: isPassword
        ? IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: onVisibilityTap,
          )
        : null,
    filled: true,
    fillColor: const Color(0xFFF8F5FF),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}
