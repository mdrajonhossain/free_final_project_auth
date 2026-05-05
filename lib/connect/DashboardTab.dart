import 'package:flutter/material.dart';

class DashboardTab extends StatelessWidget {
  final Map<String, dynamic>? userMe;

  const DashboardTab({super.key, this.userMe});

  String get fullName {
    final first = userMe?['firstname'] ?? '';
    final last = userMe?['lastname'] ?? '';
    final name = "$first $last".trim();
    return name.isEmpty ? "User" : name;
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFF0B1B3A);
    const Color card = Color(0xFF142A55);
    const Color card2 = Color(0xFF1A3470);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Title("Recent Activity"),

              const SizedBox(height: 12),

              /// ================= LIST CARDS =================
              _ActivityCard(
                title: "New file uploaded",
                subtitle: "Project_report.pdf",
                icon: Icons.upload_file,
              ),

              _ActivityCard(
                title: "Task completed",
                subtitle: "UI redesign finished",
                icon: Icons.check_circle,
              ),

              _ActivityCard(
                title: "New comment",
                subtitle: "Client feedback received",
                icon: Icons.comment,
              ),

              const SizedBox(height: 22),

              const _Title("Modules"),

              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _Module(icon: Icons.task_alt, title: "Tasks", onTap: () {}),
                  _Module(
                    icon: Icons.folder,
                    title: "FileHub",
                    onTap: () {
                      Navigator.pushNamed(context, '/filehuball');
                    },
                  ),
                  _Module(
                    icon: Icons.bar_chart,
                    title: "Analytics",
                    onTap: () {},
                  ),
                  _Module(
                    icon: Icons.settings,
                    title: "Settings",
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ================= TITLE =================
class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// ================= STAT CARD =================
class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const _StatCard({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    const Color card = Color(0xFF142A55);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ================= ACTIVITY CARD =================
class _ActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ActivityCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const Color card = Color(0xFF142A55);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ================= MODULE =================
class _Module extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _Module({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const Color card = Color(0xFF142A55);

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
