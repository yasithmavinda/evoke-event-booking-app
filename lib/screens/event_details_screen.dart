import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../services/firebase_service.dart';
import '../widgets/custom_widgets.dart';

class EventDetailsScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailsScreen({super.key, required this.event});

  void _showBookingDialog(BuildContext context) {
    const Color primaryAccent = Color(0xFFD73B22);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: const Text('Confirm Booking', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Event: ${event.name}', style: TextStyle(color: Colors.grey[800])),
            const SizedBox(height: 12),
            Text(
              'Total: ${event.formattedPrice}',
              style: const TextStyle(color: primaryAccent, fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) throw 'User not logged in';

                // 1. Create booking in Firestore
                await FirebaseFirestore.instance.collection('bookings').add({
                  'userId': user.uid,
                  'eventId': event.id,
                  'eventName': event.name,
                  'eventDate': event.date.toIso8601String(),
                  'imageUrl': event.imageUrl,
                  'status': 'Active',
                  'timestamp': FieldValue.serverTimestamp(),
                });

                // 2. Trigger Requirement 1: Booking Confirmation Notification
                await FirestoreService().sendNotification(
                  userId: user.uid,
                  title: 'Booking Confirmed!',
                  message: 'You have successfully booked ${event.name}.',
                  type: 'booking_confirm',
                );

                // 3. Decrement Available Seats
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
            child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
              SizedBox(width: 16),
              Text('Successfully Booked!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryAccent = Color(0xFFD73B22);
    final bool isSoldOut = event.availableSeats <= 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Header Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Hero(
              tag: 'event-image-${event.id}',
              child: Image.network(event.imageUrl, fit: BoxFit.cover),
            ),
          ),
          
          // Back Button
          Positioned(
            top: 60,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              ),
            ),
          ),

          // Content Sheet
          Positioned.fill(
            top: MediaQuery.of(context).size.height * 0.42,
            child: Container(
              padding: const EdgeInsets.fromLTRB(30, 40, 30, 0),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F7),
                borderRadius: BorderRadius.vertical(top: Radius.circular(48)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.category.toUpperCase(),
                      style: const TextStyle(color: primaryAccent, fontWeight: FontWeight.w800, letterSpacing: 2),
                    ),
                    const SizedBox(height: 12),
                    Text(event.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.1)),
                    const SizedBox(height: 25),
                    
                    _buildInfoRow(Icons.calendar_month_rounded, DateFormat('EEEE, dd MMMM').format(event.date)),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.location_on_rounded, event.location),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.event_seat_outlined, 
                      event.availableSeats > 0 ? '${event.availableSeats} Seats Available' : 'Sold Out',
                      isWarning: isSoldOut,
                    ),
                    
                    const SizedBox(height: 40),
                    const Text('About', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Text(
                      event.description,
                      style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.6),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),

          // Bottom CTA
          Positioned(
            bottom: 40,
            left: 30,
            right: 30,
            child: Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(35),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Price', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      Text(event.formattedPrice, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: isSoldOut ? null : () => _showBookingDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSoldOut ? Colors.grey[800] : primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: Text(isSoldOut ? 'SOLD OUT' : 'Book Now', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isWarning = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xFFD73B22), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text, 
            style: TextStyle(
              fontWeight: FontWeight.w600, 
              fontSize: 15,
              color: isWarning ? const Color(0xFFD73B22) : Colors.black,
            )
          )
        ),
      ],
    );
  }
}
