import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/amc_model.dart';
import '../../services/user_service.dart';

enum SolarAmcFilter { active, expiringSoon, expired, all }

List<AmcModel> _parseSolarAmcList(List<dynamic> rawList) {
  final docs = rawList
      .map((e) => AmcModel.fromJson(e as Map<String, dynamic>))
      .toList();
  docs.sort((a, b) => b.product.billDate.compareTo(a.product.billDate));
  return docs;
}

class SolarAmcListPage extends StatefulWidget {
  final SolarAmcFilter filter;
  const SolarAmcListPage({super.key, required this.filter});

  @override
  State<SolarAmcListPage> createState() => _SolarAmcListPageState();
}

class _SolarAmcListPageState extends State<SolarAmcListPage> {
  final TextEditingController _searchController = TextEditingController();

  List<AmcModel> _allRecords = [];
  List<AmcModel> _filtered = [];
  bool _loading = true;
  String? _error;

  String get _title {
    switch (widget.filter) {
      case SolarAmcFilter.active:
        return 'Active Solar AMC';
      case SolarAmcFilter.expiringSoon:
        return 'Expiring Soon';
      case SolarAmcFilter.expired:
        return 'Expired Solar AMC';
      case SolarAmcFilter.all:
        return 'Solar AMC Database';
    }
  }

  Color get _accentColor {
    switch (widget.filter) {
      case SolarAmcFilter.active:
        return const Color(0xFF10B981);
      case SolarAmcFilter.expiringSoon:
        return const Color(0xFFF59E0B);
      case SolarAmcFilter.expired:
        return const Color(0xFFEF4444);
      case SolarAmcFilter.all:
        return const Color(0xFF3B82F6);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Fetch all, filter in Dart — avoids missing-field issue (matches Angular)
      final snap = await FirebaseFirestore.instance
          .collection('solaramc-list')
          .get();

      final rawList = snap.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .where((d) => d['isdeleted'] != true)
          .toList();

      final parsed = await compute(_parseSolarAmcList, rawList);

      setState(() {
        _allRecords = parsed;
        _applyFilter();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();

    _filtered = _allRecords.where((detail) {
      if (widget.filter != SolarAmcFilter.all && detail.isArchive) return false;

      bool statusMatch;
      switch (widget.filter) {
        case SolarAmcFilter.active:
          statusMatch =
              detail.optForAmc != 'notinterested' &&
              (detail.amcEndStatus == 'active' ||
                  detail.amcEndStatus == 'expiring');
          break;
        case SolarAmcFilter.expiringSoon:
          statusMatch = detail.amcEndStatus == 'expiring';
          break;
        case SolarAmcFilter.expired:
          statusMatch = detail.amcEndStatus == 'expired';
          break;
        case SolarAmcFilter.all:
          statusMatch = true;
          break;
      }

      if (!statusMatch) return false;
      if (query.isEmpty) return true;

      return detail.customer.name.toLowerCase().contains(query) ||
          detail.customer.address.toLowerCase().contains(query) ||
          detail.customer.phone.toLowerCase().contains(query) ||
          detail.amc.type.toLowerCase().contains(query) ||
          detail.assignedEmployee.toLowerCase().contains(query);
    }).toList();
  }

  void _onSearchChanged(String _) {
    setState(() => _applyFilter());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          _title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF1B2B5E),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, color: const Color(0xFFF5C518)),
        ),
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _accentColor),
                  const SizedBox(height: 16),
                  Text(
                    'Loading $_title...',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Something went wrong.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$_title  •  ${_filtered.length}',
                              style: TextStyle(
                                color: _accentColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search by name, address, phone...',
                          hintStyle: const TextStyle(fontSize: 13),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                _filtered.isEmpty
                    ? Expanded(
                        child: Center(
                          child: Text(
                            'No $_title records found.',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      )
                    : Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) => _SolarAmcCard(
                            amc: _filtered[index],
                            accentColor: _accentColor,
                          ),
                        ),
                      ),
              ],
            ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────
class _SolarAmcCard extends StatelessWidget {
  final AmcModel amc;
  final Color accentColor;

