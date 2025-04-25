import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../models/event_model.dart';

class EventsProvider with ChangeNotifier {
  final Dio? _dio;
  List<Event> _events = [];
  bool _isLoading = false;
  String? _error;

  EventsProvider(this._dio) {
    fetchEvents();
  }

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchEvents() async {
    if (_dio == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _dio.get('/events');

      if (response.statusCode == 200) {
        final List<dynamic> eventsJson = response.data;
        _events = eventsJson.map((json) => Event.fromJson(json)).toList();
        _error = null;
      } else {
        _error = 'Failed to fetch events';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createEvent(Event event) async {
    if (_dio == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // First create the event with registration closed
      final eventToCreate = Event(
        id: event.id,
        domain: event.domain,
        name: event.name,
        eventType: event.eventType,
        eventDate: event.eventDate,
        description: event.description,
        venue: event.venue,
        coordinatorDetails: event.coordinatorDetails,
        ruleBook: event.ruleBook,
        minPlayers: event.minPlayers,
        maxPlayers: event.maxPlayers,
        registrationFee: event.registrationFee,
        prizePool: event.prizePool,
        registrationOpen: false, // Create with registration closed initially
      );

      final response =
          await _dio.post('/events', data: eventToCreate.toJson());

      if (response.statusCode == 201) {
        // If the event was created successfully and registration should be open
        if (event.registrationOpen) {
          final createdEvent = Event.fromJson(response.data);
          final statusResponse =
              await _dio.patch('/events/${createdEvent.id}/status', data: {
            'registrationOpen': true,
          });

          if (statusResponse.statusCode != 200) {
            _error = 'Failed to set registration status';
            return false;
          }
        }

        await fetchEvents();
        return true;
      } else {
        final errorData = response.data;
        _error = errorData['message'] ?? 'Failed to create event';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateEvent(Event event) async {
    if (_dio == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // First update the event details
      final response =
          await _dio.put('/events/${event.id}', data: event.toJson());

      if (response.statusCode == 200) {
        // Then update the registration status if it has changed
        final currentEvent = _events.firstWhere((e) => e.id == event.id);
        if (currentEvent.registrationOpen != event.registrationOpen) {
          final statusResponse =
              await _dio.patch('/events/${event.id}/status', data: {
            'registrationOpen': event.registrationOpen,
          });

          if (statusResponse.statusCode != 200) {
            _error = 'Failed to update registration status';
            return false;
          }
        }

        await fetchEvents();
        return true;
      } else {
        _error = 'Failed to update event';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteEvent(int eventId) async {
    if (_dio == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _dio.delete('/events/$eventId');

      // Both 200 and 204 are valid success responses for DELETE
      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchEvents();
        return true;
      } else {
        final errorData = response.data;
        _error = errorData['message'] ?? 'Failed to delete event';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Future<bool> uploadEventPicture(int eventId, dynamic imageData) async {
  //   try {
  //     _isLoading = true;
  //     _error = null;
  //     notifyListeners();

  //     if (_dio == null) {
  //       throw Exception('Not authenticated');
  //     }

  //     FormData formData;

  //     formData = FormData.fromMap({
  //         'file': await MultipartFile.fromFile(imageData),
  //       });


  //     // if (imageData is String) {
  //     //   // For mobile, use path
        
  //     // }
  //     //  else if (imageData is Uint8List) {
  //      // // For web, use bytes
  //     //   formData = FormData.fromMap({
  //     //     'file': MultipartFile.fromBytes(
  //     //       imageData,
  //     //       filename: 'event_image.jpg',
  //     //     ),
  //     //   });
  //     // }
  //     //  else {
  //     //   throw Exception('Invalid image data type');
  //     // }

  //     final response = await _dio.put(
  //       '/events/$eventId/upload',
  //       data: formData,
  //     );

  //     if (response.statusCode == 200) {
  //       await fetchEvents();
  //       return true;
  //     } else {
  //       final errorData = response.data;
  //       _error = errorData['message'] ?? 'Failed to upload event picture';
  //       return false;
  //     }
  //   } catch (e) {
  //     _error = 'Error: $e';
  //     return false;
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }

Future<bool> uploadEventPicture(int eventId, String imagePath) async {
  try {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (_dio == null) {
      throw Exception('Not authenticated');
    }
    
    // Get file information
    File file = File(imagePath);
    if (!await file.exists()) {
      _error = 'File does not exist';
      return false;
    }
    
    // Extract filename and determine MIME type
    final fileName = imagePath.split('/').last;
    String mimeType;
    if (fileName.toLowerCase().endsWith('.jpg') || fileName.toLowerCase().endsWith('.jpeg')) {
      mimeType = 'image/jpeg';
    } else if (fileName.toLowerCase().endsWith('.png')) {
      mimeType = 'image/png';
    } else {
      mimeType = 'image/jpeg'; // Default fallback
    }

    // Create form data with proper content type
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        imagePath,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ),
    });

    final response = await _dio.put(
      '/events/$eventId/upload',
      data: formData,
    );

    if (response.statusCode == 200) {
      await fetchEvents();
      return true;
    } else {
      _error = response.data['message'] ?? 'Failed to upload event picture';
      return false;
    }
  } catch (e) {
    _error = 'Upload error: $e';
    return false;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  Future<bool> toggleRegistrationStatus(int eventId) async {
    if (_dio == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final event = _events.firstWhere((e) => e.id == eventId);

      final response = await _dio.patch('/events/$eventId/status', data: {
        'registrationOpen': !event.registrationOpen,
      });

      if (response.statusCode == 200) {
        final updatedEvent = Event.fromJson(response.data);
        final index = _events.indexWhere((e) => e.id == eventId);
        if (index != -1) {
          _events[index] = updatedEvent;
          notifyListeners();
        }
        await fetchEvents();
        return true;
      } else {
        final errorData = response.data;
        _error = errorData['message'] ?? 'Failed to toggle registration status';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
