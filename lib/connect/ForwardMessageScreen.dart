import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../AppColors.dart';
import '../controller/stateBloc/message/chat_bloc.dart';
import '../connect/crypto_utils.dart';
import '../controller/api/api_service.dart'; // Ensure ApiServer is accessible

class ForwardMessageScreen extends StatefulWidget {
  final Map<String, dynamic> messageToForward;

  const ForwardMessageScreen({super.key, required this.messageToForward});

  @override
  State<ForwardMessageScreen> createState() => _ForwardMessageScreenState();
}

class _ForwardMessageScreenState extends State<ForwardMessageScreen> {
  String searchQuery = "";
  final Set<String> _selectedConversationIds = {};
  List<dynamic>? _conversationRooms;
  bool _isLoading = true;
  bool _isForwarding = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    try {
      final myId = context.read<ChatBloc>().state.myId;
      if (myId.isEmpty) throw Exception("User ID not found");

      final apiService = ApiServer();
      final data = await apiService.fetchRooms(myId);
      setState(() {
        _conversationRooms = data['rooms'] as List?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleForward() async {
    if (_selectedConversationIds.isEmpty) return;

    setState(() => _isForwarding = true);
    final apiService = ApiServer();

    final originalMsgId =
        widget.messageToForward['msg_id']?.toString() ??
        widget.messageToForward['id']?.toString();
    final originalConversationId = widget.messageToForward['conversation_id']
        ?.toString();

    final isReplyVal = widget.messageToForward['is_reply_msg'];
    final String isReplyMsg = (isReplyVal == true || isReplyVal == 'yes')
        ? 'yes'
        : 'no';

    if (originalMsgId == null || originalConversationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to get message details.")),
      );
      setState(() => _isForwarding = false);
      return;
    }

    try {
      await apiService.forwardMessage(
        originalConversationId: originalConversationId,
        msgId: originalMsgId,
        isReplyMsg: isReplyMsg,
        targetConversationIds: _selectedConversationIds.toList(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Message forwarded to ${_selectedConversationIds.length} conversations!",
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to forward: ${e.toString()}")),
        );
        setState(() => _isForwarding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList =
        _conversationRooms?.where((room) {
          final title = room['title']?.toString().toLowerCase() ?? "";
          return title.contains(searchQuery.toLowerCase());
        }).toList() ??
        [];

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Forward message",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedConversationIds.isNotEmpty)
                  TextButton.icon(
                    onPressed: _isForwarding ? null : _handleForward,
                    icon: _isForwarding
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text("Forward (${_selectedConversationIds.length})"),
                  )
                else
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.black54),
                  ),
              ],
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: "Search conversations...",
                hintStyle: const TextStyle(color: Colors.black38),
                prefixIcon: const Icon(Icons.search, color: Colors.black45),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Text(
                      "Error: $_error",
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : filteredList.isEmpty
                ? const Center(
                    child: Text(
                      "No conversations found",
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final room = filteredList[index];
                      final String imageUrl =
                          (room['conv_img'] ??
                                  room['img'] ??
                                  room['image'] ??
                                  '')
                              .toString();
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.accentColor,
                          backgroundImage: imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl)
                              : null,
                          child: imageUrl.isEmpty
                              ? Text(
                                  (room['title']?[0] ?? 'C').toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        title: Text(
                          room['title'] ?? "No Title",
                          style: const TextStyle(color: Colors.black),
                        ),
                        trailing:
                            _selectedConversationIds.contains(
                              room['conversation_id'].toString(),
                            )
                            ? const Icon(Icons.check_circle, color: Colors.blue)
                            : const Icon(
                                Icons.circle_outlined,
                                color: Colors.grey,
                              ),
                        onTap: () {
                          final id = room['conversation_id'].toString();
                          setState(() {
                            if (_selectedConversationIds.contains(id)) {
                              _selectedConversationIds.remove(id);
                            } else {
                              _selectedConversationIds.add(id);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
