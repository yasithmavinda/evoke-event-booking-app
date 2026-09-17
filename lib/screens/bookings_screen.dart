import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_widgets.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  /// Handles the cancellation logic in Firestore
  Future<void> _cancelBooking(BuildContext context, String bookingId, String eventId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // Using a batch write for atomic updates
      WriteBatch batch = firestore.batch();

      // 1. Update Booking Status
      DocumentReference bookingRef = firestore.collection('bookings').doc(bookingId);
      batch.update(bookingRef, {'status': 'Cancelled'});

      // 2. Increment Available Seats in Events collection
      DocumentReference eventRef = firestore.collection('events').doc(eventId);
      batch.update(eventRef, {'availableSeats': FieldValue.increment(1)});

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking Cancelled successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ErrorSnackbar.show(context, 'Failed to cancel: $e');
      }
    }
  }

  void _showCancelDialog(BuildContext context, String bookingId, String eventId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel this booking? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep it', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              _cancelBooking(context, bookingId, eventId);
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: currentUserId)
            .orderBy('eventDate', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF9030)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 80, color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  const Text('No bookings yet', style: TextStyle(color: Colors.white38, fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String bookingId = doc.id;
              final String status = data['status'] ?? 'Active';
              final bool isActive = status == 'Active';

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              data['imageUrl'],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(width: 80, height: 80, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['eventName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMM dd, yyyy').format(DateTime.parse(data['eventDate'])),
                                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                _StatusBadge(status: status),
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
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent, width: 1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _showCancelDialog(context, bookingId, data['eventId']),
                            child: const Text('Cancel Booking', style: TextStyle(color: Colors.redAccent)),
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

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    bool isActive = status == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.greenAccent.withOpacity(0.1) : Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isActive ? Colors.greenAccent : Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
