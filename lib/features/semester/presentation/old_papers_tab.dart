// lib/features/semester/presentation/old_papers_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../semester_repository.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart' as ew;

class OldPapersTab extends ConsumerWidget {
  final int semesterId;
  final String? semesterName;
  final SubjectModel? subject;
  final bool isSubscribed;
  final VoidCallback onSubscribeTap;

  const OldPapersTab({
    super.key,
    required this.semesterId,
    this.semesterName,
    this.subject,
    required this.isSubscribed,
    required this.onSubscribeTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final papersAsync = subject == null
        ? ref.watch(oldPapersProvider(semesterId))
        : ref.watch(pdfsBySubjectProvider(
            (semesterId: semesterId, subjectId: subject!.id)));

    return papersAsync.when(
      data: (papers) {
        if (papers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open_rounded, size: 64, color: AppColors.textHint),
                SizedBox(height: 16),
                Text(
                  'No files found in this subject',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(oldPapersProvider(semesterId));
            if (subject != null) {
              ref.invalidate(pdfsBySubjectProvider(
                  (semesterId: semesterId, subjectId: subject!.id)));
            }
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: papers.length,
            itemBuilder: (_, i) => _FileCard(
              paper: papers[i],
              isSubscribed: isSubscribed,
              onSubscribeTap: onSubscribeTap,
              semesterId: semesterId,
              semesterName: semesterName,
            ),
          ),
        );
      },
      loading: () => const LoadingWidget(),
      error: (e, _) => ew.AppErrorWidget(message: e.toString()),
    );
  }
}

class _FileCard extends ConsumerStatefulWidget {
  final OldPaperModel paper;
  final bool isSubscribed;
  final VoidCallback onSubscribeTap;
  final int semesterId;
  final String? semesterName;

  const _FileCard({
    required this.paper,
    required this.isSubscribed,
    required this.onSubscribeTap,
    required this.semesterId,
    this.semesterName,
  });

  @override
  ConsumerState<_FileCard> createState() => _FileCardState();
}

class _FileCardState extends ConsumerState<_FileCard> {
  bool _loadingUrl = false;

  Future<void> _handlePdfTap() async {
    final bool isActuallyLocked = widget.paper.isLocked && !widget.paper.isFree;

    if (isActuallyLocked) {
      widget.onSubscribeTap();
      return;
    }

    setState(() => _loadingUrl = true);
    try {
      final response = await ref
          .read(semesterRepositoryProvider)
          .getPaperViewUrl(widget.paper.id);

      final pdfUrl = response['pdf_url'] ??
          response['url'] ??
          response['file_url'] ??
          response['download_url'];

      if (pdfUrl == null || pdfUrl.toString().trim().isEmpty) {
        throw Exception('Invalid PDF link');
      }

      if (!mounted) return;

      context.push('/pdf-viewer', extra: {
        'url': pdfUrl.toString(),
        'title': widget.paper.title,
        'isSubscribed': !widget.paper.isLocked || widget.paper.isFree,
        'paperId': widget.paper.id,
        'semesterId': widget.semesterId,
        'semesterName': widget.semesterName,
      });
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString();
        // Handle locked PDF error specifically as requested
        if (errorStr.contains('403') || errorStr.contains('purchase') || errorStr.contains('subscription_required')) {
          widget.onSubscribeTap();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorStr.replaceAll('Exception: ', '')),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _loadingUrl = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isActuallyLocked = widget.paper.isLocked && !widget.paper.isFree;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _loadingUrl ? null : _handlePdfTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.picture_as_pdf_rounded,
                        color: isActuallyLocked ? Colors.grey : Colors.redAccent,
                        size: 48,
                      ),
                      if (isActuallyLocked)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(blurRadius: 4, color: Colors.black12)
                              ],
                            ),
                            child: const Icon(Icons.lock_rounded,
                                size: 14, color: Colors.orangeAccent),
                          ),
                        )
                      else if (widget.paper.isFree)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'FREE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.paper.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: isActuallyLocked
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (widget.paper.year > 0)
                    Text(
                      'Year: ${widget.paper.year}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (_loadingUrl)
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
