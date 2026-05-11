import 'package:flutter/material.dart';
import '../AppColors.dart';

class DirectMessagePopup {
  static void show(BuildContext context, List<dynamic>? conversationRooms) {
    String searchQuery = "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            final filteredList =
                conversationRooms?.where((room) {
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
                          "Direct message",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                        setPopupState(() => searchQuery = value);
                      },
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: "Search conversations...",
                        hintStyle: const TextStyle(color: Colors.black38),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.black45,
                        ),
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
                    child: filteredList.isEmpty
                        ? const Center(
                            child: Text(
                              "No results found",
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
                                          (room['title']?[0] ?? 'C')
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  room['title'] ?? "No Title",
                                  style: const TextStyle(color: Colors.black),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(
                                    context,
                                    '/chat',
                                    arguments: {
                                      'conversation_id':
                                          room['conversation_id'],
                                      'company_id': room['company_id'],
                                      'participants': room['participants'],
                                      'title': room['title'] ?? 'No Title',
                                      'conv_img': room['conv_img'],
                                    },
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
