import 'package:dio/dio.dart';
import '../models/domain_poster.dart';

class DomainPosterService {
  final Dio dio;

  DomainPosterService(this.dio);

  Future<List<DomainPoster>> getAllDomainPosters() async {
    final response = await dio.get('/domain-posters');
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = response.data;
      return jsonList.map((json) => DomainPoster.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load domain posters');
    }
  }

  Future<List<DomainPoster>> getDomainPostersByDomain(String domainName) async {
    final response = await dio.get('/domain-posters/$domainName');
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = response.data;
      return jsonList.map((json) => DomainPoster.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load domain posters for $domainName');
    }
  }

  Future<DomainPoster> createDomainPoster(
      String domainName, MultipartFile posterFile) async {
    final formData = FormData.fromMap({
      'domainName': domainName.toUpperCase(),
      'domainPoster': posterFile,
    });

    final response = await dio.post(
      '/domain-posters',
      data: formData,
    );

    if (response.statusCode == 201) {
      return DomainPoster.fromJson(response.data);
    } else {
      throw Exception('Failed to create domain poster');
    }
  }

  Future<DomainPoster> updateDomainPoster(
      int id, String domainName, MultipartFile posterFile) async {
    final formData = FormData.fromMap({
      'domainName': domainName.toUpperCase(),
      'domainPoster': posterFile,
    });

    final response = await dio.put(
      '/domain-posters/$id',
      data: formData,
    );

    if (response.statusCode == 200) {
      return DomainPoster.fromJson(response.data);
    } 
    else {
      throw Exception('Failed to update domain poster');
    }
  }

  Future<bool> deleteDomainPoster(int id) async {
    final response = await dio.delete('/domain-posters/$id');
    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }
}
