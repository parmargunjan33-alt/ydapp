// lib/features/pdf_viewer/presentation/pdf_viewer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../subscription/presentation/subscribe_bottom_sheet.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  final String url;
  final String title;
  final bool isSubscribed;
  final int paperId;
  final int? semesterId;
  final String? semesterName;

  const PdfViewerScreen({
    super.key,
    required this.url,
    required this.title,
    required this.isSubscribed,
    required this.paperId,
    this.semesterId,
    this.semesterName,
  });

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  final PdfViewerController _pdfController = PdfViewerController();
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  bool _hitPreviewLimit = false;

  static const MethodChannel _channel =
      MethodChannel('studymate/security');

  @override
  void initState() {
    super.initState();
    _enableScreenSecurity();
  }

  @override
  void dispose() {
    _disableScreenSecurity();
    _pdfController.dispose();
    super.dispose();
  }

  /// Applies FLAG_SECURE on Android to block screenshots and screen recording.
  Future<void> _enableScreenSecurity() async {
    try {
      await _channel.invokeMethod('setSecureFlag', {'secure': true});
    } catch (_) {
      // Handled natively – see MainActivity.kt
    }
  }

  Future<void> _disableScreenSecurity() async {
    try {
      await _channel.invokeMethod('setSecureFlag', {'secure': false});
    } catch (_) {}
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    setState(() => _currentPage = details.newPageNumber);

    // Enforce preview limit for unsubscribed users
    if (!widget.isSubscribed &&
        details.newPageNumber > AppConstants.pdfPreviewPages) {
      setState(() => _hitPreviewLimit = true);
      // Snap back to last allowed page
      _pdfController.jumpToPage(AppConstants.pdfPreviewPages);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D2D2D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          SfPdfViewer.network(
            widget.url,
            controller: _pdfController,
            onDocumentLoaded: (details) {
              setState(() {
                _totalPages = details.document.pages.count;
                _isLoading = false;
              });
            },
            onDocumentLoadFailed: (details) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to load PDF: ${details.description}'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            onPageChanged: _onPageChanged,
            // SECURITY RESTRICTIONS:
            enableTextSelection: false, // Prevent copying text
            enableDoubleTapZooming: true,
            pageLayoutMode: PdfPageLayoutMode.single,
            scrollDirection: PdfScrollDirection.horizontal,
            interactionMode: PdfInteractionMode.pan,
            // Disable context menu (copy, etc.)
            enableHyperlinkNavigation: false,
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: const Color(0xFF2D2D2D),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),

          // Preview limit overlay
          if (_hitPreviewLimit && !widget.isSubscribed)
            _PreviewLimitOverlay(
              semesterId: widget.semesterId,
              semesterName: widget.semesterName,
              onSubscribeTap: () {
                if (widget.semesterId != null) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => SubscribeBottomSheet(
                      semesterId: widget.semesterId!,
                      semesterName:
                          widget.semesterName ?? 'This Semester',
                    ),
                  );
                }
              },
            ),

          // Preview badge for free users
          if (!widget.isSubscribed && !_hitPreviewLimit)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Preview: $_currentPage / ${AppConstants.pdfPreviewPages} pages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PreviewLimitOverlay extends StatelessWidget {
  final int? semesterId;
  final String? semesterName;
  final VoidCallback onSubscribeTap;

  const _PreviewLimitOverlay({
    this.semesterId,
    this.semesterName,
    required this.onSubscribeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Preview Ended',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'You\'ve seen ${AppConstants.pdfPreviewPages} pages for free.\nSubscribe to read the full paper.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: onSubscribeTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 36, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Subscribe for ₹75',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Go back',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
