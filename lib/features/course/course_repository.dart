import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/models.dart';

/// Modern Notifier for language selection (Riverpod 3.x compatible)
class SelectedLanguageNotifier extends Notifier<String> {
  @override
  String build() {
    return AppConstants.langEnglish;
  }

  void setLanguage(String lang) {
    state = lang;
  }
}

final selectedLanguageProvider = NotifierProvider<SelectedLanguageNotifier, String>(() {
  return SelectedLanguageNotifier();
});

/// Provider for the CourseRepository instance
final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return CourseRepository(api);
});

class CourseRepository {
  final ApiService _api;
  CourseRepository(this._api);

  Future<List<CourseModel>> getCourses(int universityId) async {
    final list = await _api.getCourses(universityId);
    
    return list
        .map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Provider for the list of courses, reactively linked to universityId
final coursesProvider = FutureProvider.family<List<CourseModel>, int>((ref, universityId) async {
  final repo = ref.watch(courseRepositoryProvider);
  return repo.getCourses(universityId);
});
