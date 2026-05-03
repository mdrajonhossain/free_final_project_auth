import 'package:flutter/material.dart';

class ChatSkeleton extends StatefulWidget {
  const ChatSkeleton({super.key});

  @override
  State<ChatSkeleton> createState() => _ChatSkeletonState();
}

class _ChatSkeletonState extends State<ChatSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final Color bg = const Color(0xff0B1120);
  final Color surface = const Color(0xff111827);
  final Color bubble = const Color(0xff1F2937);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),

            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                itemCount: 10,
                itemBuilder: (context, index) {
                  final bool isMe = index % 2 == 0;
                  return _message(isMe);
                },
              ),
            ),

            _input(),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: surface,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          _box(40, 40, 14),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_box(12, 120, 6), const SizedBox(height: 8)],
            ),
          ),
        ],
      ),
    );
  }

  // ================= MESSAGE =================

  Widget _message(bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[_box(36, 36, 100), const SizedBox(width: 10)],

          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe) _box(10, 70, 5),
                if (!isMe) const SizedBox(height: 6),

                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.70,
                  ),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xff2B2F55) : bubble,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 6),
                      bottomRight: Radius.circular(isMe ? 6 : 20),
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _box(12, double.infinity, 6),
                      const SizedBox(height: 10),
                      _box(12, 140, 6),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: _box(10, 50, 6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (isMe) ...[const SizedBox(width: 10), _box(36, 36, 100)],
        ],
      ),
    );
  }

  // ================= INPUT =================

  Widget _input() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: bubble,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _box(12, 100, 6),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          _box(52, 52, 16),
        ],
      ),
    );
  }

  // ================= SHIMMER BOX =================

  Widget _box(double h, double w, double r) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            height: h,
            width: w,
            color: bubble,
            child: FractionallySizedBox(
              alignment: Alignment(-1 + (_controller.value * 2), 0),
              widthFactor: 0.35,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.02),
                      Colors.white.withOpacity(0.10),
                      Colors.white.withOpacity(0.02),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
