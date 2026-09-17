import '../models/event_model.dart';

class BookingService {
  static final List<EventModel> _myBookings = [];

  static List<EventModel> get myBookings => List.unmodifiable(_myBookings);

  static void bookEvent(EventModel event) {
    if (!_myBookings.any((e) => e.id == event.id)) {
      _myBookings.add(event);
    }
  }

  static bool isBooked(String eventId) {
    return _myBookings.any((e) => e.id == eventId);
  }
}
