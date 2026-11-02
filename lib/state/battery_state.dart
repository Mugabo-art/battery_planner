import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/hour_slot.dart';
import '../repositories/hour_repository.dart';

class BatteryState extends ChangeNotifier {
  BatteryState(this._repo) {
    // Born: open the pipe to the backend, once.
    _subscription = _repo.watchAll().listen(
          (list) {
        _hours = list;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _loading = false;
        _error = 'Could not load your day.';
        notifyListeners();
      },
    );
  }

  final HourRepository _repo;
  StreamSubscription<List<HourSlot>>? _subscription;

  // The data: private, so only the brain can change it.
  List<HourSlot> _hours = [];
  bool _loading = true;
  String? _error;

  // Read-only views for the screens.
  List<HourSlot> get hours => _hours;
  bool get loading => _loading;
  String? get error => _error;

  // Computed every time it is read, never saved.
  // The battery % after each hour.
  List<int> get battery {
    final results = <int>[];
    int level = 100;
    for (final slot in _hours) {
      level = level - drainOf(slot.activity);
      if (slot.charging) level = level + 20;
      if (level < 0) level = 0;
      if (level > 100) level = 100;
      results.add(level);
    }
    return results;
  }

  // The hour the battery reaches 0, or null if it survives.
  int? get deathHour {
    final levels = battery;
    for (int i = 0; i < levels.length; i++) {
      if (levels[i] == 0) return _hours[i].hour;
    }
    return null;
  }

  // The battery % after a given hour (computed, never saved).
  int levelAt(int hour) {
    final levels = battery;
    final index = _hours.indexWhere((s) => s.hour == hour);
    return index == -1 ? 0 : levels[index];
  }

  // Filter: 'all', 'heavy' (video/games) or 'charging'.
  String _filter = 'all';
  String get filter => _filter;

  void setFilter(String value) {
    _filter = value;
    notifyListeners();
  }

  // The hours to show, computed from the hours and the filter.
  List<HourSlot> get visible {
    if (_filter == 'heavy') {
      return _hours.where((s) => drainOf(s.activity) >= 12).toList();
    }
    if (_filter == 'charging') {
      return _hours.where((s) => s.charging).toList();
    }
    return _hours;
  }

  // Actions: the brain hands the job to the repository.
  Future<void> update(HourSlot slot) => _repo.update(slot);
  Future<void> remove(HourSlot slot) => _repo.delete(slot);
  Future<void> addSamples() => _repo.addSamples();

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}