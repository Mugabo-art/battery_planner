import 'package:cloud_firestore/cloud_firestore.dart';

class HourSlot {
  HourSlot(this.hour, this.activity, {this.charging = false, this.photoUrl}); // CHANGED

  final int hour;
  String activity;
  bool charging;
  final String? photoUrl; // NEW: a link to the photo, or null: no photo

  Map<String, dynamic> toMap() => {
    'hour': hour,
    'activity': activity,
    'charging': charging,
    'photoUrl': photoUrl, // NEW
  };

  factory HourSlot.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return HourSlot(
      (data['hour'] as num).toInt(),
      data['activity'] as String,
      charging: data['charging'] as bool? ?? false,
      photoUrl: data['photoUrl'] as String?, // NEW
    );
  }
}

// How much battery each activity uses per hour (a fixed rule).
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