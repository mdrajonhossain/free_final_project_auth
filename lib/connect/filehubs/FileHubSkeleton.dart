import 'package:flutter/material.dart';

class FileHubSkeleton extends StatelessWidget {
  final bool isDark;
  final String type; // 'file', 'tag', or 'link'

  const FileHubSkeleton({super.key, required this.isDark, this.type = 'file'});

  @override
  Widget build(BuildContext context) {
    final Color shimmerColor = isDark
        ? const Color(0xFF1B2945)
        : Colors.grey.withOpacity(0.1);
    final Color highlightColor = isDark
        ? const Color(0xFF132850)
        : Colors.grey.withOpacity(0.05);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: highlightColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: _buildSkeletonItem(shimmerColor),
        );
      },
    );
  }

  Widget _buildSkeletonItem(Color color) {
    if (type == 'tag') {
      return Row(
        children: [
          Container(
            height: 14,
            width: 14,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 120, color: color),
                const SizedBox(height: 6),
                Container(height: 10, width: 80, color: color),
              ],
            ),
          ),
          Container(height: 16, width: 16, color: color),
        ],
      );
    } else if (type == 'link') {
      return Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: Container(height: 14, color: color)),
          const SizedBox(width: 10),
          Expanded(flex: 5, child: Container(height: 12, color: color)),
          const SizedBox(width: 10),
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      );
    } else {
      // Default 'file' skeleton
      return Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 15, width: 150, color: color),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(height: 10, width: 40, color: color),
                    const SizedBox(width: 10),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(height: 10, width: 60, color: color),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      );
    }
  }
}
