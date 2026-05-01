// lib/features/pdf_viewer/presentation/pdf_viewer_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../core/api/api_client.dart';
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
  final SearchController _searchController = SearchController();
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(1);
  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  bool _isSearchOpen = false;
  int _totalPages = 0;
  bool _isLoading = true;
  bool _hitPreviewLimit = false;
  String? _localPath;
  File? _pdfFile;
  double _downloadProgress = 0;
  String? _errorMessage;

  static const MethodChannel _channel =
      MethodChannel('studymate/security');

  @override
  void initState() {
    super.initState();
    _enableScreenSecurity();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final directory = await getApplicationCacheDirectory();
      final fileName = 'paper_${widget.paperId}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        setState(() {
          _localPath = filePath;
          _pdfFile = file;
          // Note: _isLoading will be set to false in onDocumentLoaded
        });
        return;
      }

      final dio = ref.read(dioProvider);
      await dio.download(
        widget.url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _localPath = filePath;
          _pdfFile = File(filePath);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to download PDF. Please check your connection.';
        });
      }
    }
  }

  @override
  void dispose() {
    _disableScreenSecurity();
    _pdfController.dispose();
    _currentPageNotifier.dispose();
    _searchResult.clear();
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
    _currentPageNotifier.value = details.newPageNumber;

    // Enforce preview limit for unsubscribed users
    if (!widget.isSubscribed &&
        details.newPageNumber > AppConstants.pdfPreviewPages) {
      if (!_hitPreviewLimit) {
        setState(() => _hitPreviewLimit = true);
      }
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
          IconButton(
            icon: Icon(_isSearchOpen ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearchOpen) {
                  _searchResult.clear();
                  _isSearchOpen = false;
                } else {
                  _isSearchOpen = true;
                }
              });
            },
          ),
          if (_totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: ValueListenableBuilder<int>(
                  valueListenable: _currentPageNotifier,
                  builder: (context, page, _) {
                    return Text(
                      '$page / $_totalPages',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearchOpen)
            Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search keyword...',
                        hintStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white54
                              : Colors.black45,
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          _searchResult = _pdfController.searchText(value);
                          _searchResult.addListener(() {
                            if (mounted) setState(() {});
                          });
                        }
                      },
                    ),
                  ),
                  if (_searchResult.hasResult) ...[
                    Text(
                      '${_searchResult.currentInstanceIndex} / ${_searchResult.totalInstanceCount}',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.keyboard_arrow_up,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                      onPressed: () => _searchResult.previousInstance(),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                      onPressed: () => _searchResult.nextInstance(),
                    ),
                  ],
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                if (_pdfFile != null)
                  SfPdfViewer.file(
                    _pdfFile!,
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
                    pageLayoutMode: PdfPageLayoutMode.continuous,
                    scrollDirection: PdfScrollDirection.vertical,
                    // Disable context menu (copy, etc.)
                    enableHyperlinkNavigation: false,
                    canShowScrollHead: true,
                    pageSpacing: 4,
                  )
                else if (_errorMessage != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _errorMessage = null;
                                _isLoading = true;
                                _downloadProgress = 0;
                              });
                              _loadPdf();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Loading overlay
                if (_isLoading)
                  Container(
                    color: const Color(0xFF2D2D2D),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: AppColors.primary),
                          if (_localPath == null && _downloadProgress > 0) ...[
                            const SizedBox(height: 20),
                            Text(
                              'Downloading: ${(_downloadProgress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: LinearProgressIndicator(
                                value: _downloadProgress,
                                backgroundColor: Colors.white10,
                                color: AppColors.primary,
                              ),
                            ),
                          ] else if (_localPath == null) ...[
                            const SizedBox(height: 20),
                            const Text(
                              'Connecting...',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ] else ...[
                            const SizedBox(height: 20),
                            const Text(
                              'Opening PDF...',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ],
                      ),
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
                    child: ValueListenableBuilder<int>(
                      valueListenable: _currentPageNotifier,
                      builder: (context, page, _) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Preview: $page / ${AppConstants.pdfPreviewPages} pages',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
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
