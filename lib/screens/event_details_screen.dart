import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../services/booking_service.dart';
import '../widgets/custom_widgets.dart';

class EventDetailsScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailsScreen({super.key, required this.event});

  void _showBookingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text('Confirm Booking', style: Theme.of(context).textTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Event: ${event.name}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('Price: ${event.formattedPrice}',
                 style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Do you want to proceed with the booking?', style: TextStyle(color: Colors.white60)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) throw 'User not logged in';

                // Create booking in Firestore
                await FirebaseFirestore.instance.collection('bookings').add({
                  'userId': user.uid,
                  'eventId': event.id,
                  'eventName': event.name,
                  'eventDate': event.date.toIso8601String(),
                  'imageUrl': event.imageUrl,
                  'status': 'Active',
                  'timestamp': FieldValue.serverTimestamp(),
                });

                // Decrement Available Seats
                await FirebaseFirestore.instance.collection('events').doc(event.id).update({
                  'availableSeats': FieldValue.increment(-1),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  _showSuccessSnackbar(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ErrorSnackbar.show(context, 'Booking failed: $e');
                }
              }
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.black),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Booking Successful! View in My Bookings.',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-bleed Image with Hero
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Hero(
              tag: 'event-image-${event.id}',
              child: Image.network(
                event.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Gradient Overlay for readability of back button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
            ),
          ),

          // Content Container
          Positioned.fill(
            top: MediaQuery.of(context).size.height * 0.4,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              decoration: const BoxDecoration(
                color: Color(0xFF111827),
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            event.category,
                            style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text('4.8', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(event.name, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28)),
                    const SizedBox(height: 20),
                    
                    // Info Row
                    Row(
                      children: [
                        _buildInfoIcon(Icons.calendar_month_rounded, DateFormat('MMM dd, yyyy').format(event.date)),
                        const SizedBox(width: 20),
                        _buildInfoIcon(Icons.access_time_filled_rounded, event.time),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoIcon(Icons.location_on_rounded, event.location),
                    
                    const SizedBox(height: 30),
                    Text('About Event', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Text(
                      event.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                    ),
                    const SizedBox(height: 100), // Space for Book Now button
                  ],
                ),
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              style: IconButton.styleFrom(backgroundColor: Colors.black26),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Bottom Bar with Book Now Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0xFF111827).withOpacity(0), const Color(0xFF111827)],
                ),
              ),
              child: PrimaryButton(
                text: 'Book Now • ${event.formattedPrice}',
                onPressed: () => _showBookingDialog(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoIcon(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white70, size: 18),
        ),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
