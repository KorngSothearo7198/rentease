import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'features/auth/owner/Owner_login_screen.dart';
import 'features/auth/owner/register_screen.dart';
import 'features/auth/renter/loginScreen.dart';
import 'features/owner/screens/owner_home_screen.dart';
import 'features/renter/screens/renter_home_screen.dart';
import 'features/splashScreen/SplashScreen.dart';
import 'firebase_options.dart';
// import 'firebase_options.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();


  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print("Firebase apps: ${Firebase.apps.length}");

  runApp(
    const MyApp(),
  );

}


class MyApp extends StatelessWidget {

  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner:false,

      title:"RentEase",

      theme: ThemeData(

        primaryColor:
        const Color(0xFF6B46C1),

      ),

      home:
      const OwnerHomeScreen(),

    );

  }

}