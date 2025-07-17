import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:inventory_app/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jayhawk Liquor Inventory',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          primary: const Color.fromARGB(255, 13, 110, 253),
          secondary: const Color.fromARGB(255, 173, 181, 189),
          seedColor: const Color.fromARGB(255, 13, 110, 253),
          error: Color.fromARGB(255,220, 53, 69)
        ),
      ),
      home: HomePage(),
    );
  }
}
