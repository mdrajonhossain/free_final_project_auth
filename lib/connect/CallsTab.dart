import 'package:flutter/material.dart';

class CallsTab extends StatelessWidget {
  const CallsTab({super.key});

  final List<Map<String, String>> calls = const [
    {"name": "John Doe", "time": "10:30 AM"},
    {"name": "Sarah Khan", "time": "Yesterday"},
    {"name": "Alex Smith", "time": "2 days ago"},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: calls.length,
      itemBuilder: (context, index) {
        return Card(
          color: Colors.green.withOpacity(
            0.1,
          ), // Green background for list items
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.call,
              color: Colors.greenAccent,
            ), // Green accent for call icon
            title: Text(
              calls[index]["name"]!,
              style: const TextStyle(
                color: Colors.white,
              ), // White text for visibility
            ),
            subtitle: Text(
              calls[index]["time"]!,
              style: const TextStyle(
                color: Colors.white70,
              ), // Lighter text for visibility
            ),
            trailing: const Icon(
              Icons.phone,
              color: Colors.white54,
            ), // Lighter icon for visibility
          ),
        );
      },
    );
  }
}
