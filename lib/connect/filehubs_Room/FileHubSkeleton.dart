import 'package:flutter/material.dart';

class FileHubSkeleton extends StatelessWidget {
  final bool isDark;
  final String type; // 'file', 'tag', or 'link'

  const FileHubSkeleton({super.key, required this.isDark, this.type = 'file'});

  @override
  Widget build(BuildContext context) {
    final Color shimmerColor =
        isDark // Color for the actual skeleton elements
        ? const Color(0xFF1B2945) // Darker blue-grey for dark mode
        : const Color(0xFFE0E0E0); // Light grey for light mode
    final Color highlightColor =
        isDark // Background color for the item container
        ? const Color(
            0xFF0F1B35,
          ) // Deeper, more professional blue for dark mode
        : const Color(0xFFF5F5F5); // Very light grey for light mode

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: 10, // Increased count for better initial fill
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: highlightColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: _buildUnifiedSkeletonItem(shimmerColor, type),
        );
      },
    );
  }

  Widget _buildUnifiedSkeletonItem(Color color, String itemType) {
    // Define common dimensions and border radii for a professional and consistent look
    const double leadingShapeSize = 44.0;
    const double trailingShapeSize = 24.0;
    const double commonBorderRadius = 12.0;
    const double textLineBorderRadius = 4.0;

    // Design is now identical for all types (file, tag, link)
    // to maintain a professional, unified interface.
    const BoxShape leadingShapeBoxShape = BoxShape.rectangle;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center, // Align items vertically in the center
      children: [
        // Leading placeholder shape (e.g., icon, avatar, tag indicator)
        Container(
          height: leadingShapeSize,
          width: leadingShapeSize,
          decoration: BoxDecoration(
            color: color,
            shape: leadingShapeBoxShape,
            borderRadius: BorderRadius.circular(commonBorderRadius),
          ),
        ),
        const SizedBox(
          width: 16,
        ), // Spacing between leading shape and text content
        // Main content area with two lines of text placeholders
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Primary text line placeholder
              Container(
                height: 16, // Height for the primary text line
                width: double.infinity, // Takes full available width
                margin: const EdgeInsets.only(
                  right: 50,
                ), // Makes it appear shorter than full width
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(textLineBorderRadius),
                ),
              ),
              const SizedBox(height: 10), // Precise spacing between text lines
              // Secondary text line placeholder
              Container(
                height: 11, // Slightly thinner secondary line
                width: 120, // Fixed width for metadata feel
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(textLineBorderRadius),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12), // Spacing before trailing shape
        // Trailing placeholder shape (e.g., action button, status indicator)
        Container(
          height: trailingShapeSize,
          width: trailingShapeSize,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape
                .circle, // Consistently a circle for the trailing element
          ),
        ),
      ],
    );
  }
}
