// lib/features/semester/semester_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../course/course_repository.dart';
import '../../core/api/api_service.dart';
import '../../core/models/models.dart';

final semesterRepositoryProvider = Provider<SemesterRepository>((ref) {
  return SemesterRepository(ref.watch(apiServiceProvider));
});

class SemesterRepository {
  final ApiService _api;
  SemesterRepository(this._api);

  Future<List<SemesterModel>> getSemesters(int courseId) async {
    final list = await _api.getSemesters(courseId);
    return list
        .map((e) => SemesterModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SemesterModel> getSemesterDetail(int semesterId) async {
    final res = await _api.getSemesterDetail(semesterId);
    // If the internal get already wrapped it in 'data'
    final data = res['data'] ?? res['semester'] ?? res;
    
    if (data is List && data.isNotEmpty) {
      return SemesterModel.fromJson(data.first as Map<String, dynamic>);
    }

    return SemesterModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<List<OldPaperModel>> getOldPapers(int semesterId) async {
    final list = await _api.getOldPapers(semesterId);
    return list
        .map((e) => OldPaperModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<OldPaperModel>> getPdfsBySubject({
    required int semesterId,
    required int subjectId,
  }) async {
    final list = await _api.getPdfsBySubject(
      semesterId: semesterId,
      subjectId: subjectId,
    );
    return list
        .map((e) => OldPaperModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SubjectModel>> getSubjects(int semesterId) async {
    final list = await _api.getSubjects(semesterId);
    return list
        .map((e) => SubjectModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getPaperViewUrl(int paperId) =>
      _api.getPaperViewUrl(paperId);
}

final semestersProvider =
    FutureProvider.family<List<SemesterModel>, int>((ref, courseId) async {
  return ref.watch(semesterRepositoryProvider).getSemesters(courseId);
});

final semesterDetailProvider =
    FutureProvider.family<SemesterModel, int>((ref, semesterId) async {
  return ref.watch(semesterRepositoryProvider).getSemesterDetail(semesterId);
});

final subjectsProvider =
    FutureProvider.family<List<SubjectModel>, int>((ref, semesterId) async {
  return ref.watch(semesterRepositoryProvider).getSubjects(semesterId);
});

final oldPapersProvider =
    FutureProvider.family<List<OldPaperModel>, int>((ref, semesterId) async {
  return ref.watch(semesterRepositoryProvider).getOldPapers(semesterId);
});

final pdfsBySubjectProvider = FutureProvider.family<List<OldPaperModel>,
    ({int semesterId, int subjectId})>((ref, arg) async {
  return ref.watch(semesterRepositoryProvider).getPdfsBySubject(
        semesterId: arg.semesterId,
        subjectId: arg.subjectId,
      );
});
