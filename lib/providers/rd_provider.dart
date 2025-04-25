import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class RdProvider with ChangeNotifier {
  final Dio? _dio;
  String? _error;
  bool _isLoading = false;
  Map<String, dynamic>? _currentTeam;
  List<Map<String, dynamic>>? _teamsByEvent;

  RdProvider(this._dio);

  String? get error => _error;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get currentTeam => _currentTeam;
  List<Map<String, dynamic>>? get teamsByEvent => _teamsByEvent;

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void _updateCurrentTeam(Map<String, dynamic> team) {
    // Convert 'paid' to 'hasPaid' for consistency in the UI
    _currentTeam = {
      ...team,
      'hasPaid': team['paid'] ?? false,
    };
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getTeamByTid(String tid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_dio == null) {
        _setError('Not authenticated');
        return null;
      }

      final response = await _dio.get('/teams/tid/$tid');

      if (response.statusCode == 200) {
        _updateCurrentTeam(response.data);
        _error = null;
      } else if (response.statusCode == 404) {
        _currentTeam = null;
        _error = 'Team not found';
      } else {
        _currentTeam = null;
        _error = 'Failed to fetch team details';
      }
    } catch (e) {
      _currentTeam = null;
      _error = 'Error: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _currentTeam;
  }

  Future<bool> togglePaymentStatus(String tid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_dio == null) {
        _setError('Not authenticated');
        return false;
      }

      final response = await _dio.patch('/teams/$tid/payment');

      if (response.statusCode == 200) {
        _updateCurrentTeam(response.data);
        return true;
      } else {
        _error = 'Failed to update payment status';
        return false;
      }
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getTeamsByEvent(int eventId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_dio == null) {
        _setError('Not authenticated');
        return [];
      }

      print('Fetching teams for event ID: $eventId');
      final response = await _dio.get('/teams/events/$eventId');
      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        _teamsByEvent = List<Map<String, dynamic>>.from(response.data);
        _error = null;
        print('Successfully fetched ${_teamsByEvent?.length} teams');
        return _teamsByEvent!;
      } else {
        _teamsByEvent = null;
        _error = 'Failed to fetch teams by event';
        print('Failed to fetch teams. Status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      _teamsByEvent = null;
      _error = 'Error: ${e.toString()}';
      print('Error fetching teams: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
