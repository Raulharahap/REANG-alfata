import 'package:flutter/material.dart';

class ProgressPembangunanView extends StatelessWidget {
  const ProgressPembangunanView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: theme.hintColor),
          const SizedBox(height: 16),
          Text(
            "Halaman Progress Pembangunan",
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            "Fitur ini sedang dalam pengembangan.",
            style: TextStyle(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}
