import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_mobile_app/screens/dashboard_screen.dart';
import 'package:my_mobile_app/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Wrap the app in ProviderScope so Riverpod works everywhere
  runApp(const ProviderScope(child: MySellableApp()));
}

class MySellableApp extends StatelessWidget {
  const MySellableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Premium App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue, // Change this to your brand color
        textTheme: GoogleFonts.poppinsTextTheme(), // Makes it look professional
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If the snapshot has user data, they are logged in!
          if (snapshot.hasData) {
            return const DashboardScreen(); // User is logged in, show dashboard
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class MainEntryScreen extends ConsumerWidget {
  const MainEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Store")),
      body: const Center(child: Text("Welcome to your production-ready app!")),
    );
  }
}
