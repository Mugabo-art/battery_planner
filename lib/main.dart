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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const AuthGate(),
    );
  }
}