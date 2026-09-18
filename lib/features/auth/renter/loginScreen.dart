// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:rentease/features/auth/renter/registerScreen.dart';
// import '../../../models/user_model.dart';
// import '../../../services/auth_service.dart';
// import '../../../services/notification_service.dart';
// import '../../../services/session_service.dart';
// import '../../owner/screens/owner_home_screen.dart';
// import '../../renter/screens/renter_home_screen.dart';
//
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   final AuthService authService = AuthService();
//
//   final emailController = TextEditingController();
//   final passwordController = TextEditingController();
//
//   bool _obscurePassword = true;
//   bool isLoading = false;
//
//   Future<void> _handleLogin() async {
//     if (emailController.text.trim().isEmpty ||
//         passwordController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please enter email and password")),
//       );
//       return;
//     }
//
//     setState(() => isLoading = true);
//
//     try {
//       UserModel? user = await authService.login(
//         email: emailController.text.trim(),
//         password: passwordController.text,
//       );
//
//       if (!mounted) return;
//
//       if (user == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("User not found")),
//         );
//         return;
//       }
//
//       // Save user locally
//       await SessionService.saveUser(user.toJson());
//       // await NotificationService().saveFCMToken(user.uid);
//
//       if (user.role == "owner") {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (_) => const OwnerHomeScreen(),
//           ),
//         );
//       } else if (user.role == "renter") {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (_) => const RenterHomeScreen(),
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Invalid user role")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(e.toString())),
//       );
//     } finally {
//       if (mounted) {
//         setState(() => isLoading = false);
//       }
//     }
//
//   }
//
//   @override
//   void dispose() {
//     emailController.dispose();
//     passwordController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F5FF),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0),
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 const SizedBox(height: 40),
//
//                 // Rentify Title
//                 const Text(
//                   'Rentify',
//                   style: TextStyle(
//                     fontSize: 32,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF6B46C1),
//                   ),
//                 ),
//
//                 const SizedBox(height: 40),
//
//                 const Text(
//                   'Welcome Back',
//                   style: TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 const Text(
//                   'Log in to manage your luxury rentals',
//                   style: TextStyle(fontSize: 16, color: Colors.black54),
//                   textAlign: TextAlign.center,
//                 ),
//
//                 const SizedBox(height: 40),
//
//                 // Login Card
//                 Container(
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(24),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.05),
//                         blurRadius: 20,
//                         offset: const Offset(0, 10),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Email Field
//                       const Text('Email Address', style: _labelStyle),
//                       const SizedBox(height: 8),
//                       TextField(
//                         controller: emailController,
//                         keyboardType: TextInputType.emailAddress,
//                         decoration: _inputDecoration(
//                           hint: 'name@luxury.com',
//                           icon: Icons.email_outlined,
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//
//                       // Password Field
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           const Text('Password', style: _labelStyle),
//                           GestureDetector(
//                             onTap: () {
//                               // TODO: Forgot Password Navigation
//                             },
//                             child: const Text(
//                               'Forgot Password?',
//                               style: TextStyle(
//                                 color: Color(0xFF6B46C1),
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),
//                       TextField(
//                         controller: passwordController,
//                         obscureText: _obscurePassword,
//                         decoration: _inputDecoration(
//                           hint: '••••••••',
//                           icon: Icons.lock_outline,
//                           isPassword: true,
//                           onVisibilityTap: () {
//                             setState(
//                               () => _obscurePassword = !_obscurePassword,
//                             );
//                           },
//                           obscure: _obscurePassword,
//                         ),
//                       ),
//                       const SizedBox(height: 32),
//
//                       // Sign In Button
//                       SizedBox(
//                         width: double.infinity,
//                         height: 56,
//                         child: ElevatedButton(
//                           onPressed: isLoading ? null : _handleLogin,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF6B46C1),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(30),
//                             ),
//                           ),
//                           child: isLoading
//                               ? const CircularProgressIndicator(
//                                   color: Colors.white,
//                                 )
//                               : const Text(
//                                   'Sign In',
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                         ),
//                       ),
//
//                       const SizedBox(height: 24),
//
//                       // OR Divider
//                       const Row(
//                         children: [
//                           Expanded(child: Divider()),
//                           Padding(
//                             padding: EdgeInsets.symmetric(horizontal: 16),
//                             child: Text(
//                               'OR CONTINUE WITH',
//                               style: TextStyle(
//                                 color: Colors.grey,
//                                 fontSize: 13,
//                               ),
//                             ),
//                           ),
//                           Expanded(child: Divider()),
//                         ],
//                       ),
//                       const SizedBox(height: 24),
//
//                       // Social Login Buttons
//                       Row(
//                         children: [
//                           Expanded(
//                             child: OutlinedButton.icon(
//                               onPressed: () {},
//                               icon: Image.asset(
//                                 'assets/google.png',
//                                 height: 24,
//                               ),
//                               label: const Text('Google'),
//                               style: _socialButtonStyle,
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: OutlinedButton.icon(
//                               onPressed: () {},
//                               icon: const Icon(Icons.apple, size: 28),
//                               label: const Text('Apple'),
//                               style: _socialButtonStyle,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 const SizedBox(height: 32),
//
//                 // Sign Up Link
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text(
//                       "Don't have an account? ",
//                       style: TextStyle(color: Colors.black54),
//                     ),
//                     GestureDetector(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const RegisterScreen(),
//                           ),
//                         );
//                       },
//                       child: const Text(
//                         'Sign up for free',
//                         style: TextStyle(
//                           color: Color(0xFF6B46C1),
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 const SizedBox(height: 40),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // Reusable Helpers
// const TextStyle _labelStyle = TextStyle(
//   fontSize: 14,
//   fontWeight: FontWeight.w600,
//   color: Colors.black87,
// );
//
// InputDecoration _inputDecoration({
//   required String hint,
//   required IconData icon,
//   bool isPassword = false,
//   VoidCallback? onVisibilityTap,
//   bool obscure = false,
// }) {
//   return InputDecoration(
//     hintText: hint,
//     prefixIcon: Icon(icon, color: Colors.grey),
//     suffixIcon: isPassword
//         ? IconButton(
//             icon: Icon(
//               obscure ? Icons.visibility_off : Icons.visibility,
//               color: Colors.grey,
//             ),
//             onPressed: onVisibilityTap,
//           )
//         : null,
//     border: OutlineInputBorder(
//       borderRadius: BorderRadius.circular(12),
//       borderSide: BorderSide.none,
//     ),
//     filled: true,
//     fillColor: const Color(0xFFF8F5FF),
//   );
// }
//
// final ButtonStyle _socialButtonStyle = OutlinedButton.styleFrom(
//   padding: const EdgeInsets.symmetric(vertical: 16),
//   side: const BorderSide(color: Colors.grey),
//   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// );

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:rentease/features/auth/renter/registerScreen.dart';

import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/session_service.dart';

import '../../owner/screens/owner_home_screen.dart';
import '../../renter/screens/renter_home_screen.dart';

enum LoginType { renter, owner }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  LoginType selectedLoginType = LoginType.renter;

  bool _obscurePassword = true;
  bool isLoading = false;

  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  // ============================================================
  // LOGIN
  // ============================================================
  Future<void> _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter email and password.');
      return;
    }

    setState(() => isLoading = true);

    try {
      UserModel? user = await authService.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (user == null) {
        _showMessage('User account was not found.');
        return;
      }

      final expectedRole =
      selectedLoginType == LoginType.owner ? 'owner' : 'renter';

      if (user.role.toLowerCase() != expectedRole) {
        _showMessage(
          selectedLoginType == LoginType.owner
              ? 'This account is not an Owner account.'
              : 'This account is not a Renter account.',
        );
        return;
      }

      if (user.accountStatus.toLowerCase() != 'active') {
        _showMessage('Your account is not active.');
        return;
      }

      await SessionService.saveUser(user.toJson());

      if (user.role.toLowerCase() == 'owner') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OwnerHomeScreen()),
        );
      } else if (user.role.toLowerCase() == 'renter') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RenterHomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(_firebaseErrorMessage(e));
    } catch (e) {
      _showMessage('Login failed. Please try again.');
      debugPrint('LOGIN ERROR: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ============================================================
  // SEGMENTED CONTROL
  // ============================================================
  Widget _buildLoginTypeSelector() {
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
          Expanded(
            child: GestureDetector(
              onTap: () => _selectLoginType(LoginType.renter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: selectedLoginType == LoginType.renter
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
                      color: selectedLoginType == LoginType.renter
                          ? Colors.white
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Renter',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: selectedLoginType == LoginType.renter
                            ? Colors.white
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _selectLoginType(LoginType.owner),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: selectedLoginType == LoginType.owner
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
                      color: selectedLoginType == LoginType.owner
                          ? Colors.white
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Owner',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: selectedLoginType == LoginType.owner
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

  String _firebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      default:
        return e.message ?? 'Login failed.';
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _selectLoginType(LoginType type) {
    setState(() => selectedLoginType = type);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    // Animation values based on scroll
    final double progress = (_scrollOffset / 120).clamp(0.0, 1.0);

    final double logoSize = 64 - (progress * 24);          // 64 → 40
    final double logoIconSize = 32 - (progress * 10);      // 32 → 22
    final double logoRadius = 18 - (progress * 6);         // 18 → 12
    final double titleSize = 30 - (progress * 6);          // 30 → 24
    final double topSpace = 45 - (progress * 20);          // 45 → 25
    final double afterLogoSpace = 18 - (progress * 8);     // 18 → 10
    final double afterTitleSpace = 36 - (progress * 16);   // 36 → 20
    final double subtitleOpacity = 1.0 - progress;         // fade out

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(height: topSpace),

                    // ================= LOGO (animated) =================
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 50),
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF00C2FF)],
                        ),
                        borderRadius: BorderRadius.circular(logoRadius),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C63FF)
                                .withOpacity(0.25 * (1 - progress * 0.5)),
                            blurRadius: 20 - (progress * 8),
                            offset: Offset(0, 8 - (progress * 3)),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.home_rounded,
                        color: Colors.white,
                        size: logoIconSize,
                      ),
                    ),

                    SizedBox(height: afterLogoSpace),

                    // ================= APP NAME =================
                    Text(
                      'Rentify',
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                      ),
                    ),

                    SizedBox(height: afterTitleSpace),

                    // ================= WELCOME TEXT =================
                    Opacity(
                      opacity: subtitleOpacity,
                      child: Column(
                        children: [
                          const Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Choose your account type to continue',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ================= SEGMENTED CONTROL =================
                    _buildLoginTypeSelector(),

                    const SizedBox(height: 28),

                    // ================= LOGIN FORM =================
                    _buildLoginForm(),

                    const SizedBox(height: 28),

                    // ================= REGISTER =================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Colors.black54),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Sign up for free',
                            style: TextStyle(
                              color: Color(0xFF6B46C1),
                              fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOGIN FORM
  // ============================================================
  Widget _buildLoginForm() {
    final loginTitle = selectedLoginType == LoginType.owner
        ? 'Owner Login'
        : 'Renter Login';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(selectedLoginType),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
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
            Text(
              loginTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Email Address', style: _labelStyle),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(
                hint: 'name@example.com',
                icon: Icons.email_outlined,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Password', style: _labelStyle),
                GestureDetector(
                  onTap: () {
                    // TODO: Forgot password
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Color(0xFF6B46C1),
                      fontWeight: FontWeight.w600,
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
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleLogin,
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
                  width: 23,
                  height: 23,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  selectedLoginType == LoginType.owner
                      ? 'Login as Owner'
                      : 'Login as Renter',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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