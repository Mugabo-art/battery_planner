import 'package:flutter/material.dart';

void main() {
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
      home: const DayScreen(),
    );
  }
}

class DayScreen extends StatefulWidget {
  const DayScreen({super.key});

  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> {
  List<HourSlot> day = sampleDay();

  void openHour(HourSlot slot) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditHourScreen(slot: slot)),
    ).then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final battery = simulate(day);
    final death = deathHour(day);

    return Scaffold(
      appBar: AppBar(title: const Text('Battery Planner')),
      body: Column(
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
                    onTap: () => openHour(slot),
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
                  onTap: () => openHour(slot),
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
      ),
    );
  }
}

class HourSlot {
  HourSlot(this.hour, this.activity);

  final int hour;
  String activity;
  bool charging = false;
}

List<HourSlot> sampleDay() {
  return [
    HourSlot(7, 'video'),
    HourSlot(8, 'video'),
    HourSlot(9, 'chat'),
    HourSlot(10, 'idle'),
    HourSlot(11, 'games'),
    HourSlot(12, 'games'),
    HourSlot(13, 'chat'),
    HourSlot(14, 'idle'),
    HourSlot(15, 'video'),
    HourSlot(16, 'video'),
    HourSlot(17, 'games'),
    HourSlot(18, 'chat'),
    HourSlot(19, 'video'),
    HourSlot(20, 'video'),
    HourSlot(21, 'games'),
    HourSlot(22, 'chat'),
    HourSlot(23, 'idle'),
  ];
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

  @override
  void initState() {
    super.initState();
    activity = widget.slot.activity;
    charging = widget.slot.charging;
  }

  void save() {
    widget.slot.activity = activity;
    widget.slot.charging = charging;
    Navigator.pop(context);
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
                onPressed: save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}