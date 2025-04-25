import 'package:dio/dio.dart';
import '../models/team_photo.dart';
import '../core/constants.dart';

class TeamPhotoService {
  final Dio dio;

  TeamPhotoService({Dio? dio}) : dio = dio ?? Dio() {
    if (dio == null) {
      this.dio.options.baseUrl = ApiConstants.baseUrl;
    }

    // Add interceptors for logging
    this.dio.interceptors.add(InterceptorsWrapper(
          onRequest: (options, handler) {
            // print('Request: ${options.method} ${options.path}');
            // print('Headers: ${options.headers}');
            // print('Data: ${options.data}');
            return handler.next(options);
          },
          onResponse: (response, handler) {
            // print('Response: ${response.statusCode}');
            // print('Data: ${response.data}');
            return handler.next(response);
          },
          onError: (DioException e, handler) {
            // print('Error: ${e.message}');
            // print('Error Response: ${e.response?.data}');
            return handler.next(e);
          },
        ));
  }

  Future<List<TeamPhoto>> getAllTeamPhotos({String? category}) async {
    try {
      final response = await dio.get(
        '/team-photo',
        queryParameters: category != null && category.isNotEmpty
            ? {'category': category}
            : null,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        List<TeamPhoto> photos = [];
        
        // Map between API response keys and actual categories
        final categoryMappings = {
          'members': 'MEGATRONS',
          'developers': 'DEVELOPERS',
        };
        
        // Process each category in the response
        responseData.forEach((key, value) {
          if (value is List) {
            final mappedCategory = categoryMappings[key.toLowerCase()] ?? key.toUpperCase();
            
            // If a specific category was requested, only include photos from that category
            if (category == null || 
                category.isEmpty || 
                mappedCategory == category.toUpperCase() ||
                (key.toLowerCase() == 'members' && category.toUpperCase() == 'MEGATRONS')) {
              
              // Use the mapped category or the original key
              photos.addAll(value.map((json) {
                // Make sure each photo has the correct category
                if (key.toLowerCase() == 'members' && json['category'] != 'MEGATRONS') {
                  json = Map<String, dynamic>.from(json);
                  json['category'] = 'MEGATRONS';
                }
                return TeamPhoto.fromJson(json);
              }).toList());
            }
          }
        });
        
        print('Found ${photos.length} photos');
        print('Categories found: ${photos.map((p) => p.category).toSet()}');
        return photos;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to fetch team photos: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in getAllTeamPhotos: $e');
      if (e is DioException) {
        print('DioError details: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<TeamPhoto> createTeamPhoto({
    required String category,
    required MultipartFile photo,
  }) async {
    try {
      final formData = FormData.fromMap({
        'category': category,
        'teamPhoto': photo,
      });

      final response = await dio.post(
        '/team-photo',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      
      // The response structure may have changed
      if (response.data is Map<String, dynamic> && response.data.containsKey('category')) {
        return TeamPhoto.fromJson(response.data);
      } else {
        // If the response doesn't match our expected format, handle it
        print('Unexpected response format: ${response.data}');
        return TeamPhoto.fromJson(response.data);
      }
    } catch (e) {
      print('Error in createTeamPhoto: $e');
      if (e is DioException) {
        print('DioError details: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<TeamPhoto> updateTeamPhoto({
    required int id,
    required String category,
    required MultipartFile photo,
  }) async {
    try {
      final formData = FormData.fromMap({
        'category': category,
        'teamPhoto': photo,
      });

      final response = await dio.put(
        '/team-photo/$id',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      
      // The response structure may have changed
      if (response.data is Map<String, dynamic> && response.data.containsKey('category')) {
        return TeamPhoto.fromJson(response.data);
      } else {
        // If the response doesn't match our expected format, handle it
        print('Unexpected response format: ${response.data}');
        return TeamPhoto.fromJson(response.data);
      }
    } catch (e) {
      print('Error in updateTeamPhoto: $e');
      if (e is DioException) {
        print('DioError details: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<bool> deleteTeamPhoto(int id) async {
    try {
      await dio.delete('${ApiConstants.baseUrl}/team-photo/$id');
      return true;
    } catch (e) {
      print('Error in deleteTeamPhoto: $e');
      if (e is DioException) {
        print('DioError details: ${e.response?.data}');
      }
      rethrow;
    }
  }
}

