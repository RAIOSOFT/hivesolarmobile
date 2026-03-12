import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/user_service.dart';

enum ComplaintFilter { newComplaints, delayed, completed, archived, all }

// ── Top-level parse function for compute() ───────────────────
List<Map<String, dynamic>> _parseComplaintList(List<dynamic> rawList) {
  final docs = rawList.cast<Map<String, dynamic>>();
  docs.sort((a, b) {
    final aDate = (a['regDate'] as int?) ?? 0;
    final bDate = (b['regDate'] as int?) ?? 0;
    return bDate.compareTo(aDate);
  });
  return docs;
}

class ComplaintsListPage extends StatefulWidget {
  final ComplaintFilter filter;
  const ComplaintsListPage({super.key, required this.filter});

  @override
  State<ComplaintsListPage> createState() => _ComplaintsListPageState();
}

class _ComplaintsListPageState extends State<ComplaintsListPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allRecords = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String? _error;

  // ── Title and accent colour per filter ───────────────────
  String get _title {
    switch (widget.filter) {
      case ComplaintFilter.newComplaints:
        return 'New Complaints';
      case ComplaintFilter.delayed:
        return 'Delayed Complaints';
      case ComplaintFilter.completed:
        return 'Completed Complaints';
      case ComplaintFilter.archived:
        return 'Archived Complaints';
      case ComplaintFilter.all:
        return 'Complaints & Support';
    }
  }

  Color get _accentColor {
    switch (widget.filter) {
      case ComplaintFilter.newComplaints:
        return const Color(0xFFF59E0B);
      case ComplaintFilter.delayed:
        return const Color(0xFFEF4444);
      case ComplaintFilter.completed:
        return const Color(0xFF10B981);
      case ComplaintFilter.archived:
        return const Color(0xFF94A3B8);
      case ComplaintFilter.all:
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
      final snap = await FirebaseFirestore.instance
          .collection('amccomplaints-list')
          .get();

      final rawList = snap.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .where((d) => d['isdeleted'] != true)
          .toList();

      // ✅ Sort in background thread — prevents UI freeze
      final parsed = await compute(_parseComplaintList, rawList);

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
      final isArchive = detail['isarchive'] == true;
      final status = (detail['status'] ?? '').toString().toLowerCase();

      // Status filter — mirrors Angular's countFilter() switch exactly
      bool statusMatch;
      switch (widget.filter) {
        case ComplaintFilter.newComplaints:
          // countFilter('new'): status === 'new', no isarchive check
          statusMatch = status == 'new';
          break;
        case ComplaintFilter.delayed:
          // countFilter('delayed'): status === 'delayed', no isarchive check
          statusMatch = status == 'delayed';
          break;
        case ComplaintFilter.completed:
          // countFilter('completed'): status === 'completed' && !isarchive
          statusMatch = status == 'completed' && !isArchive;
          break;
        case ComplaintFilter.archived:
          // countFilter('isarchive'): isarchive === true only
          statusMatch = isArchive;
          break;
        case ComplaintFilter.all:
          // totalcomplaintList.length — all non-deleted, no other filter
          statusMatch = true;
          break;
      }

      if (!statusMatch) return false;

      // Search
      if (query.isEmpty) return true;

      return (detail['name'] ?? '').toString().toLowerCase().contains(query) ||
          (detail['address'] ?? '').toString().toLowerCase().contains(query) ||
          (detail['phone'] ?? '').toString().toLowerCase().contains(query) ||
          status.contains(query) ||
          (detail['complaintnumber'] ?? '').toString().toLowerCase().contains(
            query,
          ) ||
          (detail['productDetails'] ?? '').toString().toLowerCase().contains(
            query,
          );
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
                // ── Count badge + Search bar ──────────────
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
                          hintText: 'Search by name, address, complaint no...',
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

                // ── List ─────────────────────────────────
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
                          itemBuilder: (context, index) => _ComplaintCard(
                            data: _filtered[index],
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
class _ComplaintCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color accentColor;

  const _ComplaintCard({required this.data, required this.accentColor});

  String _formatDate(dynamic raw) {
    if (raw == null) return '-';
    final ms = raw is int ? raw : int.tryParse(raw.toString()) ?? 0;
    if (ms == 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String get _status => (data['status'] ?? '').toString().toLowerCase();
  String get _name => (data['name'] ?? '').toString();
  String get _phone => (data['phone'] ?? '').toString();
  String get _address => (data['address'] ?? '').toString();
  String get _productDetails => (data['productDetails'] ?? '').toString();
  String get _complaint => (data['complaint'] ?? '').toString();
  String get _complaintnumber => (data['complaintnumber'] ?? '').toString();
  String get _assignedemployee => (data['assignedemployee'] ?? '').toString();
  String get _priority {
    final customer = data['customer'];
    if (customer is Map) {
      return (customer['priority'] ?? data['priority'] ?? '').toString();
    }
    return (data['priority'] ?? '').toString();
  }

  double get _amount {
    final v = data['amount'];
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

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
                              _name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          // Star icon — mirrors Angular priority star check
                          if (_priority == 'highvaluecustomer')
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFF59E0B),
                              size: 18,
                            ),
                        ],
                      ),
                      if (_phone.isNotEmpty)
                        Text(
                          _phone,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF334155),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _ComplaintStatusBadge(status: _status),
              ],
            ),

            const Divider(height: 16),

            // 1. Registration Date
            if (data['regDate'] != null)
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Reg Date',
                value: _formatDate(data['regDate']),
                accent: accentColor,
              ),

            // 2. Address
            if (_address.isNotEmpty)
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: _address,
                accent: accentColor,
              ),

            // 3. Product Details
            if (_productDetails.isNotEmpty)
              _InfoRow(
                icon: Icons.inventory_2_outlined,
                label: 'Products',
                value: _productDetails,
                accent: accentColor,
              ),

            // 4. Complaint Details
            if (_complaint.isNotEmpty)
              _InfoRow(
                icon: Icons.report_problem_outlined,
                label: 'Complaint',
                value: _complaint,
                accent: accentColor,
              ),

            // 5. Complaint Number
            if (_complaintnumber.isNotEmpty)
              _InfoRow(
                icon: Icons.tag_outlined,
                label: 'Comp. No',
                value: _complaintnumber,
                accent: accentColor,
              ),

            // 6. Assigned employee
            if (_assignedemployee.isNotEmpty)
              FutureBuilder<String>(
                future: UserService.getUserName(_assignedemployee),
                builder: (context, snapshot) {
                  return _InfoRow(
                    icon: Icons.person_outline,
                    label: 'Assigned',
                    value: snapshot.data ?? 'Loading...',
                    accent: accentColor,
                  );
                },
              ),

            // 7. Amount
            _InfoRow(
              icon: Icons.currency_rupee,
              label: 'Amount',
              value: _amount > 0 ? '₹${_amount.toStringAsFixed(0)}' : '₹0',
              accent: accentColor,
            ),

            // 8. Status
            if (_status.isNotEmpty)
              _InfoRow(
                icon: Icons.info_outline,
                label: 'Status',
                value: _capitalize(_status),
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
            width: 72,
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
class _ComplaintStatusBadge extends StatelessWidget {
  final String status;
  const _ComplaintStatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case 'new':
        return const Color(0xFFF59E0B);
      case 'delayed':
        return const Color(0xFFEF4444);
      case 'completed':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  String get _label {
    switch (status) {
      case 'new':
        return 'New';
      case 'delayed':
        return 'Delayed';
      case 'completed':
        return 'Completed';
      default:
        return status.isEmpty ? 'Unknown' : status;
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
