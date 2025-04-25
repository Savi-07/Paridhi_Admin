import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/combo_event_model.dart';

class ComboEventsProvider with ChangeNotifier {
  List<ComboEvent> _combos = [];
  bool _isLoading = false;
  String? _error;
  final Dio? _dio;

  ComboEventsProvider(this._dio);

  List<ComboEvent> get combos => _combos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCombos() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_dio == null) {
        throw Exception('Not authenticated');
      }

      final response = await _dio.get('/combos');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _combos = data.map((json) => ComboEvent.fromJson(json)).toList();
      } else {
        _error = 'Failed to fetch combos';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCombo(ComboEvent combo) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_dio == null) {
        throw Exception('Not authenticated');
      }

      // First create the combo with registration closed
      final comboToCreate = ComboEvent(
        id: combo.id,
        name: combo.name,
        description: combo.description,
        domain: combo.domain,
        events: combo.events,
        registrationFee: combo.registrationFee,
        createdAt: combo.createdAt,
        updatedAt: combo.updatedAt,
        createdByUsername: combo.createdByUsername,
        registrationOpen: false, // Create with registration closed initially
      );

      final response =
          await _dio.post('/combos', data: comboToCreate.toJson());

      if (response.statusCode == 201) {
        // If the combo was created successfully and registration should be open
        if (combo.registrationOpen) {
          final createdCombo = ComboEvent.fromJson(response.data);
          final statusResponse =
              await _dio.patch('/combos/${createdCombo.id}/status', data: {
            'registrationOpen': true,
          });

          if (statusResponse.statusCode != 200) {
            _error = 'Failed to set registration status';
            return false;
          }
        }

        await fetchCombos();
        return true;
      } else {
        _error = 'Failed to create combo: ${response.data}';
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCombo(ComboEvent combo) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_dio == null) {
        throw Exception('Not authenticated');
      }

      // First update the combo details
      final response =
          await _dio.put('/combos/${combo.id}', data: combo.toJson());

      if (response.statusCode == 200) {
        // Then update the registration status if it has changed
        final currentCombo = _combos.firstWhere((c) => c.id == combo.id);
        if (currentCombo.registrationOpen != combo.registrationOpen) {
          final statusResponse =
              await _dio.patch('/combos/${combo.id}/status', data: {
            'registrationOpen': combo.registrationOpen,
          });

          if (statusResponse.statusCode != 200) {
            _error = 'Failed to update registration status';
            return false;
          }
        }

        await fetchCombos();
        return true;
      } else {
        _error = 'Failed to update combo: ${response.data}';
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCombo(int comboId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_dio == null) {
        throw Exception('Not authenticated');
      }

      final response = await _dio.delete('/combos/$comboId');

      if (response.statusCode == 204) {
        await fetchCombos();
        return true;
      } else {
        _error = 'Failed to delete combo: ${response.data}';
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleRegistrationStatus(int comboId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_dio == null) {
        throw Exception('Not authenticated');
      }

      final response = await _dio.patch('/combos/$comboId/status');

      if (response.statusCode == 200) {
        await fetchCombos();
        return true;
      } else {
        _error = 'Failed to toggle registration status: ${response.data}';
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadComboPicture(int comboId, dynamic imageData) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_dio == null) {
        throw Exception('Not authenticated');
      }

      final uri = Uri.parse('${ApiConstants.baseUrl}/combos/$comboId/upload');
      final request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] =
          'Bearer ${_dio.options.headers['Authorization']}';

      if (imageData is String) {
        request.files.add(await http.MultipartFile.fromPath('file', imageData));
      } else if (imageData is Uint8List) {
        request.files.add(http.MultipartFile.fromBytes('file', imageData));
      } else {
        throw Exception('Invalid image data type');
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        await fetchCombos();
        return true;
      } else {
        _error = 'Failed to upload combo picture: ${response.body}';
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
