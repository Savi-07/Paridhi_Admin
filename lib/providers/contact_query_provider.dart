import 'package:flutter/foundation.dart';
import '../models/contact_query.dart';
import '../services/contact_query_service.dart';

class ContactQueryProvider with ChangeNotifier {
  final ContactQueryService _service;
  List<ContactQuery> _queries = [];
  bool _isLoading = false;
  String? _error;

  ContactQueryProvider(this._service);

  List<ContactQuery> get queries => _queries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchQueries({bool? resolved}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _queries = await _service.getQueries(resolved: resolved);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resolveQuery(int id, String response, String resolvedBy) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedQuery =
          await _service.resolveQuery(id, response, resolvedBy);
      final index = _queries.indexWhere((q) => q.id == id);
      if (index != -1) {
        _queries[index] = updatedQuery;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
