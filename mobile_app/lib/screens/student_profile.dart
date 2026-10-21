import 'package:flutter/material.dart';
import '../services/order_manager.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import 'role_selection.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderManager = OrderManager();
    final session = SessionService();
    // One shared impact formula (ImpactStats) — the Pickups screen used a
    // different one, so the same rescue showed two different CO₂ numbers.
    final impact = orderManager.impact;
    final displayName = session.name ?? 'SaveBite Student';
    final displayEmail = session.email ?? 'Not signed in';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Impact & Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF006C5B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Switch Mode',
            icon: const Icon(Icons.swap_horiz_rounded),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Student Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFF006C5B).withValues(alpha: 0.12),
                    child: const Icon(Icons.person_rounded, size: 36, color: Color(0xFF006C5B)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayEmail,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          // Badge is earned, not decorative: it appears once a
                          // student has actually rescued their first box.
                          child: Text(
                            impact.mealsRescued > 0
                                ? "🎓 Campus Food Hero"
                                : "🌱 Ready to rescue food",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Eco Impact Dashboard
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF006C5B), Color(0xFF0A8A76)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF006C5B).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.eco_rounded, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "Your Food Rescue Impact",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Together with local shops, you are diverting surplus food from landfills.",
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildImpactItem("🌱", "${impact.mealsRescued}", "Meals\nRescued"),
                      Container(height: 40, width: 1, color: Colors.white.withValues(alpha: 0.2)),
                      _buildImpactItem("💰", "₹${impact.moneySaved.toStringAsFixed(0)}", "Money\nSaved"),
                      Container(height: 40, width: 1, color: Colors.white.withValues(alpha: 0.2)),
                      _buildImpactItem("🌍", "${impact.co2AvoidedKg}kg", "CO₂\nAvoided"),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Navigation & Quick Settings
            // NOTE: the old "Switch to Vendor Mode" tile let any student open the
            // vendor portal. A vendor account now comes from the server token, so
            // there is nothing to switch into from here.
            _buildActionTile(
              icon: Icons.radar_rounded,
              title: "Geofence Notifications",
              subtitle: "Alerts enabled for shops within 2.0 km",
              color: const Color(0xFF006C5B),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Geofence notifications active for 2km campus radius.")),
                );
              },
            ),

            _buildActionTile(
              icon: Icons.logout_rounded,
              title: "Sign Out",
              subtitle: "End this session on this device",
              color: Colors.redAccent,
              onTap: () async {
                await ApiService.signOut();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
              },
            ),

            _buildActionTile(
              icon: Icons.info_outline_rounded,
              title: "How Mystery Box Works",
              subtitle: "Surplus rescue rules, decay pricing & pickups",
              color: Colors.blueGrey,
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: "Mystery Box Food Rescue",
                  applicationVersion: "1.0.0 (Phase 1)",
                  children: const [
                    Text("• Hyperlocal food rescue connecting campus students with nearby food stores."),
                    SizedBox(height: 6),
                    Text("• Dynamic Decay Pricing: Food prices automatically decay as store closing time approaches."),
                    SizedBox(height: 6),
                    Text("• Atomic 5-Minute Locks: Real-time inventory locks prevent double-booking surplus."),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      ),
    );
  }
}
