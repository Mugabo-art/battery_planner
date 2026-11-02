import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/hour_slot.dart';
import '../state/battery_state.dart';
import '../widgets/activity_style.dart';

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
    // Step 16: watch the brain. This number updates live,
    // even while this screen is open.
    final level = context.watch<BatteryState>().levelAt(widget.slot.hour);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Edit ${widget.slot.hour}:00',
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          // Live battery card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: levelColor(level).withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.battery_std_rounded, color: levelColor(level)),
                    const SizedBox(width: 8),
                    Text('Battery after ${widget.slot.hour}:00',
                        style: const TextStyle(color: AppColors.muted)),
                    const Spacer(),
                    Text('$level%',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: levelColor(level))),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: level / 100,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    color: levelColor(level),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Live from your plan',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text('What are you doing?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          // Activity grid
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              for (final name in drainPerHour.keys)
                _ActivityTile(
                  name: name,
                  selected: activity == name,
                  onTap: () => setState(() => activity = name),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Charging switch
          Material(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: SwitchListTile(
              secondary: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bolt_rounded, color: AppColors.amber),
              ),
              title: const Text('Charging',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('+20% this hour',
                  style: TextStyle(color: AppColors.muted)),
              value: charging,
              onChanged: (value) => setState(() => charging = value),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            onPressed: saving ? null : save,
            child: Text(saving ? 'Saving…' : 'Save'),
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = activityColor(name);
    return Material(
      color: selected ? color.withValues(alpha: 0.18) : AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(activityIcon(name), color: color, size: 30),
              const SizedBox(height: 6),
              Text(capitalize(name),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('-${drainOf(name)}%/h',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}