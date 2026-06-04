import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/theme/themeList.dart';
import 'package:freeli/theme/ThemeCubit.dart';

class DirectMessagePopup {
  static void show(
    BuildContext context,
    List<dynamic>? conversationRooms, {
    required bool isDark,
  }) {
    String searchQuery = "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return BlocBuilder<ThemeCubit, AppThemeModel>(
          builder: (context, appTheme) {
            final textColor = appTheme.textColor;
            final subTextColor = appTheme.subTextColor;
            final bgColor = appTheme.backgroundColor;

            return StatefulBuilder(
              builder: (context, setPopupState) {
                final filteredList =
                    conversationRooms?.where((room) {
                      final title =
                          room['title']?.toString().toLowerCase() ?? "";
                      return title.contains(searchQuery.toLowerCase());
                    }).toList() ??
                    [];

                return Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
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
                            Text(
                              "Direct message",
                              style: TextStyle(
                                color: textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.close, color: subTextColor),
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
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: "Search conversations...",
                            hintStyle: TextStyle(
                              color: subTextColor.withOpacity(0.5),
                            ),
                            prefixIcon: Icon(Icons.search, color: subTextColor),
                            filled: true,
                            fillColor: textColor.withOpacity(0.05),
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
                            ? Center(
                                child: Text(
                                  "No results found",
                                  style: TextStyle(color: subTextColor),
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
                                      backgroundColor: appTheme.accentColor,
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
                                      style: TextStyle(color: textColor),
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
      },
    );
  }
}
