// lib/features/semester/presentation/semester_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../semester_repository.dart';
import '../../subscription/subscription_repository.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart' as ew;
import 'old_papers_tab.dart';
import '../../subscription/presentation/subscribe_bottom_sheet.dart';

class SemesterScreen extends ConsumerWidget {
  final int semesterId;
  final String semesterName;
  final SubjectModel? subject;

  const SemesterScreen({
    super.key,
    required this.semesterId,
    required this.semesterName,
    this.subject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semDetailAsync = ref.watch(semesterDetailProvider(semesterId));

    final String displayTitle = subject != null
        ? '${subject!.name} (${semesterName})'
        : semesterName;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          displayTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: const [],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(semesterDetailProvider(semesterId));
          ref.invalidate(oldPapersProvider(semesterId));
          if (subject != null) {
            ref.invalidate(pdfsBySubjectProvider(
                (semesterId: semesterId, subjectId: subject!.id)));
          }
          return ref.read(semesterDetailProvider(semesterId).future);
        },
        child: semDetailAsync.when(
          data: (semester) => OldPapersTab(
            semesterId: semesterId,
            semesterName: semesterName,
            subject: subject,
            isSubscribed: semester.isSubscribed,
            onSubscribeTap: () => _showSubscribe(context),
          ),
          loading: () => const LoadingWidget(),
          error: (e, _) => ew.AppErrorWidget(message: e.toString()),
        ),
      ),
    );
  }

  void _showSubscribe(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubscribeBottomSheet(
        semesterId: semesterId,
        semesterName: semesterName,
      ),
    );
  }
}
