import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'auth_gate.dart';
import 'hour_slot.dart';

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

class DayScreen extends StatelessWidget {
  const DayScreen({super.key});

  void openHour(BuildContext context, HourSlot slot) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditHourScreen(slot: slot)),
    );
  }

  Future<void> deleteHour(BuildContext context, HourSlot slot) async {
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
      // Delete exactly this hour's document
      await myHours().doc('${slot.hour}').delete();
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: myHours().orderBy('hour').snapshots(),
        builder: (context, snapshot) {
          // Error state: for example, the rules refused
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load your day.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Loading state: nothing has arrived yet
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final day = snapshot.data!.docs.map(HourSlot.fromDoc).toList();

          // Empty state: this user has no hours yet
          if (day.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Your day is empty.',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => addSampleHours(),
                      child: const Text('Add a sample day'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Computed every time the data arrives, never saved
          final battery = simulate(day);
          final death = deathHour(day);

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

                    if (isDead) {
                      return ListTile(
                        onTap: () => openHour(context, slot),
                        onLongPress: () => deleteHour(context, slot),
                        leading: Text('${slot.hour}:00'),
                        title: Row(
                          children: [
                            Text(slot.activity),
                            if (slot.charging)
                              const Icon(Icons.bolt, color: Colors.amber),
                          ],
                        ),
                        subtitle: const Text('☠ Phone is dead'),
                        trailing: const Text('—'),
                      );
                    }

                    return ListTile(
                      onTap: () => openHour(context, slot),
                      onLongPress: () => deleteHour(context, slot),
                      leading: Text('${slot.hour}:00'),
                      title: Row(
                        children: [
                          Text(slot.activity),
                          if (slot.charging)
                            const Icon(Icons.bolt, color: Colors.amber),
                        ],
                      ),
                      subtitle: LinearProgressIndicator(
                        value: battery[index] / 100,
                        minHeight: 8,
                        color: battery[index] < 20 ? Colors.red : Colors.green,
                      ),
                      trailing: Text('${battery[index]}%'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

const drainPerHour = {
  'video': 12,
  'games': 15,
  'chat': 5,
  'music': 6,
  'idle': 2,
};

int drainOf(String activity) {
  return drainPerHour[activity] ?? 0;
}

List<int> simulate(List<HourSlot> day) {
  final results = <int>[];
  int battery = 100;

  for (final slot in day) {
    battery = battery - drainOf(slot.activity);

    if (slot.charging) {
      battery = battery + 20;
    }

    if (battery < 0) {
      battery = 0;
    }
    if (battery > 100) {
      battery = 100;
    }

    results.add(battery);
  }

  return results;
}

int? deathHour(List<HourSlot> day) {
  final results = simulate(day);

  for (int i = 0; i < results.length; i++) {
    if (results[i] == 0) {
      return day[i].hour;
    }
  }

  return null;
}

List<HourSlot> dayWithCharging(List<int> chargingHours) {
  final day = sampleDay();

  for (final slot in day) {
    if (chargingHours.contains(slot.hour)) {
      slot.charging = true;
    }
  }

  return day;
}

class EditHourScreen extends StatefulWidget {
  const EditHourScreen({super.key, required this.slot});

  final HourSlot slot;

  @override
  State<EditHourScreen> createState() => _EditHourScreenState();
}

class _EditHourScreenState extends State<EditHourScreen> {
  String activity = '';
  bool charging = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    activity = widget.slot.activity;
    charging = widget.slot.charging;
  }

  Future<void> save() async {
    setState(() => saving = true);
    try {
      // Update exactly this hour's document in Firestore
      await myHours().doc('${widget.slot.hour}').update({
        'activity': activity,
        'charging': charging,
      });
      if (mounted) Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: ${e.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit ${widget.slot.hour}:00')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final name in drainPerHour.keys)
                  ChoiceChip(
                    label: Text('$name (-${drainOf(name)}%)'),
                    selected: activity == name,
                    onSelected: (_) {
                      setState(() {
                        activity = name;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Charging (+20%)'),
              value: charging,
              onChanged: (value) {
                setState(() {
                  charging = value;
                });
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: saving ? null : save,
                child: Text(saving ? 'Saving…' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}