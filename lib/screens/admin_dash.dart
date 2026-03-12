import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/api_services.dart';
import '../models/amc_status_model.dart';
import '../models/support_stats_model.dart';
import '../models/solar_amc_model.dart';
import 'login_page.dart';
import 'details/amc_list_page.dart';
import 'details/solaramc_list_page.dart';
import 'details/complaints_list_page.dart';

class AdminDash extends StatefulWidget {
  const AdminDash({super.key});

  @override
  State<AdminDash> createState() => _AdminDashState();
}

class _AdminDashState extends State<AdminDash> {
  late final Future<AmcStatusModel> amcData;
  late final Future<SupportStatsModel> supportData;
  late final Future<SolarAmcModel> solarAmcData;

  // ✅ Fetch all docs, filter isdeleted in Dart
  // — avoids Firestore missing-field issue (no index, matches Angular logic)
  Future<SupportStatsModel> _fetchSupportStats() async {
    final snap = await FirebaseFirestore.instance
        .collection('amccomplaints-list')
        .get();

    final rawList = snap.docs
        .map((d) => d.data())
        .where((d) => d['isdeleted'] != true)
        .toList();

    return SupportStatsModel.fromRecords(rawList);
  }

  @override
  void initState() {
    super.initState();
    amcData = ApiService.getAmcStatusCounts();
    supportData = _fetchSupportStats();
    solarAmcData = ApiService.getSolarAmcStatusCounts();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1B2B5E),
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _openAmcList(AmcFilter filter) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AmcListPage(filter: filter)),
    );
  }

  void _openSolarAmcList(SolarAmcFilter filter) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SolarAmcListPage(filter: filter)),
    );
  }

  void _openComplaintList(ComplaintFilter filter) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ComplaintsListPage(filter: filter)),
    );
  }

  Widget _sectionLabel(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1B2B5E),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  Widget _grid(List<Widget> tiles) {
    final w = MediaQuery.of(context).size.width;
    final cols = w >= 900 ? 4 : (w >= 600 ? 3 : 2);
    return GridView.count(
      crossAxisCount: cols,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.05,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: tiles,
    );
  }

  Widget _tile(
    String title,
    String count,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: color.withOpacity(0.18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const Spacer(),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 22,
                height: 3,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),

      // ── AppBar ──────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2B5E),
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 72,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF1B2B5E),
          statusBarIconBrightness: Brightness.light,
        ),
        title: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/logo1.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.solar_power_rounded,
                    color: Color(0xFFF5C518),
                    size: 26,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Hive Solar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    height: 1.2,
                  ),
                ),
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Color(0xFFF5C518),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.account_circle_rounded,
              color: Colors.white,
              size: 36,
            ),
            color: Colors.white,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            offset: const Offset(0, 58),
            onSelected: (v) {
              if (v == 'logout') _logout();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                height: 52,
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFF1B2B5E),
                      child: Icon(Icons.person, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Admin',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            FirebaseAuth.instance.currentUser?.email ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                height: 40,
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFEF4444),
                      size: 17,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, color: const Color(0xFFF5C518)),
        ),
      ),

      // ── Body ────────────────────────────────────────────────
      body: FutureBuilder<AmcStatusModel>(
        future: amcData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1B2B5E),
                strokeWidth: 3,
              ),
            );
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error loading dashboard',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final data = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── AMC Overview ────────────────────────────
                _sectionLabel(
                  'AMC Overview',
                  'Annual Maintenance Contract summary',
                ),
                const SizedBox(height: 12),
                _grid([
                  _tile(
                    'Active AMC',
                    data.active.toString(),
                    Icons.verified_user_rounded,
                    const Color(0xFF10B981),
                    onTap: () => _openAmcList(AmcFilter.active),
                  ),
                  _tile(
                    'Expiring Soon',
                    data.expiring.toString(),
                    Icons.timer_rounded,
                    const Color(0xFFF59E0B),
                    onTap: () => _openAmcList(AmcFilter.expiringSoon),
                  ),
                  _tile(
                    'AMC Database',
                    data.database.toString(),
                    Icons.storage_rounded,
                    const Color(0xFF3B82F6),
                    onTap: () => _openAmcList(AmcFilter.all),
                  ),
                  _tile(
                    'Expired',
                    data.expired.toString(),
                    Icons.cancel_rounded,
                    const Color(0xFFEF4444),
                    onTap: () => _openAmcList(AmcFilter.expired),
                  ),
                ]),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(thickness: 1, color: Color(0xFFE2E8F0)),
                ),

                // ── Customer Support ─────────────────────────
                _sectionLabel(
                  'Customer Support',
                  'Complaints & ticket summary',
                ),
                const SizedBox(height: 12),
                FutureBuilder<SupportStatsModel>(
                  future: supportData,
                  builder: (_, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(
                            color: Color(0xFF1B2B5E),
                            strokeWidth: 2.5,
                          ),
                        ),
                      );
                    }
                    if (!snap.hasData) {
                      return const Text(
                        'No support data',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      );
                    }
                    final s = snap.data!;
                    return _grid([
                      _tile(
                        'New Tickets',
                        s.newTickets.toString(),
                        Icons.fiber_new_rounded,
                        const Color(0xFF10B981),
                        onTap: () =>
                            _openComplaintList(ComplaintFilter.newComplaints),
                      ),
                      _tile(
                        'Delayed',
                        s.delayed.toString(),
                        Icons.hourglass_bottom_rounded,
                        const Color(0xFFEF4444),
                        onTap: () =>
                            _openComplaintList(ComplaintFilter.delayed),
                      ),
                    ]);
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(thickness: 1, color: Color(0xFFE2E8F0)),
                ),

                // ── Solar AMC ────────────────────────────────
                _sectionLabel('Solar AMC List', 'Solar AMC contract summary'),
                const SizedBox(height: 12),
                FutureBuilder<SolarAmcModel>(
                  future: solarAmcData,
                  builder: (_, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(
                            color: Color(0xFF1B2B5E),
                            strokeWidth: 2.5,
                          ),
                        ),
                      );
                    }
                    if (!snap.hasData) {
                      return const Text(
                        'No solar AMC data',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      );
                    }
                    return _grid([
                      _tile(
                        'Expiring Soon',
                        snap.data!.expiringSoon.toString(),
                        Icons.timer_rounded,
                        const Color(0xFFF59E0B),
                        onTap: () =>
                            _openSolarAmcList(SolarAmcFilter.expiringSoon),
                      ),
                      _tile(
                        'Active AMCs',
                        snap.data!.activeAmcs.toString(),
                        Icons.verified_user_rounded,
                        const Color(0xFF10B981),
                        onTap: () => _openSolarAmcList(SolarAmcFilter.active),
                      ),
                      _tile(
                        'Expired',
                        snap.data!.expired.toString(),
                        Icons.cancel_rounded,
                        const Color(0xFFEF4444),
                        onTap: () => _openSolarAmcList(SolarAmcFilter.expired),
                      ),
                      _tile(
                        'AMC Database',
                        snap.data!.amcDatabase.toString(),
                        Icons.storage_rounded,
                        const Color(0xFF3B82F6),
                        onTap: () => _openSolarAmcList(SolarAmcFilter.all),
                      ),
                    ]);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
