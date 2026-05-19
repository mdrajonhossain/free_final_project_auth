import 'package:flutter/material.dart';
import '../controller/api/api_service.dart';
import '../skeleton.dart';
import 'format_utils.dart';
import 'jitsi_call_service.dart';
import '../AppColors.dart';

class CallsTab extends StatefulWidget {
  final String? userId;
  final String? companyId;
  final bool isDark;

  const CallsTab({super.key, this.userId, this.companyId, this.isDark = true});

  @override
  State<CallsTab> createState() => _CallsTabState();
}

class _CallsTabState extends State<CallsTab> {
  bool isLoading = true;

  List<dynamic> callHistory = [];
  Map<String, dynamic>? myProfile;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    try {
      final profile = await ApiServer().fetchMe();
      setState(() => myProfile = profile);
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
    await getCallHistory();
  }

  Future<void> getCallHistory() async {
    try {
      final data = await ApiServer().fetchCallHistory(
        widget.userId,
        companyId: widget.companyId,
      );
      if (mounted) {
        setState(() {
          callHistory = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      debugPrint("Error fetching call history: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(widget.isDark),
      body: isLoading
          ? const ChatSkeleton()
          : callHistory.isEmpty
          ? const Center(
              child: Text(
                "No call history yet",
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async => getCallHistory(),
              color: Colors.greenAccent,
              backgroundColor: const Color(0xff1B2335),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                itemCount: callHistory.length,
                itemBuilder: (context, index) {
                  final room = callHistory[index];
                  final String conversationId = (room['conversation_id'] ?? '')
                      .toString();
                  final String title = (room['conv_title'] ?? 'No Title')
                      .toString();
                  final String imageUrl = (room['conv_img'] ?? '').toString();
                  final String createdAt = (room['created_at'] ?? '')
                      .toString();
                  final String callDuration = (room['call_duration'] ?? '00:00')
                      .toString();
                  final bool isRunning = room['call_running'] == true;
                  final String callType = (room['msg_type'] ?? 'audio')
                      .toString();
                  final String callStatus = (room['call_status'] ?? '')
                      .toString()
                      .toLowerCase();

                  // Professional status color and icon logic
                  Color statusColor = Colors.white38;
                  IconData statusIcon = Icons.call_received;

                  if (isRunning) {
                    statusColor = Colors.greenAccent;
                    statusIcon = Icons.call_made_rounded;
                  } else if (callStatus.contains('missed')) {
                    statusColor = Colors.redAccent;
                    statusIcon = Icons.call_missed_rounded;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: ListTile(
                      onTap: conversationId.isEmpty
                          ? null
                          : () {
                              JitsiCallService.joinCall(
                                context: context,
                                userId: widget.userId,
                                companyId: widget.companyId,
                                conversationId: conversationId,
                                conversationType: callType,
                                participants:
                                    (room['participants'] as List?)?.toList() ??
                                    [],
                                roomTitle: title,
                                userName: myProfile?['firstname'],
                                userEmail: myProfile?['email'],
                                userAvatar: myProfile?['img'],
                                isVideo: callType == "accept",
                                onCallFinished: () => getCallHistory(),
                              );
                            },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white10,
                            backgroundImage: imageUrl.isNotEmpty
                                ? NetworkImage(imageUrl)
                                : null,
                            child: imageUrl.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    color: Colors.white24,
                                    size: 28,
                                  )
                                : null,
                          ),
                          if (isRunning)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xff0B1120),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 6),
                            Text(
                              "${callStatus.toUpperCase()} • $callDuration",
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(
                            callType == "accept"
                                ? Icons.videocam_rounded
                                : Icons.call_rounded,
                            color: isRunning
                                ? Colors.greenAccent
                                : Colors.white24,
                            size: 24,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            FormatUtils.formatTime(createdAt),
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
