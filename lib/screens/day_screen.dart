import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/hour_slot.dart';
import '../state/battery_state.dart';
import 'edit_hour_screen.dart';

class DayScreen extends StatelessWidget {
  const DayScreen({super.key});

  // Open the edit screen and hand it the SAME brain.
  void _openHour(BuildContext context, HourSlot slot) {
    final state = context.read<BatteryState>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<BatteryState>.value(
          value: state,
          child: EditHourScreen(slot: slot),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, HourSlot slot) async {
    final state = context.read<BatteryState>(); // read BEFORE the await
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this hour?'),
        content: Text('${slot.hour}:00 · ${slot.activity}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (sure == true) {
      await state.remove(slot);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BatteryState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battery Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: _body(context, state),
    );
  }

  Widget _body(BuildContext context, BatteryState state) {
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(state.error!, textAlign: TextAlign.center),
        ),
      );
    }

    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final day = state.hours;

    if (day.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Your day is empty.', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.read<BatteryState>().addSamples(),
                child: const Text('Add a sample day'),
              ),
            ],
          ),
        ),
      );
    }

    final battery = state.battery; // computed in the brain
    final death = state.deathHour; // computed in the brain

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: death != null ? Colors.red : Colors.green,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            death != null
                ? '☠ Dies at $death:00'
                : 'Survives with ${battery.last}% left',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: day.length,
            itemBuilder: (context, index) {
              final slot = day[index];
              final isDead = death != null && slot.hour > death;

              return ListTile(
                onTap: () => _openHour(context, slot),
                onLongPress: () => _delete(context, slot),
                leading: Text('${slot.hour}:00'),
                title: Row(
                  children: [
                    Text(slot.activity),
                    if (slot.charging)
                      const Icon(Icons.bolt, color: Colors.amber),
                  ],
                ),
                subtitle: isDead
                    ? const Text('☠ Phone is dead')
                    : LinearProgressIndicator(
                  value: battery[index] / 100,
                  minHeight: 8,
                  color: battery[index] < 20 ? Colors.red : Colors.green,
                ),
                trailing: Text(isDead ? '—' : '${battery[index]}%'),
              );
            },
          ),
        ),
      ],
    );
  }
}