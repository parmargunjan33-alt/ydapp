// lib/core/widgets/search_bar_widget.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppSearchBar extends StatefulWidget {
  final String hint;
  final void Function(String) onChanged;

  const AppSearchBar({
    super.key,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search_rounded,
            color: AppColors.textSecondary),
        suffixIcon: _ctrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.textSecondary),
                onPressed: () {
                  _ctrl.clear();
                  widget.onChanged('');
                },
              )
            : null,
      ),
    );
  }
}
