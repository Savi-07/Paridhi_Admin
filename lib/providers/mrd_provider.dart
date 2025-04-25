import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class MrdProvider with ChangeNotifier {
  Dio? _dio;

  MrdProvider(this._dio);

  set dio(Dio? dioInstance) {
    _dio = dioInstance;
    notifyListeners();
  }

  Dio get _safeDio {
    if (_dio == null) throw Exception('Dio instance not available');
    return _dio!;
  }

  Future<List<Map<String, dynamic>>> getMrdByEmail(String email) async {
    try {
      final response = await _safeDio.get('/mrd/user/$email/gids');

      if (response.statusCode == 200) {
        final gids = List<String>.from(response.data ?? []);
        if (gids.isEmpty) return [];

        // Fetch MRD details concurrently
        final mrdDetails = await Future.wait(
          gids.map((gid) => getMrdByGid(gid)),
        );

        return mrdDetails;
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to fetch MRD GIDs');
      }
    } catch (e) {
      throw Exception('Error fetching MRD by email: $e');
    }
  }

  Future<Map<String, dynamic>> getMrdByGid(String gid) async {
    try {
      final response = await _safeDio.get('/mrd/$gid');

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      } else {
        throw Exception('Failed to fetch MRD details for GID: $gid');
      }
    } catch (e) {
      throw Exception('Error fetching MRD by GID: $e');
    }
  }

  Future<Map<String, dynamic>> togglePaymentStatus(String gid) async {
    try {
      final response = await _safeDio.patch('/mrd/$gid/payment');

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      } else {
        throw Exception('Failed to update payment status');
      }
    } catch (e) {
      throw Exception('Error updating payment status: $e');
    }
  }
}
