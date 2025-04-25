import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class CrdProvider with ChangeNotifier {
  final Dio? _dio;
  String? _error;
  bool _isLoading = false;
  List<Map<String, dynamic>>? _prelimsTeams;
  List<Map<String, dynamic>>? _finalsTeams;
  int? _selectedEventId;

  CrdProvider(this._dio);

  String? get error => _error;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>>? get prelimsTeams => _prelimsTeams;
  List<Map<String, dynamic>>? get finalsTeams => _finalsTeams;
  int? get selectedEventId => _selectedEventId;

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void setSelectedEventId(int? eventId) {
    _selectedEventId = eventId;
    notifyListeners();
  }

  void _updateTeamInList(List<Map<String, dynamic>>? teams, String tid,
      String field, dynamic value) {
    if (teams != null) {
      final index = teams.indexWhere((team) => team['tid'] == tid);
      if (index != -1) {
        teams[index][field] = value;
        notifyListeners();
      }
    }
  }

  Future<void> fetchPrelimsTeams(int eventId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_dio == null) {
        _setError('Not authenticated');
        return;
      }

      final response = await _dio.get('/crd/events/$eventId/prelims');

      if (response.statusCode == 200) {
        _prelimsTeams = List<Map<String, dynamic>>.from(response.data);
        _error = null;
      } else {
        _prelimsTeams = null;
        _error = 'Failed to fetch prelims teams';
      }
    } catch (e) {
      _prelimsTeams = null;
      _error = 'Error: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFinalsTeams(int eventId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_dio == null) {
        _setError('Not authenticated');
        return;
      }

      final response = await _dio.get('/crd/events/$eventId/finals');

      if (response.statusCode == 200) {
        _finalsTeams = List<Map<String, dynamic>>.from(response.data);
        _error = null;
      } else {
        _finalsTeams = null;
        _error = 'Failed to fetch finals teams';
      }
    } catch (e) {
      _finalsTeams = null;
      _error = 'Error: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleHasPlayed(String tid) async {
    try {
      if (_dio == null) {
        _setError('Not authenticated');
        return false;
      }

      // Check if team is qualified before allowing hasPlayed to be set to false
      final prelimsTeam = _prelimsTeams?.firstWhere(
        (team) => team['tid'] == tid,
        orElse: () => {},
      );
      final finalsTeam = _finalsTeams?.firstWhere(
        (team) => team['tid'] == tid,
        orElse: () => {},
      );

      final isQualified = (prelimsTeam?['qualified'] ?? false) ||
          (finalsTeam?['qualified'] ?? false);
      final currentHasPlayed = (prelimsTeam?['hasPlayed'] ?? false) ||
          (finalsTeam?['hasPlayed'] ?? false);

      // If trying to set hasPlayed to false while team is qualified, return false
      if (currentHasPlayed && isQualified) {
        return false; // Will trigger error snackbar in UI
      }

      final response = await _dio.patch('/teams/$tid/played');

      if (response.statusCode == 200) {
        // Refetch teams to ensure UI is in sync with backend
        if (_selectedEventId != null) {
          await fetchPrelimsTeams(_selectedEventId!);
          await fetchFinalsTeams(_selectedEventId!);
        }
        return true;
      }
      return false;
    } catch (e) {
      _setError('Error toggling has played status: ${e.toString()}');
      return false;
    }
  }

  Future<bool> toggleQualified(String tid) async {
    try {
      if (_dio == null) {
        _setError('Not authenticated');
        return false;
      }

      // Check if team has played before allowing qualification
      final prelimsTeam = _prelimsTeams?.firstWhere(
        (team) => team['tid'] == tid,
        orElse: () => {},
      );
      final finalsTeam = _finalsTeams?.firstWhere(
        (team) => team['tid'] == tid,
        orElse: () => {},
      );

      // Get the current team's hasPlayed status
      final currentTeam =
          prelimsTeam?.isNotEmpty == true ? prelimsTeam : finalsTeam;
      final hasPlayed = currentTeam?['hasPlayed'] ?? false;
      final isCurrentlyQualified = currentTeam?['qualified'] ?? false;

      // Only check hasPlayed when qualifying (not when unqualifying)
      if (!hasPlayed && !isCurrentlyQualified) {
        return false; // Will trigger error snackbar in UI
      }

      // Make the API call to toggle qualified status
      final response = await _dio.patch('/teams/$tid/qualified');

      if (response.statusCode == 200) {
        // If qualifying, set position to NONE
        if (!isCurrentlyQualified) {
          await _dio.patch('/teams/$tid?position=NONE');
        }

        // Refetch teams to ensure UI is in sync with backend
        if (_selectedEventId != null) {
          await fetchPrelimsTeams(_selectedEventId!);
          await fetchFinalsTeams(_selectedEventId!);
        }
        return true;
      } else if (response.statusCode == 500) {
        _setError('Server error occurred while updating qualification status');
        return false;
      } else {
        _setError('Failed to update qualification status');
        return false;
      }
    } catch (e) {
      _setError('Error toggling qualified status: ${e.toString()}');
      return false;
    }
  }

  Future<bool> updatePosition(String tid, String position) async {
    try {
      if (_dio == null) {
        _setError('Not authenticated');
        return false;
      }

      final response = await _dio.patch(
        '/teams/$tid?position=$position',
      );

      if (response.statusCode == 200) {
        // Refetch teams to ensure UI is in sync with backend
        if (_selectedEventId != null) {
          await fetchPrelimsTeams(_selectedEventId!);
          await fetchFinalsTeams(_selectedEventId!);
        }
        return true;
      }
      return false;
    } catch (e) {
      _setError('Error updating position: ${e.toString()}');
      return false;
    }
  }
}
