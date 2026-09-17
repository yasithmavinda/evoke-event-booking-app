import 'package:intl/intl.dart';

class EventModel {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final DateTime date;
  final String time;
  final String location;
  final String category;
  final double price;
  final int availableSeats;

  EventModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.category,
    required this.price,
    required this.availableSeats,
  });

  /// Formats price to Sri Lankan Rupee format (e.g., Rs. 2,500.00)
  String get formattedPrice {
    final format = NumberFormat.currency(
      locale: 'en_LK',
      symbol: 'Rs. ',
      decimalDigits: 2,
    );
    return format.format(price);
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'].toString(),
      name: json['name'],
      imageUrl: json['imageUrl'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      time: json['time'],
      location: json['location'],
      category: json['category'],
      price: (json['price'] as num).toDouble(),
      availableSeats: json['availableSeats'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'date': date.toIso8601String(),
      'time': time,
      'location': location,
      'category': category,
      'price': price,
      'availableSeats': availableSeats,
    };
  }
}

// Keeping the mock data with the new model name for backward compatibility during development
final List<EventModel> mockEvents = [
  EventModel(
    id: '1',
    name: 'Colombo Music Festival',
    imageUrl: 'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?q=80&w=1000&auto=format&fit=crop',
    description: 'The biggest electronic music festival in Colombo featuring top local and international DJs.',
    date: DateTime(2024, 12, 15),
    time: '18:00',
    location: 'Viharamahadevi Open Air Theatre, Colombo',
    category: 'Music',
    price: 5000.0,
    availableSeats: 500,
  ),
  EventModel(
    id: '2',
    name: 'Galle Art Exhibition',
    imageUrl: 'https://images.unsplash.com/photo-1531058020387-3be344556be6?q=80&w=1000&auto=format&fit=crop',
    description: 'Explore contemporary Sri Lankan art pieces in the heart of Galle Fort.',
    date: DateTime(2024, 11, 20),
    time: '10:00',
    location: 'Galle Fort Heritage Site',
    category: 'Art',
    price: 1500.0,
    availableSeats: 200,
  ),
  EventModel(
    id: '3',
    name: 'SLIIT Tech Summit',
    imageUrl: 'https://images.unsplash.com/photo-1540575861501-7ad05823c9f5?q=80&w=1000&auto=format&fit=crop',
    description: 'The premier technology and innovation conference in Sri Lanka.',
    date: DateTime(2024, 10, 05),
    time: '09:00',
    location: 'BMICH, Colombo',
    category: 'Tech',
    price: 2500.0,
    availableSeats: 1000,
  ),
  EventModel(
    id: '4',
    name: 'Kandy Street Food Fest',
    imageUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=1000&auto=format&fit=crop',
    description: 'Experience authentic Sri Lankan street food flavors in Kandy.',
    date: DateTime(2024, 09, 12),
    time: '16:00',
    location: 'Kandy City Center Area',
    category: 'Food',
    price: 1000.0,
    availableSeats: 2000,
  ),
];
