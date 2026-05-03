import 'package:flutter/material.dart';

class ChatSkeleton extends StatelessWidget {
  const ChatSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      itemCount: 8,
      itemBuilder: (context, index) {
        final bool isMe = index % 2 == 0;
        return Padding(
          padding: EdgeInsets.only(
            bottom: 18,
            right: isMe ? 10 : 0,
            left: isMe ? 0 : 10,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!isMe) _skeletonAvatar(),
              if (!isMe) const SizedBox(width: 10),
              _skeletonBubble(isMe, context),
              if (isMe) const SizedBox(width: 10),
              if (isMe) _skeletonAvatar(),
            ],
          ),
        );
      },
    );
  }

  Widget _skeletonAvatar() {
    return Container(
      height: 36,
      width: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _skeletonBubble(bool isMe, BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.6,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(22),
          topRight: const Radius.circular(22),
          bottomLeft: Radius.circular(isMe ? 22 : 6),
          bottomRight: Radius.circular(isMe ? 6 : 22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
