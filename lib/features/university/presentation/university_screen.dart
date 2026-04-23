// lib/features/university/presentation/university_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../university_repository.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart' as ew;
import '../../../core/widgets/search_bar_widget.dart';

class UniversityScreen extends ConsumerStatefulWidget {
  const UniversityScreen({super.key});

  @override
  ConsumerState<UniversityScreen> createState() => _UniversityScreenState();
}

class _UniversityScreenState extends ConsumerState<UniversityScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final universitiesAsync = ref.watch(universitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select University'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: AppSearchBar(
              hint: 'Search universities...',
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: universitiesAsync.when(
              data: (universities) {
                final filtered = universities
                    .where((u) => u.name
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                    .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No universities found',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(universitiesProvider.future),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _UniversityCard(
                      university: filtered[i],
                      onTap: () => context.push(
                        '/home/courses',
                        extra: filtered[i],
                      ),
                    ),
                  ),
                );
              },
              loading: () => const LoadingWidget(),
              error: (e, _) => ew.AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.refresh(universitiesProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UniversityCard extends StatelessWidget {
  final UniversityModel university;
  final VoidCallback onTap;

  const _UniversityCard({required this.university, required this.onTap});

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
              // Logo / placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: university.logo != null && university.logo!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: university.logo!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _LogoPlaceholder(
                            name: university.shortName ?? university.name),
                        errorWidget: (_, __, ___) => _LogoPlaceholder(
                            name: university.shortName ?? university.name),
                      )
                    : _LogoPlaceholder(
                        name: university.shortName ?? university.name),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      university.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (university.city != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            university.city!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      university.coursesCount > 0
                          ? '${university.coursesCount} courses'
                          : 'Explore courses',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  final String name;
  const _LogoPlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    // If name contains spaces and is not already a short code, maybe take initials?
    // But since the user wants the short_name from API, and we pass that, 
    // we should just show it.
    String display = name;
    if (display.contains(' ') && display.length > 10) {
      // It's probably the full name "Gujarat University", try to get initials "GU"
      display = display.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join();
    }
    
    // Limit to 4 characters for UI
    if (display.length > 4) display = display.substring(0, 4);

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.secondary.withOpacity(0.2)
            : AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          display.toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.secondary
                : AppColors.primary,
            fontSize: display.length > 2 ? 14 : 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
