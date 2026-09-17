class BookingModel {
  final String? id;
  final String eventId;
  final String userId;
  final DateTime bookingDate;
  final double totalAmount;
  final String status; // e.g., 'confirmed', 'pending', 'cancelled'

  BookingModel({
    this.id,
    required this.eventId,
    required this.userId,
    required this.bookingDate,
    required this.totalAmount,
    this.status = 'pending',
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id']?.toString(),
      eventId: json['event_id'].toString(),
      userId: json['user_id'].toString(),
      bookingDate: DateTime.parse(json['booking_date']),
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'event_id': eventId,
      'user_id': userId,
      'booking_date': bookingDate.toIso8601String(),
      'total_amount': totalAmount,
      'status': status,
    };
  }
}
