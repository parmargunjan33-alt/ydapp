// lib/features/semester/presentation/summary_tab.dart
import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';

class SummaryTab extends StatelessWidget {
  final SemesterModel semester;
  final SubjectModel? subject;
  final bool isSubscribed;
  final VoidCallback onSubscribeTap;

  const SummaryTab({
    super.key,
    required this.semester,
    this.subject,
    required this.isSubscribed,
    required this.onSubscribeTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isSubscribed) {
      return _LockedSummary(onSubscribeTap: onSubscribeTap);
    }

    final summary = subject?.summary ?? semester.summary;

    if (summary == null || summary.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notes_rounded, size: 64, color: AppColors.textHint),
            SizedBox(height: 16),
            Text(
              'No summary added yet',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_stories_rounded,
                    color: Colors.white, size: 32),
                const SizedBox(height: 10),
                Text(
                  subject?.name ?? semester.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subject != null
                      ? 'Subject Summary'
                      : 'Semester ${semester.semesterNumber} Summary',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Summary content
          Text(
            summary,
            style: const TextStyle(
              fontSize: 15,
              height: 1.7,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _LockedSummary extends StatelessWidget {
  final VoidCallback onSubscribeTap;
  const _LockedSummary({required this.onSubscribeTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_person_rounded,
                size: 64, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          const Text(
            'Summary Locked',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Unlock this semester to access full summaries and exam papers.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSubscribeTap,
              icon: const Icon(Icons.payment_rounded),
              label: const Text('Subscribe now at ₹75'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
