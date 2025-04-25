import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class OtpProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  bool _isOtpSent = false;
  String? _otpEmail;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOtpSent => _isOtpSent;
  String? get otpEmail => _otpEmail;

  Future<bool> sendOtp(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        _isOtpSent = true;
        _otpEmail = email;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to send OTP: ${response.body}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'otp': otp.trim(),
        }),
      );

      if (response.statusCode == 200) {
        _isOtpSent = false;
        _otpEmail = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'OTP verification failed: ${response.body}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void resetOtpState() {
    _isOtpSent = false;
    _otpEmail = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
