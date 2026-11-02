import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/hour_slot.dart';
import '../state/battery_state.dart';
import '../widgets/activity_style.dart';
import 'edit_hour_screen.dart';

class DayScreen extends StatelessWidget {
  const DayScreen({super.key});

  // EXPERIMENT D: the brain is NOT handed over.
  void _openHour(BuildContext context, HourSlot slot) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditHourScreen(slot: slot),
      ),
    );
  }

  Future<void> _delete(BuildContext context, HourSlot slot) async {
    final state = context.read<BatteryState>(); // read BEFORE the await
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete this hour?'),
        content: Text('${slot.hour}:00 · ${capitalize(slot.activity)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
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
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Battery Planner',
                style: TextStyle(fontWeight: FontWeight.w800)),
            Text(email,
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log out',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _body(context, state),
    );
  }

  Widget _body(BuildContext context, BatteryState state) {
    // Error state
    if (state.error != null) {
      return _Message(
        icon: Icons.cloud_off_rounded,
        color: AppColors.red,
        text: state.error!,
      );
    }

    // Loading state
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Empty state
    if (state.hours.isEmpty) {
      return _Message(
        icon: Icons.battery_unknown_rounded,
        color: AppColors.muted,
        text: 'Your day is empty.',
        action: FilledButton.icon(
          onPressed: () => context.read<BatteryState>().addSamples(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add a sample day'),
        ),
      );
    }

    final visible = state.visible;
    final death = state.deathHour;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _HeroCard(state: state),
        const SizedBox(height: 20),

        // Filter chips: watch to show, read to change
        Row(
          children: [
            for (final f in const [
              ('all', 'All'),
              ('heavy', 'Heavy use'),
              ('charging', 'Charging'),
            ])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f.$2),
                  selected: state.filter == f.$1,
                  showCheckmark: false,
                  selectedColor: AppColors.green.withValues(alpha: 0.2),
                  side: BorderSide(
                    color: state.filter == f.$1
                        ? AppColors.green
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                  onSelected: (_) =>
                      context.read<BatteryState>().setFilter(f.$1),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('Nothing matches this filter.',
                  style: TextStyle(color: AppColors.muted)),
            ),
          ),

        for (final slot in visible)
          _HourTile(
            slot: slot,
            level: state.levelAt(slot.hour),
            dead: death != null && slot.hour > death,
            onTap: () => _openHour(context, slot),
            onLongPress: () => _delete(context, slot),
          ),
      ],
    );
  }
}

// The big card at the top: gauge + verdict + stats.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.state});

  final BatteryState state;

  @override
  Widget build(BuildContext context) {
    final levels = state.battery;
    final death = state.deathHour;
    final end = levels.last;
    final lowest = levels.reduce((a, b) => a < b ? a : b);
    final charges = state.hours.where((s) => s.charging).length;
    final dies = death != null;
    final accent = dies ? AppColors.red : AppColors.green;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.25), AppColors.card],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Battery gauge
              SizedBox(
                width: 104,
                height: 104,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: end / 100,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      color: levelColor(end),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$end%',
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w800)),
                          Text('at ${state.hours.last.hour}:00',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      dies
                          ? Icons.battery_alert_rounded
                          : Icons.battery_full_rounded,
                      color: accent,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dies ? 'Dies at $death:00' : 'Survives the day',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dies
                          ? 'Add a charge before $death:00 to make it.'
                          : 'You end the day with $end% left.',
                      style:
                      const TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _Stat(label: 'Lowest', value: '$lowest%'),
              const SizedBox(width: 10),
              _Stat(label: 'Charges', value: '$charges'),
              const SizedBox(width: 10),
              _Stat(label: 'Hours', value: '${state.hours.length}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value,
                style:
                const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

// One hour in the timeline.
class _HourTile extends StatelessWidget {
  const _HourTile({
    required this.slot,
    required this.level,
    required this.dead,
    required this.onTap,
    required this.onLongPress,
  });

  final HourSlot slot;
  final int level;
  final bool dead;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final color = activityColor(slot.activity);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: dead ? 0.45 : 1,
        child: Material(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text('${slot.hour}:00',
                        style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600)),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(activityIcon(slot.activity), color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(capitalize(slot.activity),
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 6),
                            Text('-${drainOf(slot.activity)}%',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.muted)),
                            if (slot.charging) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.bolt_rounded,
                                        size: 14, color: AppColors.amber),
                                    Text('+20%',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.amber,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (dead)
                          const Text('☠ Phone is dead',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.red))
                        else
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: level / 100,
                              minHeight: 6,
                              backgroundColor:
                              Colors.white.withValues(alpha: 0.08),
                              color: levelColor(level),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    dead ? '—' : '$level%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: dead ? AppColors.muted : levelColor(level),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Error and empty states.
class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.color,
    required this.text,
    this.action,
  });

  final IconData icon;
  final Color color;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18)),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}