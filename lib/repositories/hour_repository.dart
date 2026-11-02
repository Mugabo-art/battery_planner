import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/hour_slot.dart';

class HourRepository {
  HourRepository(this.uid);

  final String uid;

  // users/{uid}/hours: the path your security rules protect.
  CollectionReference<Map<String, dynamic>> get _hours =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('hours');

  // The pipe: the list now, and again after every change.
  Stream<List<HourSlot>> watchAll() => _hours
      .orderBy('hour')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(HourSlot.fromDoc).toList());

  // The hour number is the document id.
  Future<void> update(HourSlot slot) =>
      _hours.doc('${slot.hour}').update(slot.toMap());

  Future<void> delete(HourSlot slot) => _hours.doc('${slot.hour}').delete();

  // Sample data for a brand new account.
  Future<void> addSamples() async {
    final batch = FirebaseFirestore.instance.batch();
    for (final slot in sampleDay()) {
      batch.set(_hours.doc('${slot.hour}'), slot.toMap());
    }
    await batch.commit();
  }
}