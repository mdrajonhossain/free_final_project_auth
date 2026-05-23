import 'package:flutter/material.dart';

class MuteNotifications extends StatefulWidget {
  final bool alreadyMuted;
  final Function(bool) onMuteChanged;

  const MuteNotifications({
    super.key,
    required this.alreadyMuted,
    required this.onMuteChanged,
  });

  static void show(
    BuildContext context, {
    required bool alreadyMuted,
    required Function(bool) onMuteChanged,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => MuteNotifications(
        alreadyMuted: alreadyMuted,
        onMuteChanged: onMuteChanged,
      ),
    );
  }

  @override
  State<MuteNotifications> createState() => _MuteNotificationsState();
}

class _MuteNotificationsState extends State<MuteNotifications> {
  String selectedDuration = "20Y";
  late bool alreadyMuted;

  @override
  void initState() {
    super.initState();
    alreadyMuted = widget.alreadyMuted;
  }

  final List<Map<String, String>> muteOptions = [
    {"label": "Until I turn it back on", "value": "20Y"},
    {"label": "For 30 minutes", "value": "30M"},
    {"label": "For 1 Hour", "value": "1H"},
    {"label": "For 12 Hours", "value": "12H"},
    {"label": "For 1 Day", "value": "1D"},
    {"label": "For 1 Month", "value": "1M"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.6),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.90,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// HEADER
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Mute notification for this room",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white12),

              /// TITLE
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Please select one of the mute options.",
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
              ),

              /// OPTIONS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: muteOptions.map((option) {
                    final isSelected = selectedDuration == option["value"];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDuration = option["value"]!;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.withOpacity(0.15)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blueAccent
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            /// RADIO
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blueAccent
                                      : Colors.white38,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Text(
                                option["label"]!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 10),

              /// FOOTER BUTTONS
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    /// CANCEL
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    /// UNMUTE (optional)
                    if (alreadyMuted)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            widget.onMuteChanged(false);
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.15),
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            "Unmute",
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ),

                    if (alreadyMuted) const SizedBox(width: 10),

                    /// MUTE BUTTON
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onMuteChanged(true);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          alreadyMuted ? "Update" : "Mute",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
