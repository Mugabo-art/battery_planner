import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HourSlot {
  HourSlot(this.hour, this.activity, {this.charging = false});

  final int hour;
  String activity;
  bool charging;

  // Only the facts the user chose. The battery is computed, never saved.
  Map<String, dynamic> toMap() => {
    'hour': hour,
    'activity': activity,
    'charging': charging,
  };

  factory HourSlot.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return HourSlot(
      (data['hour'] as num).toInt(),
      data['activity'] as String,
      charging: data['charging'] as bool? ?? false,
    );
  }
}

// The signed-in user's hours: users/{uid}/hours
CollectionReference<Map<String, dynamic>> myHours() {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('hours');
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

// Sample data, written once when a new account is created
Future<void> addSampleHours() async {
  final batch = FirebaseFirestore.instance.batch();
  for (final slot in sampleDay()) {
    batch.set(myHours().doc('${slot.hour}'), slot.toMap());
  }
  await batch.commit();
}