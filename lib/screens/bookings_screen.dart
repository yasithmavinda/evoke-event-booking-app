import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../widgets/custom_widgets.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  Future<void> _cancelBooking(BuildContext context, String bookingId, String eventId, String eventName) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;
    
    try {
      WriteBatch batch = firestore.batch();
      
      // 1. Update Booking Status
      batch.update(firestore.collection('bookings').doc(bookingId), {'status': 'Cancelled'});
      
      // 2. Increment Available Seats
      batch.update(firestore.collection('events').doc(eventId), {'availableSeats': FieldValue.increment(1)});
      
      await batch.commit();

      // 3. Trigger Requirement 2: Booking Cancellation Notification
      if (user != null) {
        await FirestoreService().sendNotification(
          userId: user.uid,
          title: 'Booking Cancelled',
          message: 'Your booking for "$eventName" has been cancelled successfully.',
          type: 'booking_cancel',
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking Cancelled'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) ErrorSnackbar.show(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: currentUserId)
            .orderBy('eventDate', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No bookings yet', style: TextStyle(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'Active';
              final isActive = status == 'Active';

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(data['imageUrl'], width: 80, height: 80, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['eventName'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                                const SizedBox(height: 4),
                                Text(DateFormat('MMM dd, yyyy').format(DateTime.parse(data['eventDate'])), style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.greenAccent.withOpacity(0.1) : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(status, style: TextStyle(color: isActive ? Colors.green[700] : Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w800)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isActive)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => _cancelBooking(context, docs[index].id, data['eventId'], data['eventName']),
                            style: TextButton.styleFrom(foregroundColor: Colors.redAccent, textStyle: const TextStyle(fontWeight: FontWeight.bold)),
                            child: const Text('CANCEL BOOKING'),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
