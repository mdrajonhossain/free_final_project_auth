import 'package:flutter/material.dart';

class MentionUser {
  final String id;
  final String name;
  final String? imageUrl;

  MentionUser({required this.id, required this.name, this.imageUrl});
}

class MentionTextField extends StatefulWidget {
  final List<MentionUser> users;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextStyle? style;
  final Function(String)? onSubmitted;
  final Color? popupBackgroundColor;
  final int? minLines;
  final int? maxLines;
  final VoidCallback? onTap;

  const MentionTextField({
    super.key,
    required this.users,
    required this.controller,
    this.focusNode,
    this.decoration,
    this.style,
    this.onSubmitted,
    this.popupBackgroundColor,
    this.minLines,
    this.maxLines,
    this.onTap,
  });

  @override
  State<MentionTextField> createState() => _MentionTextFieldState();
}

class _MentionTextFieldState extends State<MentionTextField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<MentionUser> _filteredUsers = [];
  int _mentionStartIndex = -1;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant MentionTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
    // If the users list updates while the mention logic is active, re-trigger filtering
    if (widget.users != oldWidget.users && _mentionStartIndex != -1) {
      _onTextChanged();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _hideOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (!selection.isValid || !selection.isCollapsed) {
      _hideOverlay();
      return;
    }

    final cursorPosition = selection.baseOffset;
    if (cursorPosition == 0) {
      _hideOverlay();
      return;
    }

    final textBeforeCursor = text.substring(0, cursorPosition);

    // Look for '@' that is either at the start or preceded by whitespace

    // কার্সারের আগে সবথেকে কাছের '@' খুঁজে বের করা
    int lastAtIndex = -1;
    for (int i = cursorPosition - 1; i >= 0; i--) {
      if (text[i] == '@') {
        // চেক করা হচ্ছে '@' মেসেজের শুরুতে কি না অথবা এর আগে স্পেস/নিউলাইন আছে কি না
        if (i == 0 || RegExp(r'\s').hasMatch(text[i - 1])) {
          lastAtIndex = i;
          break;
        }
        if (RegExp(r'\s').hasMatch(text[i])) break;
      }
      // যদি '@' পাওয়ার আগে স্পেস পাওয়া যায়, তবে মেনশন বন্ধ
      if (RegExp(r'\s').hasMatch(text[i])) break;
    }

    if (lastAtIndex != -1) {
      final query = textBeforeCursor.substring(lastAtIndex + 1);
      if (!RegExp(r'\s').hasMatch(query)) {
        _mentionStartIndex = lastAtIndex;
        _filterUsers(query);
        return;
      }
    }

    _hideOverlay();
  }

  void _filterUsers(String query) {
    final filtered = widget.users
        .where((user) => user.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    setState(() {
      _filteredUsers = filtered;
    });

    if (_filteredUsers.isNotEmpty) {
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  void _showOverlay() {
    if (!mounted) return;

    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 280, // Matches the UI width for the popup
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          followerAnchor: Alignment.bottomLeft,
          targetAnchor: Alignment.topLeft,
          offset: const Offset(
            -15,
            -10,
          ), // Shifted left to remove the gap and up for better spacing
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            color: widget.popupBackgroundColor ?? Theme.of(context).cardColor,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _filteredUsers.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Colors.white10),
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundImage: user.imageUrl != null
                          ? NetworkImage(user.imageUrl!)
                          : null,
                      child: user.imageUrl == null
                          ? Text(
                              user.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      user.name,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                    onTap: () => _addMention(user),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _addMention(MentionUser user) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final cursorPosition = selection.baseOffset;

    final textBeforeMention = text.substring(0, _mentionStartIndex);
    final textAfterCursor = text.substring(cursorPosition);

    final newText = "$textBeforeMention@${user.name} $textAfterCursor";

    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset:
            textBeforeMention.length + user.name.length + 2, // @ এবং স্পেস সহ
      ),
    );

    _hideOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        style: widget.style,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        onTap: widget.onTap,
        decoration:
            widget.decoration ??
            const InputDecoration(
              hintText: "Type @ to mention...",
              border: OutlineInputBorder(),
            ),
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}
