import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../services/routes_service.dart';
import '../../widgets/comment_widget.dart';

class ComplaintDetailSheet extends StatelessWidget {
  final Map<String, dynamic> data; // raw Firestore document
  final Color accentColor;

  const ComplaintDetailSheet({
    super.key,
    required this.data,
    required this.accentColor,
  });

  // Converts epoch ms (int or string) → "dd/MM/yyyy"
  String _formatDate(dynamic raw) {
    if (raw == null) return '-';
    final ms = raw is int ? raw : int.tryParse(raw.toString()) ?? 0;
    if (ms == 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  // phone is stored as int64 in Firestore — toString() handles both int and string
  String _phoneString(dynamic raw) => raw?.toString() ?? '';

  // Shorthand so call sites stay readable
  Widget _row(IconData icon, String label, String value) => DetailRow(
    icon: icon,
    label: label,
    value: value,
    accentColor: accentColor,
  );

  String get _status => (data['status'] ?? '').toString().toLowerCase();

  // Parse comments and sort newest first — matches Angular .slice().reverse()
  List<Map<String, dynamic>> get _comments {
    final raw = data['comments'];
    if (raw == null || raw is! List) return [];
    final list =
        raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          ..sort((a, b) {
            final aDate = (a['cdate'] as int?) ?? 0;
            final bDate = (b['cdate'] as int?) ?? 0;
            return bDate.compareTo(aDate);
          });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    // Extract all fields using exact Firestore field names
    final name = (data['name'] ?? '').toString().trim();
    final phone = _phoneString(data['phone']);
    final address = (data['address'] ?? '').toString();
    final selectedRoute = (data['selectedRoute'] ?? '').toString();
    final productDetails = (data['productDetails'] ?? '').toString();
    final complaint = (data['complaint'] ?? '').toString();
    final complaintnumber = (data['complaintnumber'] ?? '').toString();
    final assignedemployee = (data['assignedemployee'] ?? '').toString();
    // employeename is stored directly — no async lookup needed
    final employeename = (data['employeename'] ?? '').toString();
    final refno = (data['refno'] ?? '').toString();
    final visiteddate = data['visiteddate'];
    final comments = _comments;

    final amount = () {
      final v = data['amount'];
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }();

    final priority = () {
      final c = data['customer'];
      if (c is Map) return (c['priority'] ?? data['priority'] ?? '').toString();
      return (data['priority'] ?? '').toString();
    }();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SheetHandle(),

            // Header — avatar, name, phone, status badge
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: accentColor.withValues(alpha: 0.15),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            if (priority == 'highvaluecustomer')
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFF59E0B),
                                size: 18,
                              ),
                          ],
                        ),
                        if (phone.isNotEmpty)
                          Text(
                            phone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF475569),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _ComplaintStatusBadge(status: _status),
                ],
              ),
            ),

            const Divider(height: 1),

            // Scrollable detail rows
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  // 1. Ref No
                  if (refno.isNotEmpty)
                    _row(Icons.numbers_outlined, 'Ref No', refno),

                  // 2. Registration Date
                  if (data['regDate'] != null)
                    _row(
                      Icons.calendar_today_outlined,
                      'Reg Date',
                      _formatDate(data['regDate']),
                    ),

                  // 3. Address
                  if (address.isNotEmpty)
                    _row(Icons.location_on_outlined, 'Address', address),

                  // 4. Route — stored as document ID in selectedRoute field
                  //    RouteService.getRoute() resolves name + path (cached)
                  if (selectedRoute.isNotEmpty)
                    FutureBuilder<RouteInfo?>(
                      future: RouteService.getRoute(selectedRoute),
                      builder: (_, snap) {
                        final info = snap.data;
                        if (info == null) return const SizedBox.shrink();
                        return Column(
                          children: [
                            _row(Icons.route_outlined, 'Route', info.name),
                            if (info.path.isNotEmpty)
                              _row(Icons.map_outlined, 'Route Path', info.path),
                          ],
                        );
                      },
                    ),

                  // 5. Product Details
                  if (productDetails.isNotEmpty)
                    _row(
                      Icons.inventory_2_outlined,
                      'Products',
                      productDetails,
                    ),

                  // 6. Complaint Details
                  if (complaint.isNotEmpty)
                    _row(Icons.report_problem_outlined, 'Complaint', complaint),

                  // 7. Complaint Number
                  if (complaintnumber.isNotEmpty)
                    _row(Icons.tag_outlined, 'Comp. No', complaintnumber),

                  // 8. Assigned Employee
                  //    Use stored employeename first (no async needed)
                  //    Fall back to UserService lookup if not stored
                  if (employeename.isNotEmpty)
                    _row(Icons.person_outline, 'Assigned To', employeename)
                  else if (assignedemployee.isNotEmpty)
                    FutureBuilder<String>(
                      future: UserService.getUserName(assignedemployee),
                      builder: (_, snap) => _row(
                        Icons.person_outline,
                        'Assigned To',
                        snap.data ?? 'Loading...',
                      ),
                    ),

                  // 9. Amount
                  _row(
                    Icons.currency_rupee,
                    'Amount',
                    (amount == 0) ? '₹0' : '₹${amount.toStringAsFixed(0)}',
                  ),

                  // 10. Status
                  if (_status.isNotEmpty)
                    _row(Icons.info_outline, 'Status', _cap(_status)),

                  // 11. Visited Date (only present after a visit is logged)
                  if (visiteddate != null)
                    _row(
                      Icons.check_circle_outline,
                      'Visited On',
                      _formatDate(visiteddate),
                    ),

                  // 12. Comments
                  if (comments.isNotEmpty) ...[
                    CommentsSectionHeader(
                      count: comments.length,
                      accentColor: accentColor,
                    ),
                    ...comments.map(
                      (c) =>
                          CommentBubble(comment: c, accentColor: accentColor),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Complaint status badge ────────────────────────────────────────────────────
// Uses the raw `status` field values from Firestore: 'new', 'delayed', 'completed'
// This is different from the AMC badge which uses amcEndStatus (date-computed).

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
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
