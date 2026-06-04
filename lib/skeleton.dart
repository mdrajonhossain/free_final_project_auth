import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/theme/themeList.dart';
import 'package:freeli/theme/ThemeCubit.dart';

class ChatSkeleton extends StatelessWidget {
  final bool? isDark;
  const ChatSkeleton({super.key, this.isDark});

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeCubit>().state;
    final bool effectiveIsDark =
        isDark ?? (appTheme.backgroundColor.computeLuminance() < 0.5);

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 40, left: 16, right: 16),
      itemCount: 10, // Show 10 skeleton items
      itemBuilder: (context, index) {
        return Card(
          color: effectiveIsDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Avatar Skeleton
                CircleAvatar(
                  radius: 25,
                  backgroundColor: effectiveIsDark
                      ? Colors.white10
                      : Colors.black12,
                ),
                const SizedBox(width: 15),

                // Content Skeleton
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Skeleton
                      Container(
                        width: 120,
                        height: 12,
                        decoration: BoxDecoration(
                          color: effectiveIsDark
                              ? Colors.white10
                              : Colors.black12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtitle Skeleton
                      Container(
                        width: double.infinity,
                        height: 10,
                        decoration: BoxDecoration(
                          color: effectiveIsDark
                              ? Colors.white10
                              : Colors.black12,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),

                // Time Skeleton
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 10,
                      decoration: BoxDecoration(
                        color: effectiveIsDark
                            ? Colors.white10
                            : Colors.black12,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
