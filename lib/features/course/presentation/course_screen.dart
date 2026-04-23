// lib/features/course/presentation/course_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../course_repository.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart' as ew;
import '../../../core/widgets/search_bar_widget.dart';

class CourseScreen extends ConsumerStatefulWidget {
  final UniversityModel university;
  const CourseScreen({super.key, required this.university});

  @override
  ConsumerState<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends ConsumerState<CourseScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider(widget.university.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.university.name),
        actions: [
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.account_circle_outlined, size: 28),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(16),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Select a course',
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: AppSearchBar(
              hint: 'Search courses...',
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: coursesAsync.when(
              data: (courses) {
                final filtered = courses
                    .where((c) =>
                        c.name
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()) ||
                        (c.shortName
                                ?.toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ??
                            false))
                    .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No courses found',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref
                      .refresh(coursesProvider(widget.university.id).future),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _CourseCard(
                      course: filtered[i],
                      onTap: () => context.push(
                        '/home/semesters',
                        extra: filtered[i],
                      ),
                    ),
                  ),
                );
              },
              loading: () => const LoadingWidget(),
              error: (e, _) => ew.AppErrorWidget(
                message: e.toString(),
                onRetry: () =>
                    ref.refresh(coursesProvider(widget.university.id)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;

  const _CourseCard({required this.course, required this.onTap});

  // Maps course names to icons
  IconData _iconForCourse(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('engineer') || lower.contains('b.e') || lower.contains('b.tech')) {
      return Icons.engineering_rounded;
    } else if (lower.contains('commerce') || lower.contains('b.com')) {
      return Icons.account_balance_rounded;
    } else if (lower.contains('science') || lower.contains('b.sc')) {
      return Icons.science_rounded;
    } else if (lower.contains('art') || lower.contains('b.a')) {
      return Icons.palette_rounded;
    } else if (lower.contains('medical') || lower.contains('mbbs')) {
      return Icons.local_hospital_rounded;
    } else if (lower.contains('computer') || lower.contains('bca') || lower.contains('mca')) {
      return Icons.computer_rounded;
    } else if (lower.contains('mba') || lower.contains('management')) {
      return Icons.business_center_rounded;
    }
    return Icons.school_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.secondary.withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconForCourse(course.name),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.secondary
                        : AppColors.primary,
                    size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            course.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (course.shortName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkSurfaceVariant
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              course.shortName!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (course.description != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        course.description!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      course.semestersCount > 0
                          ? '${course.semestersCount} semesters'
                          : 'Explore semesters',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.secondary
                            : AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
