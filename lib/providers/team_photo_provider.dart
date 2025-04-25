import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import '../models/team_photo.dart';
import '../services/team_photo_service.dart';

class TeamPhotoProvider with ChangeNotifier {
  TeamPhotoService? _service;
  List<TeamPhoto> _photos = [];
  bool _isLoading = false;
  String? _error;
  Dio? _dio;

  // Add a list of allowed MIME types
  static final List<String> allowedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/jpg',
    'image/gif',
    'image/webp',
    'image/svg+xml',
    'image/heic',
    'image/heif',
    'image/tiff',
    'image/bmp',
  ];

  // Validate image content type
  bool _isValidImageType(MultipartFile file) {
    final contentType = file.contentType?.mimeType;
    return contentType != null && allowedImageTypes.contains(contentType);
  }

  TeamPhotoProvider({Dio? dio}) {
    _dio = dio;
    if (_dio != null) {
      _service = TeamPhotoService(dio: _dio);
    }
  }

  List<TeamPhoto> get photos => _photos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAllPhotos({String? category}) async {
    if (_service == null) {
      _error = 'Service not initialized';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _photos = await _service!.getAllTeamPhotos(category: category);
      _printPhotoStats();
    } catch (e) {
      if (e is DioException) {
        _error = e.response?.data?['message'] ??
            e.message ??
            'Failed to fetch photos';
      } else {
        _error = e.toString();
      }
      print('Error fetching photos: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _printPhotoStats() {
    final categories = _photos.map((p) => p.category).toSet();
    print('Total photos: ${_photos.length}');
    print('Available categories: $categories');
    
    for (final category in categories) {
      final count = _photos.where((p) => p.category == category).length;
      print('Category $category has $count photos');
    }
  }

  Future<bool> createPhoto({
    required String category,
    required XFile photo,
  }) async {
    if (_service == null) {
      _error = 'Service not initialized';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final bytes = await photo.readAsBytes();
      final filename = photo.name;
      final photoFile = MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: MediaType.parse(photo.mimeType ?? 'image/jpeg'),
      );

      // Validate image type
      if (!_isValidImageType(photoFile)) {
        _error = 'Invalid image type. Allowed types: JPEG, PNG, GIF, WEBP, SVG, HEIC, HEIF, TIFF, BMP';
        notifyListeners();
        return false;
      }

      final newPhoto = await _service!.createTeamPhoto(
        category: category,
        photo: photoFile,
      );
      _photos.add(newPhoto);
      return true;
    } catch (e) {
      if (e is DioException) {
        final responseData = e.response?.data;
        if (responseData != null && responseData is Map) {
          _error = responseData['message'] ?? responseData['error'] ?? e.message ?? 'Failed to create photo';
        } else {
          _error = e.message ?? 'Failed to create photo';
        }
      } else {
        _error = e.toString();
      }
      print('Error creating photo: $_error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePhoto({
    required int id,
    required String category,
    required XFile photo,
  }) async {
    if (_service == null) {
      _error = 'Service not initialized';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final bytes = await photo.readAsBytes();
      final filename = photo.name;
      final photoFile = MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: MediaType.parse(photo.mimeType ?? 'image/jpeg'),
      );

      // Validate image type
      if (!_isValidImageType(photoFile)) {
        _error = 'Invalid image type. Allowed types: JPEG, PNG, GIF, WEBP, SVG, HEIC, HEIF, TIFF, BMP';
        notifyListeners();
        return false;
      }

      final updatedPhoto = await _service!.updateTeamPhoto(
        id: id,
        category: category,
        photo: photoFile,
      );
      
      final index = _photos.indexWhere((p) => p.id == id);
      if (index != -1) {
        _photos[index] = updatedPhoto;
      }
      return true;
    } catch (e) {
      if (e is DioException) {
        final responseData = e.response?.data;
        if (responseData != null && responseData is Map) {
          _error = responseData['message'] ?? responseData['error'] ?? e.message ?? 'Failed to update photo';
        } else {
          _error = e.message ?? 'Failed to update photo';
        }
      } else {
        _error = e.toString();
      }
      print('Error updating photo: $_error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePhoto(int id) async {
    if (_service == null) {
      _error = 'Service not initialized';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service!.deleteTeamPhoto(id);
      _photos.removeWhere((photo) => photo.id == id);
      return true;
    } catch (e) {
      if (e is DioException) {
        _error = e.response?.data?['message'] ??
            e.message ??
            'Failed to delete photo';
      } else {
        _error = e.toString();
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<TeamPhoto> getPhotosByCategory(String category) {
    // Map between API keys and actual categories
    final categoryMappings = {
      'members': 'MEGATRONS',
      'megatrons': 'MEGATRONS',
      'developers': 'DEVELOPERS',
    };
    
    final normalizedCategory = categoryMappings[category.toLowerCase()] ?? category.toUpperCase();
    
    return _photos.where((photo) => 
      photo.category.toUpperCase() == normalizedCategory
    ).toList();
  }
}
