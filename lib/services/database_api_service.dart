import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';
import '../models/booking_model.dart';

/// Industrial-grade exception for API errors
class DatabaseApiException implements Exception {
  final String message;
  final int? statusCode;
  DatabaseApiException(this.message, [this.statusCode]);
  @override
  String toString() => 'DatabaseApiException: $message (Status: $statusCode)';
}

/// Senior-level API Service for robust backend integration.
class DatabaseApiService {
  // Base URL for Android Emulator to local machine
  static const String _baseUrl = 'http://10.0.2.2:3000/api'; 
  
  final http.Client _client;
  DatabaseApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Centralized response handler with status code validation
  dynamic _processResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return json.decode(response.body);
      case 400:
        throw DatabaseApiException('Bad Request: The server could not understand the request.', 400);
      case 401:
        throw DatabaseApiException('Unauthorized: Authentication is required.', 401);
      case 500:
        throw DatabaseApiException('Internal Server Error: Something went wrong on the server.', 500);
      default:
        throw DatabaseApiException('Error: Unexpected status code.', response.statusCode);
    }
  }

  /// Global request wrapper for error handling and timeouts
  Future<T> _safeRequest<T>(Future<http.Response> Function() request, T Function(dynamic json) mapper) async {
    try {
      final response = await request().timeout(const Duration(seconds: 15));
      final data = _processResponse(response);
      return mapper(data);
    } on SocketException {
      throw DatabaseApiException('Network Error: Please check your internet connection.');
    } on http.ClientException {
      throw DatabaseApiException('Connection Error: Failed to connect to the database server.');
    } on DatabaseApiException {
      rethrow;
    } catch (e) {
      throw DatabaseApiException('Unexpected Error: ${e.toString()}');
    }
  }

  /// GET: Fetch all available events
  Future<List<EventModel>> fetchAvailableEvents() async {
    return _safeRequest(
      () => _client.get(Uri.parse('$_baseUrl/events')),
      (json) => (json as List).map((e) => EventModel.fromJson(e)).toList(),
    );
  }

  /// GET: Fetch specific event details by ID
  Future<EventModel> fetchEventDetails(String id) async {
    return _safeRequest(
      () => _client.get(Uri.parse('$_baseUrl/events/$id')),
      (json) => EventModel.fromJson(json),
    );
  }

  /// POST: Create a new booking
  Future<BookingModel> createBooking(BookingModel booking) async {
    return _safeRequest(
      () => _client.post(
        Uri.parse('$_baseUrl/bookings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(booking.toJson()),
      ),
      (json) => BookingModel.fromJson(json),
    );
  }

  /// POST: Publish a new event
  Future<EventModel> publishNewEvent(EventModel event) async {
    return _safeRequest(
      () => _client.post(
        Uri.parse('$_baseUrl/events'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(event.toJson()),
      ),
      (json) => EventModel.fromJson(json),
    );
  }
}
