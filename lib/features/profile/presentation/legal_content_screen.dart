import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

class LegalContentScreen extends ConsumerStatefulWidget {
  final String title;
  final String endpoint;

  const LegalContentScreen({
    super.key,
    required this.title,
    required this.endpoint,
  });

  @override
  ConsumerState<LegalContentScreen> createState() => _LegalContentScreenState();
}

class _LegalContentScreenState extends ConsumerState<LegalContentScreen> {
  bool _isLoading = true;
  String? _content;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchContent();
  }

  Future<void> _fetchContent() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(widget.endpoint);
      
      if (response.data['success'] == true) {
        setState(() {
          _content = response.data['content'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.data['message'] ?? 'Failed to load content';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: 120,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _error = null;
                              });
                              _fetchContent();
                            },
                            child: const Text('Retry'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: HtmlWidget(
                    _content ?? '',
                    textStyle: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: AppColors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
    );
  }
}
