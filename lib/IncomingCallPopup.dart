import 'package:flutter/material.dart';

class IncomingCallPopup extends StatelessWidget {
  final String callerName;
  final String callerImage;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final bool isVideoCall;

  const IncomingCallPopup({
    super.key,
    required this.callerName,
    required this.callerImage,
    required this.onAccept,
    required this.onDecline,
    this.isVideoCall = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * .88,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xff1E1E1E),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Profile Image
              Stack(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.grey.shade800,
                    backgroundImage: callerImage.isNotEmpty
                        ? NetworkImage(callerImage)
                        : null,
                    child: callerImage.isEmpty
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 40,
                          )
                        : null,
                  ),

                  /// online indicator
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              /// Incoming Text
              Text(
                isVideoCall ? "Incoming Video Call" : "Incoming Audio Call",
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              /// Caller Name
              Text(
                callerName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              /// Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  /// Decline
                  GestureDetector(
                    onTap: onDecline,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Decline",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  /// Accept
                  GestureDetector(
                    onTap: onAccept,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isVideoCall ? Icons.videocam : Icons.call,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Accept",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
