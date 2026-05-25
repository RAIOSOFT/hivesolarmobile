import 'package:flutter/material.dart';
import '../../models/amc_model.dart';
import '../../services/user_service.dart';
import '../../services/routes_service.dart';
import '/widgets/comment_widget.dart';

class AmcDetailSheet extends StatelessWidget {
  final AmcModel amc;
  final Color accentColor;

  const AmcDetailSheet({
    super.key,
    required this.amc,
    required this.accentColor,
  });

  // Converts epoch ms string → "dd/MM/yyyy"
  String _formatDate(String raw) {
    if (raw.isEmpty) return '-';
    final ms = int.tryParse(raw);
    final dt = ms != null
        ? DateTime.fromMillisecondsSinceEpoch(ms)
        : DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  // Mirrors Angular: amount === '0' || amount === 0 → 'Free'
  String get _displayAmount {
    final v = amc.amc.amount;
    if (v == '0' || v.isEmpty) return 'Free';
    return '₹$v';
  }

  // Mirrors Angular: products[].name + details + quantity
  String _formatProducts() {
    return amc.product.products
        .map((p) {
          final name = (p['name'] ?? '').toString();
          final details = (p['details'] ?? '').toString();
          final qty = (p['quantity'] ?? '').toString();
          final parts = [
            if (name.isNotEmpty) name,
            if (details.isNotEmpty && qty.isNotEmpty) '$details - $qty No',
            if (details.isEmpty && qty.isNotEmpty) '$qty No',
          ];
          return parts.join('\n  ');
        })
        .join('\n');
  }

  // Shorthand so call sites stay readable
  Widget _row(IconData icon, String label, String value) => DetailRow(
    icon: icon,
    label: label,
    value: value,
    accentColor: accentColor,
  );

  @override
  Widget build(BuildContext context) {
    final comments = amc.comments; // sorted newest-first in AmcModel.fromJson

    return DraggableScrollableSheet(
      initialChildSize: 0.65, // opens at 65% of screen height
      minChildSize: 0.4, // can collapse to 40%
      maxChildSize: 0.95, // can expand to 95%
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
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
                      amc.customer.name.isNotEmpty
                          ? amc.customer.name[0].toUpperCase()
                          : '?',
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
                                amc.customer.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            // Star icon — mirrors Angular priority == 'highvaluecustomer'
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
                              fontSize: 13,
                              color: Color(0xFF475569),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: amc.amcEndStatus),
                ],
              ),
            ),

            const Divider(height: 1),

            // Scrollable detail rows
            // scrollController MUST be connected here — without it, dragging
            // the sheet and scrolling the list conflict with each other
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  // 1. Date of Purchase — Angular col 1
                  if (amc.product.billDate.isNotEmpty)
                    _row(
                      Icons.receipt_long_outlined,
                      'Date of Purchase',
                      _formatDate(amc.product.billDate),
                    ),

                  // 2. Address — Angular col 3
                  if (amc.customer.address.isNotEmpty)
                    _row(
                      Icons.location_on_outlined,
                      'Address',
                      [
                        amc.customer.address,
                        amc.customer.address1,
                      ].where((s) => s.isNotEmpty).join(', '),
                    ),

                  // 3. AMC Bill Date — Angular col 4
                  if (amc.amc.amcDate.isNotEmpty)
                    _row(
                      Icons.calendar_today_outlined,
                      'AMC Bill Date',
                      _formatDate(amc.amc.amcDate),
                    ),

                  // 4. AMC End Date — Angular col 5
                  if (amc.amc.endDate.isNotEmpty)
                    _row(
                      Icons.event_outlined,
                      'AMC End Date',
                      _formatDate(amc.amc.endDate),
                    ),

                  // 5. Route — Angular col 6
                  // amc.amc.route is a Firestore doc ID → resolved via RouteService
                  // RouteService caches results so Firestore is only hit once per route
                  if (amc.amc.route.isNotEmpty)
                    FutureBuilder<RouteInfo?>(
                      future: RouteService.getRoute(amc.amc.route),
                      builder: (_, snap) {
                        if (!snap.hasData) return const SizedBox.shrink();
                        final route = snap.data!;
                        return Column(
                          children: [
                            if (route.name.isNotEmpty)
                              _row(Icons.route_outlined, 'Route', route.name),
                          ],
                        );
                      },
                    ),

                  // 6. AMC Details — Angular col 7: product name + details + qty
                  if (amc.product.products.isNotEmpty)
                    _row(
                      Icons.inventory_2_outlined,
                      'AMC Details',
                      _formatProducts(),
                    ),

                  // 7. Schedule Period — Angular col 8
                  if (amc.amc.type.isNotEmpty)
                    _row(
                      Icons.autorenew_rounded,
                      'Schedule Period',
                      _cap(amc.amc.type),
                    ),

                  // 8. Schedule dates
                  if (amc.amc.schedule.isNotEmpty)
                    _row(
                      Icons.date_range_outlined,
                      'Schedule',
                      amc.amc.schedule.join(', '),
                    ),

                  // 9. Assigned To — Angular col 9
                  if (amc.assignedEmployee.isNotEmpty)
                    FutureBuilder<String>(
                      future: UserService.getUserName(amc.assignedEmployee),
                      builder: (_, snap) => _row(
                        Icons.person_outline,
                        'Assigned To',
                        snap.data ?? 'Loading...',
                      ),
                    ),

                  // 10. Amount — Angular col 10: "Free" if 0
                  _row(Icons.currency_rupee, 'Amount', _displayAmount),

                  // 11. Status — Angular col 11
                  if (amc.status.isNotEmpty)
                    _row(Icons.info_outline, 'Status', _cap(amc.status)),

                  // 12. Comments — same structure as Solar AMC and Complaints
                  // Angular: detail.comments[] with bywhom, cdate, comments fields
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

// ── Status badge ──────────────────────────────────────────────────────────────
// Uses amcEndStatus (computed from end date) — not the raw status field.
// Values: 'active', 'expiring', 'expired', 'completed', 'unknown'

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case 'active':
        return const Color(0xFF10B981);
      case 'expiring':
        return const Color(0xFFF59E0B);
      case 'expired':
        return const Color(0xFFEF4444);
      case 'completed':
        return const Color(0xFF8B5CF6);
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
