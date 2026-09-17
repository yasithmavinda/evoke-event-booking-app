import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventBookingsScreen extends StatelessWidget {
  final String eventId;
  final String eventName;

  const EventBookingsScreen({super.key, required this.eventId, required this.eventName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: Text('Bookings: $eventName'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('eventId', isEqualTo: eventId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }
          final bookings = snapshot.data?.docs ?? [];

          if (bookings.isEmpty) {
            return const Center(
              child: Text('No bookings yet for this event.', style: TextStyle(color: Colors.white38)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final data = bookings[index].data() as Map<String, dynamic>;
              // In a real app, you might fetch user names from a 'users' collection
              // but here we show the info saved in the booking document.
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white10,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('User ID: ${data['userId']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Status: ${data['status']}', style: TextStyle(color: data['status'] == 'Active' ? Colors.greenAccent : Colors.grey)),
                        ],
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
