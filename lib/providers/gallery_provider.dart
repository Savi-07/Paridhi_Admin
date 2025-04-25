import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

class GalleryProvider with ChangeNotifier {
  final Dio? _dio;
  List<Map<String, dynamic>> _galleryItems = [];
  bool _isLoading = false;
  String? _error;
  
  // Pagination state
  int _currentPage = 0;
  int _pageSize = 12;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;

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

  GalleryProvider(this._dio);

  List<Map<String, dynamic>> get galleryItems => _galleryItems;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMorePages => _hasMorePages;

  void _setError(String value) {
    _error = value;
    notifyListeners();
  }

  Future<void> fetchGallery({bool refresh = true}) async {
    if (refresh) {
      _isLoading = true;
      _error = null;
      _currentPage = 0;
      _galleryItems = [];
      _hasMorePages = true;
      notifyListeners();
    }

    try {
      if (_dio == null) {
        _setError('Not authenticated');
        return;
      }

      final response = await _dio.get('/galleries', queryParameters: {
        'page': _currentPage,
        'size': _pageSize,
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        if (data['content'] is List) {
          final newItems = List<Map<String, dynamic>>.from(data['content']);
          if (refresh) {
            _galleryItems = newItems;
          } else {
            _galleryItems.addAll(newItems);
          }
          
          // Update pagination state
          _hasMorePages = !data['last'];
          _currentPage++;
          _error = null;
        } else {
          _setError('Invalid response format: content array not found');
        }
      } else {
        _setError('Failed to fetch gallery items');
      }
    } catch (e) {
      _setError('Error: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> loadMoreItems() async {
    if (!_hasMorePages || _isLoading || _isLoadingMore) {
      return;
    }
    
    _isLoadingMore = true;
    notifyListeners();
    
    try {
      if (_dio == null) {
        _setError('Not authenticated');
        return;
      }

      final response = await _dio.get('/galleries', queryParameters: {
        'page': _currentPage,
        'size': _pageSize,
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        if (data['content'] is List) {
          final newItems = List<Map<String, dynamic>>.from(data['content']);
          _galleryItems.addAll(newItems);
          
          // Update pagination state
          _hasMorePages = !data['last'];
          _currentPage++;
          _error = null;
        } else {
          _setError('Invalid response format: content array not found');
        }
      } else {
        _setError('Failed to fetch more gallery items');
      }
    } catch (e) {
      _setError('Error: ${e.toString()}');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> uploadImage(String paridhiYear, String imagePath, {MediaType? contentType}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_dio == null) {
        _setError('Not authenticated');
        return false;
      }

      MultipartFile imageFile;
      if (contentType != null) {
        imageFile = await MultipartFile.fromFile(
          imagePath, 
          contentType: contentType
        );
      } else {
        imageFile = await MultipartFile.fromFile(imagePath);
      }

      // Validate image type
      if (!_isValidImageType(imageFile)) {
        _setError('Invalid image type. Allowed types: JPEG, PNG, GIF, WEBP, SVG, HEIC, HEIF, TIFF, BMP');
        return false;
      }

      final formData = FormData.fromMap({
        'batchYear': paridhiYear,
        'image': imageFile,
      });

      final response = await _dio.post(
        '/galleries',
        data: formData,
      );

      if (response.statusCode == 201) {
        await fetchGallery();
        return true;
      } else {
        _setError('Failed to upload image, ${response.data}');
        return false;
      }
    } catch (e) {
      _setError('Error: ${e.toString()}');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateImage(
      int id, String paridhiYear, String? imagePath, {MediaType? contentType}) async {
    
    _error = null;
    notifyListeners();

    try {
      if (_dio == null) {
        _setError('Not authenticated');
        return false;
      }

      final formData = FormData.fromMap({
        'batchYear': paridhiYear,
      });

      if (imagePath != null) {
        MultipartFile imageFile;
        if (contentType != null) {
          imageFile = await MultipartFile.fromFile(
            imagePath, 
            contentType: contentType
          );
        } else {
          imageFile = await MultipartFile.fromFile(imagePath);
        }

        // Validate image type
        if (!_isValidImageType(imageFile)) {
          _setError('Invalid image type. Allowed types: JPEG, PNG, GIF, WEBP, SVG, HEIC, HEIF, TIFF, BMP');
          return false;
        }

        formData.files.add(
          MapEntry(
            'image',
            imageFile,
          ),
        );
      }

      final response = await _dio.put('/galleries/$id', data: formData);

      if (response.statusCode == 200) {
        await fetchGallery();
        return true;
      } else {
        // await fetchGallery();

        _setError('Failed to update image');
        return false;
      }
    } catch (e) {
      _setError('Error: ${e.toString()}');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteImage(String imageId) async {
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_dio == null) {
        _setError('Not authenticated');
        return false;
      }

      final response = await _dio.delete('/galleries/$imageId');

      if (response.statusCode == 204) {
        await fetchGallery();
        return true;
      } else {
        _setError('Failed to delete image');
        return false;
      }
    } catch (e) {
      _setError('Error: ${e.toString()}');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
