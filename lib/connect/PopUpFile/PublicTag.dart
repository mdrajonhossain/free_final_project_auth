import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/AppColors.dart';
import 'package:freeli/controller/api/api_service.dart';
import 'package:freeli/controller/stateBloc/message/chat_bloc.dart';

class PublicTag extends StatefulWidget {
  final Map<String, dynamic> tagList;

  const PublicTag({super.key, required this.tagList});

  @override
  State<PublicTag> createState() => _PublicTagState();
}

class _PublicTagState extends State<PublicTag> {
  String searchQuery = "";
  final Set<String> _selectedTagIds = {};
  final Set<String> _initialSelectedTagIds = {}; // To track original selections
  List<Map<String, dynamic>>? _availableTags;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    getpublictag();
  }

  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return const Color(0xff7C5CFF);
    try {
      return Color(int.parse(hexColor.replaceAll('#', '0xff')));
    } catch (e) {
      return const Color(0xff7C5CFF);
    }
  }

  Future<void> getpublictag() async {
    try {
      final String? companyId = widget.tagList['company_id']?.toString();
      if (companyId == null || companyId.isEmpty) {
        throw Exception("Company ID is missing for fetching public tags.");
      }
      final tags = await ApiServer().fetch_Public_Tags(companyId);

      // Safely extract and pre-select current tags
      final dynamic rawCurrentTags = widget.tagList is Map
          ? widget.tagList['tagList']
          : null;
      if (rawCurrentTags is List) {
        for (var item in rawCurrentTags) {
          if (item is Map) {
            final String? id = item['tag_id']?.toString().trim();
            if (id != null && id.isNotEmpty) {
              _selectedTagIds.add(id);
              _initialSelectedTagIds.add(id); // Store initial selection
            }
          } else if (item is String) {
            _selectedTagIds.add(item.trim());
            _initialSelectedTagIds.add(item.trim()); // Store initial selection
          }
        }
      }

      // Sort available tags: Selected tags go to the top
      if (tags is List) {
        tags.sort((dynamic a, dynamic b) {
          final String aId = (a is Map)
              ? (a['tag_id']?.toString().trim() ?? "")
              : "";
          final String bId = (b is Map)
              ? (b['tag_id']?.toString().trim() ?? "")
              : "";

          final bool aSelected = _selectedTagIds.contains(aId);
          final bool bSelected = _selectedTagIds.contains(bId);
          if (aSelected && !bSelected) return -1;
          if (!aSelected && bSelected) return 1;
          return 0;
        });
      }

      setState(() {
        _availableTags = tags;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _sanitizeTags(List<Map<String, dynamic>> tags) {
    return tags
        .map(
          (tag) => {
            'tag_id': tag['tag_id']?.toString().trim(),
            'tagged_by': tag['tagged_by']?.toString(),
            'title': tag['title']?.toString(),
            'company_id': tag['company_id']?.toString(),
            'type': tag['type']?.toString(),
            'tag_type': tag['tag_type']?.toString(),
            'tag_color': tag['tag_color']?.toString(),
          },
        )
        .toList();
  }

  void _handleApply() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final String conversationId =
          widget.tagList['conversation_id']?.toString() ?? '';
      final String fileId = widget.tagList['file_id']?.toString() ?? '';
      final String msgId = widget.tagList['msg_id']?.toString() ?? '';
      final String isReply = widget.tagList['is_reply']?.toString() ?? 'no';
      final dynamic rawParticipants = widget.tagList['participants'];
      final List<String> participants = (rawParticipants is List)
          ? List<String>.from(rawParticipants.map((p) => p.toString()))
          : (rawParticipants != null ? [rawParticipants.toString()] : []);

      // Calculate tags to add and remove (IDs only)
      Set<String> currentSelectedIds = Set.from(_selectedTagIds);
      Set<String> initialSelectedIds = Set.from(_initialSelectedTagIds);

      List<String> tagsToAddIds = currentSelectedIds
          .difference(initialSelectedIds)
          .toList();
      List<String> tagsToRemoveIds = initialSelectedIds
          .difference(currentSelectedIds)
          .toList();

      // Get full tag data for newtag_tag_data and removetag_tag_data
      List<Map<String, dynamic>> newTagData = [];
      List<Map<String, dynamic>> removeTagData = [];

      if (_availableTags != null) {
        newTagData = _availableTags!
            .where((tag) => tagsToAddIds.contains(tag['tag_id']?.toString()))
            .toList();
        removeTagData = _availableTags!
            .where((tag) => tagsToRemoveIds.contains(tag['tag_id']?.toString()))
            .toList();
      }

      final Map<String, dynamic> response = await ApiServer()
          .addRemoveTagIntoFile(
            conversationId: conversationId,
            fileId: fileId,
            isReply: isReply,
            msgId: msgId,
            newTags: tagsToAddIds,
            newTagData: _sanitizeTags(newTagData),
            removetag: tagsToRemoveIds,
            removetagData: _sanitizeTags(removeTagData),
            participants: participants,
          );

      print("88888888888888888888 $response");

      if (mounted) {
        if (response['status'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? "Tags updated successfully!",
              ),
            ),
          );
          context.read<ChatBloc>().add(
            ChatMessageTagsUpdated(
              conversationId: conversationId,
              msgId: msgId,
              fileId: fileId,
              newTagIds: _selectedTagIds.map((id) => id.trim()).toList(),
              newTagDetails:
                  _availableTags
                      ?.where(
                        (tag) =>
                            _selectedTagIds.contains(tag['tag_id']?.toString()),
                      )
                      .toList() ??
                  [],
            ),
          );
          Navigator.pop(context); // Close the popup on success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? "Failed to update tags."),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update tags: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList =
        _availableTags?.where((tag) {
          final title = tag['title']?.toString().toLowerCase() ?? "";
          return title.contains(searchQuery.toLowerCase());
        }).toList() ??
        [];

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    "Assign tag(s) to the file",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_hasChanges)
                  TextButton.icon(
                    // Enable button only if there are changes
                    onPressed: _isSaving ? null : _handleApply,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text("Apply (${_selectedTagIds.length})"),
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
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 10),
            child: TextField(
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: "Search tags...",
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
                      "No tags found",
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredList.length,
                    padding: const EdgeInsets.only(top: 5, bottom: 20),
                    itemBuilder: (context, index) {
                      final tag = filteredList[index];
                      final String title =
                          tag['title']?.toString() ?? "No Title";
                      final String tagId =
                          tag['tag_id']?.toString().trim() ?? "";
                      final Color tagColor = _parseColor(
                        tag['tag_color']?.toString(),
                      );
                      final bool isSelected = _selectedTagIds.contains(tagId);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 2,
                        ),
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundColor: tagColor,
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(color: Colors.black),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Colors.blue)
                            : const Icon(
                                Icons.circle_outlined,
                                color: Colors.grey,
                              ),
                        onTap: () {
                          if (tagId.isNotEmpty) {
                            setState(() {
                              if (isSelected) {
                                _selectedTagIds.remove(tagId);
                              } else {
                                _selectedTagIds.add(tagId);
                              }
                              _hasChanges =
                                  _selectedTagIds
                                      .difference(_initialSelectedTagIds)
                                      .isNotEmpty ||
                                  _initialSelectedTagIds
                                      .difference(_selectedTagIds)
                                      .isNotEmpty;
                            });
                          }
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
