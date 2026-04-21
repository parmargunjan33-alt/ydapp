import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.collections_bookmark_rounded, size: 64, color: AppColors.textHint.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'Your downloaded materials will appear here.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              '(Coming Soon)',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
