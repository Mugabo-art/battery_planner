// Translation table (Session 7)
// MoMo Wallet            -> Battery Planner
// Txn, txn.dart          -> HourSlot, hour_slot.dart
// transactions           -> hours
// TxnRepository          -> HourRepository
// WalletState            -> BatteryState
// balance                -> battery (list of %), deathHour
// WalletScreen, TxnForm  -> DayScreen, EditHourScreen

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/auth_gate.dart';
import 'widgets/activity_style.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const BatteryApp());
}

class BatteryApp extends StatelessWidget {
  const BatteryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Battery Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.green,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.green,
          onPrimary: Colors.black,
          surface: AppColors.bg,
          error: AppColors.red,
        ),
      ),
      home: const AuthGate(),
    );
  }
}