import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';

/// Custom Exception class for API related errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// A robust, architectural-grade Service class to handle all API communications.
class ApiService {
  static const String _baseUrl = 'https://api.eventhub-mock.com/v1'; // Placeholder URL
  
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Generic helper for handling HTTP responses and errors centrally.
  dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return json.decode(response.body);
      case 400:
        throw ApiException('Invalid request parameters.', 400);
      case 401:
        throw ApiException('Unauthorized access. Please login again.', 401);
      case 403:
        throw ApiException('You do not have permission to perform this action.', 403);
      case 404:
        throw ApiException('Requested resource not found.', 404);
      case 500:
        throw ApiException('Server error. Please try again later.', 500);
      default:
        throw ApiException('Unexpected error occurred.', response.statusCode);
    }
  }

  /// Centralized Error Handling Wrapper
  Future<T> _processRequest<T>(Future<http.Response> Function() request, T Function(dynamic json) mapper) async {
    try {
      // Simulate network latency for a realistic mobile experience
      await Future.delayed(const Duration(milliseconds: 800));
      
      final response = await request().timeout(const Duration(seconds: 10));
      final decodedJson = _handleResponse(response);
      return mapper(decodedJson);
    } on SocketException {
      throw ApiException('No Internet connection. Please check your network.');
    } on http.ClientException {
      throw ApiException('Client error occurred while connecting to the server.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('An unknown error occurred: ${e.toString()}');
    }
  }

  /// GET: Fetch all events
  Future<List<EventModel>> fetchEvents() async {
    return _processRequest(
      () => _client.get(Uri.parse('$_baseUrl/events')),
      (json) => (json['data'] as List).map((e) => EventModel.fromJson(e)).toList(),
    ).catchError((_) => mockEvents); // Fallback to mock data for demonstration
  }

  /// POST: Create a booking
  Future<bool> createBooking(String eventId, String userId) async {
    return _processRequest(
      () => _client.post(
        Uri.parse('$_baseUrl/bookings'),
        body: json.encode({'event_id': eventId, 'user_id': userId}),
        headers: {'Content-Type': 'application/json'},
      ),
      (json) => json['success'] as bool,
    );
  }

  /// POST: Add a new event
  Future<EventModel> addEvent(Map<String, dynamic> eventData) async {
    return _processRequest(
      () => _client.post(
        Uri.parse('$_baseUrl/events'),
        body: json.encode(eventData),
        headers: {'Content-Type': 'application/json'},
      ),
      (json) => EventModel.fromJson(json['data']),
    );
  }
}
