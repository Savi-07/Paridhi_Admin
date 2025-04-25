import 'package:dio/dio.dart';
import '../models/contact_query.dart';
import '../widgets/custom_snackbar.dart';

class ContactQueryService {
  final Dio? _dio;

  ContactQueryService(this._dio);

  Future<List<ContactQuery>> getQueries({bool? resolved}) async {
    if (_dio == null) {
      throw Exception('Dio instance is not initialized');
    }
    try {
      final response = await _dio!.get(
        '/contact',
        queryParameters: resolved != null ? {'isResolved': resolved} : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ContactQuery.fromJson(json)).toList();
      }
      throw Exception('Failed to fetch queries');
    } catch (e) {
      throw Exception('Error fetching queries: $e');
    }
  }

  Future<ContactQuery> getQueryById(int id) async {
    if (_dio == null) {
      throw Exception('Dio instance is not initialized');
    }
    try {
      final response = await _dio!.get('/contact/$id');

      if (response.statusCode == 200) {
        return ContactQuery.fromJson(response.data);
      }

      throw Exception('Failed to fetch query');
    } catch (e) {
      throw Exception('Error fetching query: $e');
    }
  }

  Future<ContactQuery> resolveQuery(
      int id, String responseText, String resolvedBy) async {
    if (_dio == null) {
      throw Exception('Dio instance is not initialized');
    }
    try {
      final response = await _dio!.put(
        '/contact/$id/resolve',
        data: {
          'response': responseText,
          'resolvedBy': resolvedBy,
        },
      );

      if (response.statusCode == 200) {
        return ContactQuery.fromJson(response.data);
      }
      if (response.statusCode == 400) {
        final data = response.data;

        if (data is Map<String, dynamic> && data['validationErrors'] != null) {
          final errors = data['validationErrors'] as List<dynamic>;

          // Get the first error message (or map through all if needed)
          final errorMessage = errors.isNotEmpty && errors[0] is Map
              ? errors[0]['message']
              : 'Bad request';

          // Log it (optional)
          // print('Validation Error: $errorMessage');

          // Throw user-friendly error
          throw Exception(errorMessage);
        } else {
          throw Exception('Bad request: ${response.data}');
        }
      }

      throw Exception('Failed to resolve query');
    } catch (e) {
      throw Exception('Error resolving query: $e');
    }
  }
}
