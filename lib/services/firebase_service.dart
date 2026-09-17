import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';

/// Professional Firestore Service to handle all database operations.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _imgbbKey = '89673809366fbcb9f56d0ba7bdd9c179';

  /// Uploads an image to ImgBB and returns the display URL.
  Future<String> uploadImageToImgBB(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbKey'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonResponse['data']['display_url'];
      } else {
        throw Exception('ImgBB Upload Failed: ${jsonResponse['error']['message']}');
      }
    } catch (e) {
      print('❌ ImgBB Error: $e');
      throw Exception('Failed to upload image to ImgBB.');
    }
  }

  /// Uploads a new event with an image hosted on ImgBB.
  Future<void> uploadNewEvent(Map<String, dynamic> eventData, File? imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      String imageUrl = eventData['imageUrl'] ?? '';

      if (imageFile != null) {
        imageUrl = await uploadImageToImgBB(imageFile);
      }

      eventData['imageUrl'] = imageUrl;
      eventData['organizerId'] = user.uid; // Link event to organizer
      eventData['createdAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('events').add(eventData);
    } catch (e) {
      print('❌ Error uploading event: $e');
      throw Exception('Failed to upload event.');
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({'isRead': true});
  }

  /// 4-Type Requirement: Sends an in-app notification
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type, // 1: confirmation, 2: cancellation, 3: update, 4: reminder
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Notification Error: $e');
    }
  }

  /// Requirement 3: Notify all attendees of an Event Update
  Future<void> notifyAttendeesOfUpdate(String eventId, String eventName) async {
    final bookings = await _firestore.collection('bookings')
        .where('eventId', isEqualTo: eventId)
        .where('status', isEqualTo: 'Active')
        .get();

    for (var doc in bookings.docs) {
      await sendNotification(
        userId: doc.data()['userId'],
        title: 'Event Update: $eventName',
        message: 'The details for an event you booked have been updated. Please check the latest info.',
        type: 'event_update',
      );
    }
  }

  /// Requirement 4: Notify all attendees of an Event Reminder
  Future<void> sendManualReminder(String eventId, String eventName) async {
    final bookings = await _firestore.collection('bookings')
        .where('eventId', isEqualTo: eventId)
        .where('status', isEqualTo: 'Active')
        .get();

    for (var doc in bookings.docs) {
      await sendNotification(
        userId: doc.data()['userId'],
        title: 'Reminder: $eventName',
        message: 'Get ready! Your event is happening soon. Don\'t forget to check your ticket.',
        type: 'event_reminder',
      );
    }
  }

  /// Updates an existing event and triggers update notifications
  Future<void> updateEvent(String eventId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('events').doc(eventId).update(data);
      // Trigger Requirement 3
      await notifyAttendeesOfUpdate(eventId, data['name']);
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  /// Deletes an event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  /// Streams events for a specific organizer
  Stream<List<EventModel>> getOrganizerEventsStream(String organizerId) {
    return _firestore
        .collection('events')
        .where('organizerId', isEqualTo: organizerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return EventModel.fromJson({...data, 'id': doc.id});
      }).toList();
    });
  }

  /// Seeds initial events if the collection is empty.
  Future<void> seedInitialEvents() async {
    try {
      final snapshot = await _firestore.collection('events').limit(1).get();
      
      if (snapshot.docs.isEmpty) {
        print('🌱 Seeding initial events...');
        final List<Map<String, dynamic>> initialEvents = [
          {
            'name': 'Colombo Music Festival',
            'category': 'Music',
            'date': DateTime(2026, 5, 20).toIso8601String(),
            'time': '06:00 PM',
            'location': 'Viharamahadevi Park, Colombo',
            'price': 5000.0,
            'availableSeats': 1000,
            'imageUrl': 'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3',
            'description': 'The ultimate music experience in the heart of Colombo.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Galle Art Exhibition',
            'category': 'Art',
            'date': DateTime(2026, 6, 15).toIso8601String(),
            'time': '10:00 AM',
            'location': 'Galle Fort, Galle',
            'price': 1500.0,
            'availableSeats': 300,
            'imageUrl': 'https://images.unsplash.com/photo-1531058020387-3be344556be6',
            'description': 'Exploring contemporary art within the historic Galle Fort.',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'INCO 2026 Smart-Drop Exhibition',
            'category': 'Tech',
            'date': DateTime(2026, 8, 10).toIso8601String(),
            'time': '09:00 AM',
            'location': 'BMICH, Colombo',
            'price': 500.0,
            'availableSeats': 5000,
            'imageUrl': 'https://images.unsplash.com/photo-1540575861501-7ad05823c9f5',
            'description': 'Showcasing the latest industrial and technology innovations.',
            'createdAt': FieldValue.serverTimestamp(),
          }
        ];

        final batch = _firestore.batch();
        for (var event in initialEvents) {
          final docRef = _firestore.collection('events').doc();
          batch.set(docRef, event);
        }
        await batch.commit();
        print('✅ Seeding complete.');
      }
    } catch (e) {
      print('❌ Seeding failed: $e');
    }
  }

  Stream<List<EventModel>> getEventsStream() {
    return _firestore
        .collection('events')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return EventModel.fromJson({...data, 'id': doc.id});
      }).toList();
    });
  }
}
