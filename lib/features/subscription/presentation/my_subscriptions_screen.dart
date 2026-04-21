// lib/features/subscription/presentation/my_subscriptions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../subscription_repository.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';

class MySubscriptionsScreen extends ConsumerWidget {
  const MySubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subsAsync = ref.watch(mySubscriptionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Subscriptions')),
      body: subsAsync.when(
        data: (subs) {
          if (subs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.subscriptions_outlined,
                      size: 72, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  const Text(
                    'No subscriptions yet',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Subscribe to a semester to get full access',
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final active = subs.where((s) => s.isActive).toList();
          final expired = subs.where((s) => !s.isActive).toList();

          return RefreshIndicator(
            onRefresh: () => ref.refresh(mySubscriptionsProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (active.isNotEmpty) ...[
                  _SectionHeader(
                      label: 'Active (${active.length})',
                      color: AppColors.secondary),
                  const SizedBox(height: 10),
                  ...active.map((s) => _SubCard(sub: s)),
                  const SizedBox(height: 20),
                ],
                if (expired.isNotEmpty) ...[
                  _SectionHeader(
                      label: 'Expired (${expired.length})',
                      color: AppColors.textSecondary),
                  const SizedBox(height: 10),
                  ...expired.map((s) => _SubCard(sub: s)),
                ],
              ],
            ),
          );
        },
        loading: () => const LoadingWidget(shimmer: true),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.refresh(mySubscriptionsProvider),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SubCard extends StatelessWidget {
  final SubscriptionModel sub;
  const _SubCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    final daysLeft = sub.endDate.difference(DateTime.now()).inDays;
    final progressValue = sub.isActive
        ? daysLeft /
            sub.endDate.difference(sub.startDate).inDays.clamp(1, 999)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: sub.isActive
                        ? AppColors.secondary.withOpacity(0.1)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    sub.isActive
                        ? Icons.verified_rounded
                        : Icons.history_rounded,
                    color: sub.isActive
                        ? AppColors.secondary
                        : AppColors.textHint,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Semester ${sub.semesterId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sub.isActive
                            ? '$daysLeft days remaining'
                            : 'Expired',
                        style: TextStyle(
                          fontSize: 12,
                          color: sub.isActive
                              ? AppColors.secondary
                              : AppColors.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sub.isActive
                        ? AppColors.secondary.withOpacity(0.1)
                        : AppColors.divider,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    sub.isActive ? 'Active' : 'Expired',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: sub.isActive
                          ? AppColors.secondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            if (sub.isActive) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressValue.clamp(0.0, 1.0),
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                  minHeight: 6,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                _DateChip(
                  label: 'Started',
                  date:
                      '${sub.startDate.day}/${sub.startDate.month}/${sub.startDate.year}',
                ),
                const SizedBox(width: 8),
                _DateChip(
                  label: 'Expires',
                  date:
                      '${sub.endDate.day}/${sub.endDate.month}/${sub.endDate.year}',
                  highlight: sub.isActive,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final String date;
  final bool highlight;
  const _DateChip(
      {required this.label, required this.date, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withOpacity(0.07)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
          Text(date,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: highlight ? AppColors.primary : AppColors.textPrimary,
              )),
        ],
      ),
    );
  }
}
