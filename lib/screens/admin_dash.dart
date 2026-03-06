import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_page.dart';

class AdminDash extends StatefulWidget {
  const AdminDash({super.key});

  @override
  State<AdminDash> createState() => _AdminDashState();
}

class _AdminDashState extends State<AdminDash> {
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  // ─── STAT CARD ────────────────────────────────────────────────────
  Widget _statCard({
    required String title,
    required String count,
    required IconData icon,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF2), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryColor, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            count,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color.fromARGB(255, 85, 89, 96),
              height: 1,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECTION HEADER ──────────────────────────────────────────────
  Widget _sectionHeader(String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECTION DIVIDER ─────────────────────────────────────────────
  Widget _sectionDivider() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    child: Divider(color: Color(0xFFE2E8F0), thickness: 1.5),
  );

  // ─── 2×2 STAT GRID ───────────────────────────────────────────────
  Widget _statGrid(List<Widget> cards) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 14),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 14),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0F265C), // Hive Solar dark navy blue
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => _logout(context),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo1.png',
              height: 32,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.solar_power,
                color: Color(0xFFEAB308),
                size: 28,
              ), // Hive Solar amber
            ),
            const SizedBox(width: 8),
            const Text(
              'Hive Solar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            onPressed: () => _logout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── GREETING BANNER ──────────────────────────────────
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Welcome back — here's today's overview.",
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ════════════════════════════════════════════════════
              //  SECTION 1 — AMC LIST
              // ════════════════════════════════════════════════════
              _sectionHeader(
                'AMC List',
                Icons.verified_rounded,
                const Color(0xFF3B82F6),
              ),

              // 4 stat tiles
              _statGrid([
                _statCard(
                  title: 'EXPIRING SOON',
                  count: '12',
                  icon: Icons.warning_amber_rounded,
                  primaryColor: const Color(0xFFF59E0B),
                  secondaryColor: const Color(0xFFFBBF24),
                ),
                _statCard(
                  title: 'ACTIVE AMC',
                  count: '119',
                  icon: Icons.check_circle_rounded,
                  primaryColor: const Color(0xFF10B981),
                  secondaryColor: const Color(0xFF34D399),
                ),
                _statCard(
                  title: 'EXPIRED',
                  count: '76',
                  icon: Icons.cancel_rounded,
                  primaryColor: const Color(0xFFEF4444),
                  secondaryColor: const Color(0xFFF87171),
                ),
                _statCard(
                  title: 'AMC DATABASE',
                  count: '58',
                  icon: Icons.dataset_rounded,
                  primaryColor: const Color(0xFF3B82F6),
                  secondaryColor: const Color(0xFF60A5FA),
                ),
              ]),

              _sectionDivider(),

              // ════════════════════════════════════════════════════
              //  SECTION 2 — COMPLAINTS & SUPPORT
              // ════════════════════════════════════════════════════
              _sectionHeader(
                'Complaints & Support',
                Icons.support_agent_rounded,
                const Color(0xFF6366F1),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        title: 'NEW',
                        count: '16',
                        icon: Icons.new_releases_rounded,
                        primaryColor: const Color(0xFF6366F1),
                        secondaryColor: const Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _statCard(
                        title: 'DELAYED',
                        count: '1',
                        icon: Icons.hourglass_bottom_rounded,
                        primaryColor: const Color(0xFFF97316),
                        secondaryColor: const Color(0xFFFBBF24),
                      ),
                    ),
                  ],
                ),
              ),

              _sectionDivider(),

              // ════════════════════════════════════════════════════
              //  SECTION 3 — SOLAR AMC LIST
              // ════════════════════════════════════════════════════
              _sectionHeader(
                'Solar AMC List',
                Icons.solar_power_rounded,
                const Color(0xFFF59E0B),
              ),

              // 4 stat tiles
              _statGrid([
                _statCard(
                  title: 'EXPIRING SOON',
                  count: '6',
                  icon: Icons.warning_amber_rounded,
                  primaryColor: const Color(0xFFF59E0B),
                  secondaryColor: const Color(0xFFFBBF24),
                ),
                _statCard(
                  title: 'ACTIVE AMC',
                  count: '689',
                  icon: Icons.check_circle_rounded,
                  primaryColor: const Color(0xFF10B981),
                  secondaryColor: const Color(0xFF34D399),
                ),
                _statCard(
                  title: 'EXPIRED',
                  count: '167',
                  icon: Icons.cancel_rounded,
                  primaryColor: const Color(0xFFEF4444),
                  secondaryColor: const Color(0xFFF87171),
                ),
                _statCard(
                  title: 'AMC DATABASE',
                  count: '5',
                  icon: Icons.dataset_rounded,
                  primaryColor: const Color(0xFF3B82F6),
                  secondaryColor: const Color(0xFF60A5FA),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
