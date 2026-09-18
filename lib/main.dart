// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
//
// import 'firebase_options.dart';
// import 'features/splashScreen/SplashScreen.dart';
// import 'color/theme/app_theme.dart';
// import 'color/theme/theme_controller.dart';
// import 'main2.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//
//   runApp(const MyApp());
// }
//
// class MyApp extends StatefulWidget {
//   const MyApp({super.key});
//
//   static final ThemeController themeController = ThemeController();
//
//   @override
//   State<MyApp> createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: MyApp.themeController,
//       builder: (context, child) {
//         return MaterialApp(
//           debugShowCheckedModeBanner: false,
//           title: 'RentEase',
//
//           theme: AppTheme.lightTheme,
//           darkTheme: AppTheme.darkTheme,
//
//           themeMode: MyApp.themeController.themeMode,
//
//           // home: const SplashScreen(),
//           home: RentifySplashScreen()
//
//         );
//       },
//     );
//   }
// }

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'features/splashScreen/SplashScreen.dart';
import 'color/theme/app_theme.dart';
import 'color/theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(
    fileName: '.env',
  );


  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static final ThemeController themeController =
  ThemeController();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: MyApp.themeController,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'RentEase',

          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,

          themeMode: MyApp.themeController.themeMode,

          home: const SplashScreen(),
        );
      },
    );
  }
}