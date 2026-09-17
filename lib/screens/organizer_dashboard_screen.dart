import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Event?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to remove this event?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.grey[600]))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirestoreService().deleteEvent(eventId);
              } catch (e) {
                if (context.mounted) ErrorSnackbar.show(context, e.toString());
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _sendReminder(BuildContext context, String eventId, String eventName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Send Reminder?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Send a reminder notification to all attendees of "$eventName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.grey[600]))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD73B22), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirestoreService().sendManualReminder(eventId, eventName);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminders sent to attendees!'), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (context.mounted) ErrorSnackbar.show(context, e.toString());
              }
            },
            child: const Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    const Color primaryAccent = Color(0xFFD73B22);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: StreamBuilder<List<EventModel>>(
        stream: FirestoreService().getOrganizerEventsStream(user?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return Center(child: Text('No events created yet.', style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(event.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                      ),
                      title: Text(event.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      subtitle: Text(DateFormat('MMM dd').format(event.date), style: TextStyle(color: Colors.grey[500])),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.alarm_rounded, color: Colors.orangeAccent),
                            onPressed: () => _sendReminder(context, event.id, event.name),
                            tooltip: 'Send Reminder',
                          ),
                          IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEventScreen(editEvent: event)))),
                          IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent), onPressed: () => _deleteEvent(context, event.id)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${event.availableSeats} seats left', style: const TextStyle(color: primaryAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                          ElevatedButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventBookingsScreen(eventId: event.id, eventName: event.name))),
                            style: ElevatedButton.styleFrom(backgroundColor: primaryAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 16)),
                            child: const Text('BOOKINGS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
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
