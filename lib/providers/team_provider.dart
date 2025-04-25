import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/team_member.dart';

class TeamProvider with ChangeNotifier {
  final Dio? _dio;
  List<TeamMember> _teamMembers = [];
  bool _isLoading = false;
  String _error = '';
  DateTime? _lastFetchTime;

  TeamProvider(this._dio);

  // Sort team members alphabetically by name
  List<TeamMember> get teamMembers => List.from(_teamMembers)
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchTeamMembers({
    bool refresh = false,
  }) async {
    if (_dio == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    // If not refreshing and we have recent data, don't fetch again
    if (!refresh &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inMinutes < 1) {
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // print('Fetching team members from /megatronix-team/');

      final response = await _dio!.get(
        '/megatronix-team',
      );

      // print('Response status: ${response.statusCode}');
      // print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        final teamResponse = TeamResponse.fromJson(response.data);
        // print(
        //     'Successfully parsed ${teamResponse.content.length} team members');
        _teamMembers = teamResponse.content;
        _lastFetchTime = DateTime.now();
      } else {
        _error = 'Failed to load team members. Status: ${response.statusCode}';
        // print('Error: $_error');
      }

      // Log the number of members fetched
      // print('Total team members after fetch: ${_teamMembers.length}');
    } catch (e, stackTrace) {
      _error = 'Error fetching team members: $e';
      // print('Error: $_error');
      // print('Stack trace: $stackTrace');
      // Reset the list on error
      _teamMembers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addTeamMember({
    required String name,
    required String email,
    required String year,
    required Designation designation,
    String linkedInLink = '',
    String facebookLink = '',
    String instagramLink = '',
    String githubLink = '',
    String imageLink = '',
  }) async {
    if (_dio == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Validate required fields
      if (name.isEmpty || email.isEmpty || year.isEmpty) {
        _error = 'Name, email, and year are required fields';
        return false;
      }

      // Check if email already exists
      if (_teamMembers
          .any((member) => member.email.toLowerCase() == email.toLowerCase())) {
        _error = 'A team member with this email already exists';
        return false;
      }

      // print('Adding new team member with data:');
      final requestData = {
        'name': name,
        'email': email,
        'year': year,
        'designation': designation == Designation.BACKEND_DEVELOPER_AND_APP_DEVELOPER 
            ? 'Backend Dev & App Dev' 
            : designation.toString().split('.').last,
        'linkedInLink': linkedInLink,
        'facebookLink': facebookLink,
        'instagramLink': instagramLink,
        'githubLink': githubLink,
        'imageLink': imageLink,
      };
      // print('Request data: $requestData');

      final response = await _dio!.post(
        '/megatronix-team',
        data: requestData,
      );

      // print('Response status: ${response.statusCode}');
      // print('Response data: ${response.data}');

      if (response.statusCode == 201) {
        // Create a new TeamMember object from the response
        final newMember = TeamMember.fromJson(response.data);
        // Add the new member to the list
        _teamMembers.add(newMember);
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to add team member. Status: ${response.statusCode}';
        return false;
      }
    } catch (e, stackTrace) {
      _error = 'Error adding team member: $e';
      // print('Error stack trace: $stackTrace');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTeamMember({
    required int id,
    required String name,
    required String email,
    required String year,
    required Designation designation,
    String linkedInLink = '',
    String facebookLink = '',
    String instagramLink = '',
    String githubLink = '',
    String imageLink = '',
  }) async {
    if (_dio == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    if (id <= 0) {
      _error = 'Invalid team member ID';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Validate required fields
      if (name.isEmpty || email.isEmpty || year.isEmpty) {
        _error = 'Name, email, and year are required fields';
        return false;
      }

      // Check if email already exists for another member
      if (_teamMembers.any((member) =>
          member.id != id &&
          member.email.toLowerCase() == email.toLowerCase())) {
        _error = 'A team member with this email already exists';
        return false;
      }

      // print('Updating team member with ID: $id');
      final requestData = {
        'name': name,
        'email': email,
        'year': year,
        'designation': designation == Designation.BACKEND_DEVELOPER_AND_APP_DEVELOPER 
            ? 'Backend Dev & App Dev' 
            : designation.toString().split('.').last,
        'linkedInLink': linkedInLink,
        'facebookLink': facebookLink,
        'instagramLink': instagramLink,
        'githubLink': githubLink,
        'imageLink': imageLink,
      };
      // print('Request data: $requestData');

      final response = await _dio!.put(
        '/megatronix-team/$id',
        data: requestData,
      );

      // print('Response status: ${response.statusCode}');
      // print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        // Parse the updated member from the response
        final updatedMember = TeamMember.fromJson(response.data);

        // Update the member in the local list
        final index = _teamMembers.indexWhere((member) => member.id == id);
        if (index != -1) {
          _teamMembers[index] = updatedMember;
          notifyListeners();
        }

        return true;
      } else {
        // _error = 'Failed to update team member. Status: ${response.statusCode}';
        _error = 'You dont have access to edit or add team members. Contact SuperAdmin';
        // print('Error: $_error',);
        return false;
      }
    } catch (e, stackTrace) {
      _error = 'Error updating team member: $e';
      print('Error stack trace: $stackTrace');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTeamMember(int id) async {
    if (_dio == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _dio!.delete('/megatronix-team/$id');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Remove the deleted member from the list and refresh
        await fetchTeamMembers(refresh: true);
        return true;
      } 

      if (response.statusCode == 403) {
        _error = 'You dont have access to delete team members. Contact SuperAdmin';
        return false;
      } 

      
      
      
      else {
        _error = 'Failed to delete team member. Status: ${response.statusCode}';
        return false;
      }
    } catch (e) {
      _error = 'Error deleting team member: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void refreshTeamMembers() {
    fetchTeamMembers(refresh: true);
  }
}