  const _SolarAmcCard({required this.amc, required this.accentColor});

  String _formatDate(String raw) {
    if (raw.isEmpty) return '-';
    final ms = int.tryParse(raw);
    if (ms != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    }
    final dt = DateTime.tryParse(raw);
    if (dt != null) {
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    }
    return raw;
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              amc.customer.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (amc.customer.priority == 'highvaluecustomer')
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFF59E0B),
                              size: 18,
                            ),
                        ],
                      ),
                      if (amc.customer.phone.isNotEmpty)
                        Text(
                          amc.customer.phone,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF334155),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _SolarAmcStatusBadge(status: amc.amcEndStatus),
              ],
            ),

            const Divider(height: 16),

            // 1. Date of Purchase
            if (amc.product.billDate.isNotEmpty)
              _InfoRow(
                icon: Icons.receipt_long_outlined,
                label: 'Date of Purchase',
                value: _formatDate(amc.product.billDate),
                accent: accentColor,
              ),

            // 2. Address
            if (amc.customer.address.isNotEmpty)
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: [
                  amc.customer.address,
                  amc.customer.address1,
                ].where((s) => s.isNotEmpty).join(', '),
                accent: accentColor,
              ),

            // 3. AMC Bill Date
            if (amc.amc.amcDate.isNotEmpty)
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'AMC Bill Date',
                value: _formatDate(amc.amc.amcDate),
                accent: accentColor,
              ),

            // 4. AMC End Date
            if (amc.amc.endDate.isNotEmpty)
              _InfoRow(
                icon: Icons.event_outlined,
                label: 'AMC End Date',
                value: _formatDate(amc.amc.endDate),
                accent: accentColor,
              ),

            // 5. AMC Details (type)
            if (amc.amc.type.isNotEmpty)
              _InfoRow(
                icon: Icons.autorenew_rounded,
                label: 'AMC Details',
                value: _capitalize(amc.amc.type),
                accent: accentColor,
              ),

            // 6. Schedule Period
            if (amc.amc.schedule.isNotEmpty)
              _InfoRow(
                icon: Icons.date_range_outlined,
                label: 'Schedule Period',
                value: amc.amc.schedule.join(', '),
                accent: accentColor,
              ),

            // 7. Assigned To
            if (amc.assignedEmployee.isNotEmpty)
              FutureBuilder<String>(
                future: UserService.getUserName(amc.assignedEmployee),
                builder: (context, snapshot) {
                  return _InfoRow(
                    icon: Icons.person_outline,
                    label: 'Assigned To',
                    value: snapshot.data ?? 'Loading...',
                    accent: accentColor,
                  );
                },
              ),

            // 8. Amount
            _InfoRow(
              icon: Icons.currency_rupee,
              label: 'Amount',
              value: amc.displayAmount,
              accent: accentColor,
            ),

            // 9. Status
            if (amc.status.isNotEmpty)
              _InfoRow(
                icon: Icons.info_outline,
                label: 'Status',
                value: _capitalize(amc.status),
                accent: accentColor,
              ),

            // 10. Products (extra detail)
            if (amc.product.products.isNotEmpty)
              _InfoRow(
                icon: Icons.solar_power_rounded,
                label: 'Products',
                value: amc.product.products
                    .map(
                      (p) => '${p['name'] ?? ''} - ${p['quantity'] ?? ''} No',
                    )
                    .join('\n'),
                accent: accentColor,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────
class _SolarAmcStatusBadge extends StatelessWidget {
  final String status;
  const _SolarAmcStatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case 'active':
        return const Color(0xFF10B981);
      case 'expiring':
        return const Color(0xFFF59E0B);
      case 'expired':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  String get _label {
    switch (status) {
      case 'active':
        return 'Active';
      case 'expiring':
        return 'Expiring Soon';
      case 'expired':
        return 'Expired';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
