import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../services/firebase_service.dart';
import '../widgets/custom_widgets.dart';
import 'add_event_screen.dart';
import 'event_bookings_screen.dart';

class OrganizerDashboardScreen extends StatelessWidget {
  const OrganizerDashboardScreen({super.key});

  void _deleteEvent(BuildContext context, String eventId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text('Delete Event?'),
        content: const Text('Are you sure? All bookings for this event will be orphaned.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirestoreService().deleteEvent(eventId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event deleted successfully')));
                }
              } catch (e) {
                if (context.mounted) ErrorSnackbar.show(context, e.toString());
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: const Text('Organizer Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: firestoreService.getOrganizerEventsStream(user?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }
          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return const Center(
              child: Text('You haven\'t created any events yet.', style: TextStyle(color: Colors.white38)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(event.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                      ),
                      title: Text(event.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(DateFormat('MMM dd, yyyy').format(event.date), style: const TextStyle(color: Colors.white60)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => AddEventScreen(editEvent: event)),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            onPressed: () => _deleteEvent(context, event.id),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Seats: ${event.availableSeats}', style: const TextStyle(color: Color(0xFFFF9030))),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EventBookingsScreen(eventId: event.id, eventName: event.name)),
                            ),
                            icon: const Icon(Icons.people_outline_rounded, size: 18),
                            label: const Text('View Bookings'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF9030),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
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
