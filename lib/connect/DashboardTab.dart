import 'package:flutter/material.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Dashboard",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 15),

          Text(
            "Manage your chats, calls, and analytics from here.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),

          SizedBox(height: 20),

          Text(
            "• Total Users: 120\n• Active Chats: 45\n• Calls Today: 18",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
