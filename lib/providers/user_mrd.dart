import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import 'auth_provider.dart';

class UserMrd with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _registrationResponse;
  final AuthProvider _authProvider;

  UserMrd(this._authProvider);

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get registrationResponse => _registrationResponse;

  Future<Map<String, dynamic>?> register(String email, String contact, String college, String year, String department, String rollNo) async {
    try {
      _isLoading = true;
      _error = null;
      _registrationResponse = null;
      notifyListeners();

      final token = _authProvider.token;
      if (token == null) {
        _error = 'Authentication required. Please login first.';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/profiles'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'email': email,
          'contact': contact,
          'college': college, 
          'year': year,
          'department': department,
          'rollNo': rollNo,
        }),
      );

      if (response.statusCode == 201) {
        _registrationResponse = json.decode(response.body);
        
        // After successful profile creation, get the GID
        final gidResponse = await getMrdGid(email);
        if (gidResponse != null) {
          _registrationResponse = gidResponse;
        }
        
        _isLoading = false;
        notifyListeners();
        return _registrationResponse;
      } else {
        _error = 'User Registration failed: ${response.body}';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> getMrdGid(String email) async {
    try {
      final token = _authProvider.token;
      if (token == null) {
        _error = 'Authentication required. Please login first.';
        return null;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/mrd/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'email': email,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        _error = 'Failed to get MRD GID: ${response.body}';
        return null;
      }
    } catch (e) {
      _error = 'Error getting MRD GID: $e';
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  void clearRegistrationResponse() {
    _registrationResponse = null;
    notifyListeners();
  }
}
