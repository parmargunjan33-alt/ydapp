// lib/features/semester/presentation/subject_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../semester_repository.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart' as ew;

class SubjectListScreen extends ConsumerWidget {
  final int semesterId;
  final String semesterName;

  const SubjectListScreen({
    super.key,
    required this.semesterId,
    required this.semesterName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider(semesterId));

    return Scaffold(
      appBar: AppBar(
        title: Text(semesterName),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(16),
          child: Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Select a Subject',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
      body: subjectsAsync.when(
        data: (subjects) {
          if (subjects.isEmpty) {
            return const Center(
              child: Text('No subjects available for this semester'),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(subjectsProvider(semesterId).future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: subjects.length,
              itemBuilder: (_, i) => _SubjectCard(
                subject: subjects[i],
                semesterName: semesterName,
              ),
            ),
          );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => ew.AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.refresh(subjectsProvider(semesterId)),
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final SubjectModel subject;
  final String semesterName;

  const _SubjectCard({required this.subject, required this.semesterName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.push(
              '/home/semester/${subject.semesterId}',
              extra: {
                'semesterName': semesterName,
                'subject': subject,
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.book_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (subject.code != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subject.code!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
