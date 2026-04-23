// lib/features/semester/presentation/semester_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../semester_repository.dart';
import '../../subscription/subscription_repository.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart' as ew;
import '../../subscription/presentation/subscribe_bottom_sheet.dart';

class SemesterListScreen extends ConsumerWidget {
  final CourseModel course;
  const SemesterListScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semestersAsync = ref.watch(semestersProvider(course.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(course.shortName ?? course.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(16),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Choose a semester',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
      body: semestersAsync.when(
        data: (semesters) {
          if (semesters.isEmpty) {
            return const Center(
              child: Text('No semesters available yet'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(semestersProvider(course.id));
              return ref.read(semestersProvider(course.id).future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: semesters.length,
              itemBuilder: (_, i) => _SemesterCard(
                semester: semesters[i],
                onTap: () {
                  // Always allow navigation to subjects so they can see free PDFs
                  context.push(
                    '/home/subjects/${semesters[i].id}',
                    extra: semesters[i].name,
                  );
                },
              ),
            ),
          );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => ew.AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.refresh(semestersProvider(course.id)),
        ),
      ),
    );
  }
}

class _SemesterCard extends StatelessWidget {
  final SemesterModel semester;
  final VoidCallback onTap;

  const _SemesterCard({super.key, required this.semester, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isActuallySubscribed = semester.isSubscribed;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${semester.semesterNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            semester.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Explore subjects',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isActuallySubscribed)
                      const Icon(Icons.verified_rounded,
                          color: AppColors.secondary, size: 24)
                    else
                      const Icon(Icons.lock_rounded,
                          color: AppColors.textHint, size: 24),
                  ],
                ),
                if (!isActuallySubscribed)
                  _UnlockButton(semester: semester),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnlockButton extends StatelessWidget {
  const _UnlockButton({
    required this.semester,
  });

  final SemesterModel semester;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => SubscribeBottomSheet(
                  semesterId: semester.id,
                  semesterName: semester.name,
                ),
              );
            },
            icon: const Icon(Icons.bolt_rounded, size: 18),
            label: const Text('Unlock for ₹75'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
