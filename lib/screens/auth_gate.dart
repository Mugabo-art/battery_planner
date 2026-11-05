import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repositories/hour_repository.dart';
import '../repositories/photo_repository.dart'; // NEW
import '../state/battery_state.dart';
import 'day_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }
        // Signed in: one brain for this user, given to the day screen.
        return ChangeNotifierProvider<BatteryState>(
          create: (_) => BatteryState(
            HourRepository(user.uid),
            PhotoRepository(), // NEW: the brain now gets both repositories
          ),
          child: const DayScreen(),
        );
      },
    );
  }
}