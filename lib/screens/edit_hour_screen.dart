import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/hour_slot.dart';
import '../state/battery_state.dart';

class EditHourScreen extends StatefulWidget {
  const EditHourScreen({super.key, required this.slot});

  final HourSlot slot;

  @override
  State<EditHourScreen> createState() => _EditHourScreenState();
}

class _EditHourScreenState extends State<EditHourScreen> {
  // Ephemeral state: only this screen cares, so setState is right.
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
    final state = context.read<BatteryState>(); // read BEFORE the await
    setState(() => saving = true);
    try {
      await state.update(
        HourSlot(widget.slot.hour, activity, charging: charging),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save. Try again.')),
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