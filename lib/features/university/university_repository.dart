// lib/features/university/university_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_service.dart';
import '../../core/models/models.dart';

final universityRepositoryProvider = Provider<UniversityRepository>((ref) {
  return UniversityRepository(ref.watch(apiServiceProvider));
});

class UniversityRepository {
  final ApiService _api;
  UniversityRepository(this._api);

  Future<List<UniversityModel>> getUniversities() async {
    final list = await _api.getUniversities();
    return list
        .map((e) => UniversityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final universitiesProvider =
    FutureProvider<List<UniversityModel>>((ref) async {
  return ref.watch(universityRepositoryProvider).getUniversities();
});
