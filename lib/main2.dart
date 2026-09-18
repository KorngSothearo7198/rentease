import 'package:flutter/material.dart';
import 'package:rentease/features/auth/renter/loginScreen.dart';
import 'package:rentease/features/owner/screens/owner_home_screen.dart';
import 'package:rentease/features/owner/screens/owner_subscription_screen.dart';
import 'package:rentease/features/renter/screens/renter_home_screen.dart';
import 'package:rentease/services/session_service.dart';

import 'features/auth/owner/Owner_login_screen.dart';
import 'features/owner/screens/OwnerSubscriptionScreen.dart';

class Main2 extends StatefulWidget {
  const Main2({super.key});

  @override
  State<Main2> createState() => _Main2State();
}

class _Main2State extends State<Main2> {

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  // Future<void> checkLogin() async {
  //
  //   final user = await SessionService.getUser();
  //
  //   if (!mounted) return;
  //
  //   if (user == null) {
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(
  //         builder: (_) => const LoginScreen(),
  //       ),
  //     );
  //     // Navigator.pushReplacement(
  //     //   context,
  //     //   MaterialPageRoute(
  //     //     builder: (_) => const RenterHomeScreen(),
  //     //   ),
  //     // );
  //     return;
  //   }
  //   debugPrint("UID: ${user["uid"]}");
  //   debugPrint("Full Name: ${user["fullName"]}");
  //   debugPrint("Email: ${user["email"]}");
  //   debugPrint("Phone: ${user["phone"]}");
  //   debugPrint("Role: ${user["role"]}");
  //   debugPrint("================================");
  //
  //   if (user["role"] == "owner") {
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(
  //         builder: (_) => const OwnerHomeScreen(),
  //       ),
  //     );
  //   } else {
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(
  //         builder: (_) => const RenterHomeScreen(),
  //       ),
  //     );
  //   }
  // }

  Future<void> checkLogin() async {
    final user = await SessionService.getUser();

    if (!mounted) return;

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
      return;
    }

    final role = user["role"]?.toString().toLowerCase();

    debugPrint("UID: ${user["uid"]}");
    debugPrint("Full Name: ${user["fullName"]}");
    debugPrint("Email: ${user["email"]}");
    debugPrint("Phone: ${user["phone"]}");
    debugPrint("Role: $role");
    debugPrint("================================");

    if (!mounted) return;

    switch (role) {
      case "owner":
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const OwnerHomeScreen(),
          ),
        );
        break;

      case "renter":
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const RenterHomeScreen(),
          ),
        );
        break;

      default:
        debugPrint("Unknown role: $role");

        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder: (_) => const LoginScreen(),
        //   ),
        // );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const OwnerSubscriptionScreen(),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}