import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/AppColors.dart';
import 'package:freeli/controller/api/api_service.dart';
import 'package:freeli/controller/stateBloc/message/chat_bloc.dart';

class PublicTag extends StatefulWidget {
  final Map<String, dynamic> messageToForward;

  const PublicTag({super.key, required this.messageToForward});

  @override
  State<PublicTag> createState() => _PublicTagState();
}

class _PublicTagState extends State<PublicTag> {
  String searchQuery = "";
  final Set<String> _selectedTagIds = {};
  List<Map<String, dynamic>>? _availableTags;
  bool _isLoading = true;
  bool _isSaving = false;
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
      final tags = await ApiServer().fetch_Public_Tags(
        widget.messageToForward['company_id']?.toString(),
      );
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

  void _handleApply() {
    // Implementation for applying tags.
    // This typically returns the selected tags to the caller.
    Navigator.pop(context, _selectedTagIds.toList());
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
                if (_selectedTagIds.isNotEmpty)
                  TextButton.icon(
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
                      final String tagId = tag['tag_id']?.toString() ?? "";
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
