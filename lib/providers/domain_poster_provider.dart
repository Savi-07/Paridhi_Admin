import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../models/domain_poster.dart';
import '../services/domain_poster_service.dart';

class DomainPosterProvider with ChangeNotifier {
  DomainPosterService? _service;
  List<DomainPoster> _posters = [];
  bool _isLoading = false;
  String? _error;

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

  DomainPosterProvider(Dio? dio) {
    if (dio != null) {
      _service = DomainPosterService(dio);
    }
  }

  List<DomainPoster> get posters => _posters;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAllPosters() async {
    if (_service == null) {
      _error = 'Service not initialized';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _posters = await _service!.getAllDomainPosters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPostersByDomain(String domainName) async {
    if (_service == null) {
      _error = 'Service not initialized';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _posters = await _service!.getDomainPostersByDomain(domainName);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPoster(String domainName, MultipartFile posterFile) async {
    if (_service == null) {
      _error = 'Service not initialized';
      notifyListeners();
      return false;
    }

    // Validate image type
    if (!_isValidImageType(posterFile)) {
      _error = 'Invalid image type. Allowed types: JPEG, PNG, GIF, WEBP, SVG, HEIC, HEIF, TIFF, BMP';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newPoster =
          await _service!.createDomainPoster(domainName, posterFile);
      _posters.add(newPoster);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePoster(
      int id, String domainName, MultipartFile posterFile) async {
    if (_service == null) {
      _error = 'Service not initialized';
      notifyListeners();
      return false;
    }

    // Validate image type
    if (!_isValidImageType(posterFile)) {
      _error = 'Invalid image type. Allowed types: JPEG, PNG, GIF, WEBP, SVG, HEIC, HEIF, TIFF, BMP';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedPoster =
          await _service!.updateDomainPoster(id, domainName, posterFile);
      final index = _posters.indexWhere((poster) => poster.id == id);
      if (index != -1) {
        _posters[index] = updatedPoster;
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePoster(int id) async {
    if (_service == null) {
      _error = 'Service not initialized';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service!.deleteDomainPoster(id);
      _posters.removeWhere((poster) => poster.id == id);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
