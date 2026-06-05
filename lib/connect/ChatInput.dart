import 'package:flutter/material.dart';
import 'package:freeli/connect/PopUpFile/EmojiPickerPopup.dart';
import 'package:freeli/connect/PopUpFile/attchmentPopup.dart';
import 'package:freeli/controller/stateBloc/message/chat_bloc.dart';
import 'package:freeli/theme/themeList.dart';
import 'package:freeli/theme/ThemeCubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import './mention_input.dart';
import './chat_service.dart';
import './PopUpFile/PrivateMessagePopUp.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final bool? isDark;
  final VoidCallback onSend;
  final String companyId;
  final String? userEmail;
  final String conversationId;
  final dynamic participants;
  final ChatBloc chatBloc;
  final Function(List<Map<String, dynamic>>) onAttachmentsPicked;
  final bool showAttachmentIcon;
  final bool group;
  final List<MentionUser> mentionableUsers;

  const ChatInput({
    super.key,
    required this.controller,
    this.isDark,
    required this.onSend,
    required this.companyId,
    required this.onAttachmentsPicked,
    required this.conversationId,
    required this.participants,
    required this.chatBloc,
    this.group = false,
    this.userEmail,
    this.mentionableUsers = const [],
    this.showAttachmentIcon = true,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  bool _showEmoji = false;
  final FocusNode _focusNode = FocusNode();

  void _toggleEmoji() {
    setState(() {
      _showEmoji = !_showEmoji;
    });

    if (_showEmoji) {
      _focusNode.unfocus();
    } else {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, AppThemeModel>(
      builder: (context, appTheme) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showEmoji)
              EmojiPickerView(
                controller: widget.controller,
                onClose: () => setState(() => _showEmoji = false),
              ),

            SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 14, 14),
                decoration: BoxDecoration(
                  color: appTheme.backgroundColor,
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.05)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            // LOCK ICON
                            widget.group
                                ? Row(
                                    children: [
                                      const SizedBox(width: 14),
                                      GestureDetector(
                                        onTap: () {
                                          PrivateMessagePopUp.show(
                                            context,
                                            companyId: widget.companyId,
                                            chatBloc: widget.chatBloc,
                                            userEmail: widget.userEmail,
                                            users: widget.mentionableUsers
                                                .where(
                                                  (u) => u.name != 'Everyone',
                                                )
                                                .map(
                                                  (u) => {
                                                    'name': u.name,
                                                    'image': u.imageUrl ?? '',
                                                    'id': u.id,
                                                  },
                                                )
                                                .toList(),
                                            onCreate:
                                                (
                                                  title,
                                                  recipientIds,
                                                  uploadedFiles,
                                                  tags,
                                                  message,
                                                ) {
                                                  List<String> imgFiles = [];
                                                  List<String> audioFiles = [];
                                                  List<String> videoFiles = [];
                                                  List<String> otherFiles = [];
                                                  List<Map<String, dynamic>>
                                                  sanitizedAllFiles = [];

                                                  for (var file
                                                      in uploadedFiles) {
                                                    final String bucket =
                                                        file['bucket'] ?? '';
                                                    final String key =
                                                        file['key'] ?? '';
                                                    final String path =
                                                        (bucket.isNotEmpty &&
                                                            key.isNotEmpty)
                                                        ? "$bucket/$key"
                                                        : "";

                                                    // Robust extraction of mimetype and size
                                                    String mimeType =
                                                        file['mimetype'] ??
                                                        file['contentType'] ??
                                                        '';
                                                    int fileSize =
                                                        int.tryParse(
                                                          file['size']
                                                                  ?.toString() ??
                                                              '0',
                                                        ) ??
                                                        0;

                                                    final transforms =
                                                        file['transforms']
                                                            as List?;
                                                    if (mimeType.isEmpty &&
                                                        transforms != null &&
                                                        transforms.isNotEmpty) {
                                                      mimeType =
                                                          transforms[0]['mimetype'] ??
                                                          transforms[0]['contentType'] ??
                                                          transforms[0]['content_type'] ??
                                                          '';
                                                    }
                                                    if (fileSize == 0 &&
                                                        transforms != null &&
                                                        transforms.isNotEmpty) {
                                                      fileSize =
                                                          int.tryParse(
                                                            transforms[0]['size']
                                                                    ?.toString() ??
                                                                '0',
                                                          ) ??
                                                          0;
                                                    }

                                                    if (mimeType.startsWith(
                                                      'image/',
                                                    )) {
                                                      imgFiles.add(path);
                                                    } else if (mimeType
                                                        .startsWith('audio/')) {
                                                      audioFiles.add(path);
                                                    } else if (mimeType
                                                        .startsWith('video/')) {
                                                      videoFiles.add(path);
                                                    } else {
                                                      otherFiles.add(path);
                                                    }

                                                    sanitizedAllFiles.add({
                                                      "originalname":
                                                          file['originalname'] ??
                                                          "",
                                                      "mimetype": mimeType,
                                                      "voriginalName":
                                                          file['voriginalName'] ??
                                                          file['voriginal_name'] ??
                                                          "",
                                                      "size": fileSize,
                                                      "bucket": bucket,
                                                      "key": key,
                                                      "acl":
                                                          file['acl'] ??
                                                          "public-read",
                                                      "referenceId": "",
                                                      "reference_type": "",
                                                    });
                                                  }

                                                  final attachFiles = {
                                                    "imgfile": imgFiles,
                                                    "audiofile": audioFiles,
                                                    "videofile": videoFiles,
                                                    "otherfile": otherFiles,
                                                    "allfiles":
                                                        sanitizedAllFiles,
                                                  };

                                                  final allAttachment =
                                                      sanitizedAllFiles
                                                          .map(
                                                            (_) => {
                                                              "tag_list": tags,
                                                              "has_tag":
                                                                  tags.isNotEmpty
                                                                  ? "Y"
                                                                  : "N",
                                                            },
                                                          )
                                                          .toList();

                                                  ChatService.sendMessage(
                                                    context: context,
                                                    controller:
                                                        TextEditingController(
                                                          text: message,
                                                        ),
                                                    conversationId:
                                                        widget.conversationId,
                                                    companyId: widget.companyId,
                                                    participants: [
                                                      widget
                                                          .chatBloc
                                                          .state
                                                          .myId,
                                                      ...recipientIds,
                                                    ],
                                                    chatBloc: widget.chatBloc,
                                                    onScroll: () {},
                                                    isSecret: true,
                                                    secretUsers: recipientIds,
                                                    msgTitle: title,
                                                    attachFiles:
                                                        uploadedFiles.isNotEmpty
                                                        ? attachFiles
                                                        : null,
                                                    tags: tags,
                                                    allAttachment: allAttachment
                                                        .cast<
                                                          Map<String, dynamic>
                                                        >(),
                                                  );
                                                },
                                          );
                                        },
                                        child: Container(
                                          height: 34,
                                          width: 34,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.08,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.lock_rounded,
                                            color: Colors.white.withOpacity(
                                              0.7,
                                            ),
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                  )
                                : const SizedBox(width: 18),

                            // TEXT FIELD
                            Expanded(
                              child: MentionTextField(
                                focusNode: _focusNode,
                                controller: widget.controller,
                                users: widget.mentionableUsers,
                                popupBackgroundColor: appTheme.cardColor,
                                onTap: () {
                                  if (_showEmoji) {
                                    setState(() => _showEmoji = false);
                                  }
                                },
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                                minLines: 1,
                                maxLines: 5,
                                decoration: const InputDecoration(
                                  hintText: "Message...",
                                  hintStyle: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 15,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),

                            // ATTACHMENT ICON
                            if (widget.showAttachmentIcon)
                              IconButton(
                                onPressed: () async {
                                  final results = await AttachmentPopup.show(
                                    context,
                                    userEmail: widget.userEmail,
                                    companyId: widget.companyId,
                                    conversationId: widget.conversationId,
                                    participants: widget.participants,
                                    chatBloc: widget.chatBloc,
                                  );

                                  if (results != null && results.isNotEmpty) {
                                    widget.onAttachmentsPicked(results);
                                  }
                                },
                                icon: Icon(
                                  Icons.attach_file_rounded,
                                  color: Colors.white.withOpacity(0.6),
                                  size: 22,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),

                            // EMOJI ICON
                            IconButton(
                              onPressed: _toggleEmoji,
                              icon: Icon(
                                _showEmoji
                                    ? Icons.keyboard_rounded
                                    : Icons.emoji_emotions_rounded,
                                color: _showEmoji
                                    ? const Color(0xff7C5CFF)
                                    : Colors.white.withOpacity(0.6),
                                size: 22,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),

                            const SizedBox(width: 4),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // SEND BUTTON
                    GestureDetector(
                      onTap: widget.onSend,
                      child: Container(
                        height: 54,
                        width: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: appTheme.accentColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
