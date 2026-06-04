import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/theme/ThemeCubit.dart';
import 'package:freeli/theme/themeList.dart';

class ChatSkeleton extends StatefulWidget {
  const ChatSkeleton({super.key});

  @override
  State<ChatSkeleton> createState() => _ChatSkeletonState();
}

class _ChatSkeletonState extends State<ChatSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(
      begin: 0.4,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, AppThemeModel>(
      builder: (context, theme) {
        final isDark = theme.backgroundColor.computeLuminance() < 0.5;
        final baseColor = isDark
            ? theme.cardColor.withOpacity(0.8)
            : Colors.grey.withOpacity(0.2);

        return Container(
          color: theme.backgroundColor,
          child: ListView.builder(
            itemCount: 8,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              bool isMe = index % 3 == 0; // Alternating pattern for me/other
              return FadeTransition(
                opacity: _opacityAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    mainAxisAlignment: isMe
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMe) ...[
                        CircleAvatar(radius: 18, backgroundColor: baseColor),
                        const SizedBox(width: 10),
                      ],
                      Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          // Name Placeholder
                          Container(
                            height: 10,
                            width: 60,
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          // Message Bubble Placeholder
                          Container(
                            height: 45,
                            width:
                                MediaQuery.of(context).size.width *
                                (index % 2 == 0 ? 0.6 : 0.45),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? theme.accentColor.withOpacity(0.2)
                                  : baseColor,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(isMe ? 18 : 4),
                                topRight: Radius.circular(isMe ? 4 : 18),
                                bottomLeft: const Radius.circular(18),
                                bottomRight: const Radius.circular(18),
                              ),
                              border: Border.all(
                                color: isDark ? Colors.white10 : Colors.black12,
                                width: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Time Placeholder
                          Container(
                            height: 8,
                            width: 35,
                            decoration: BoxDecoration(
                              color: baseColor.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 10),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.accentColor.withOpacity(0.15),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
