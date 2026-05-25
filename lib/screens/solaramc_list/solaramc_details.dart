import 'package:flutter/material.dart';
import '../../../models/amc_model.dart';
import '../../../services/user_service.dart';
import '../../../services/routes_service.dart';
import '../../widgets/comment_widget.dart';

class SolarAmcDetailSheet extends StatelessWidget {
  final AmcModel amc;
  final Color accentColor;

  const SolarAmcDetailSheet({
    super.key,
    required this.amc,
    required this.accentColor,
  });

  // Converts epoch ms string → "dd/MM/yyyy"
  static String _fmt(String raw) {
    if (raw.isEmpty) return '-';
    final ms = int.tryParse(raw);
    if (ms != null && ms > 0) {
      final d = DateTime.fromMillisecondsSinceEpoch(ms);
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
    return raw;
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  // Shorthand so call sites stay readable
  Widget _row(IconData icon, String label, String value) => DetailRow(
    icon: icon,
    label: label,
    value: value,
    accentColor: accentColor,
  );

  @override
  Widget build(BuildContext context) {
    final fullAddress = [
      amc.customer.address,
      amc.customer.address1,
    ].where((s) => s.isNotEmpty).join(', ');

    final products = amc.product.products
        .map((p) => '${p['name'] ?? ''} - ${p['quantity'] ?? ''} No')
        .join('\n');

    final routeId = amc.amc.route;
    final comments = amc.comments; // already sorted newest-first in AmcModel

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
            // Drag handle — tells user this sheet is resizable
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
                  _AmcStatusBadge(status: amc.amcEndStatus),
                ],
              ),
            ),

            const Divider(height: 1),

            // Scrollable detail rows
            // The scrollController MUST be passed here — without it dragging
            // the sheet and scrolling the list will conflict with each other
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  // 1. Date of Purchase
                  if (amc.product.billDate.isNotEmpty)
                    _row(
                      Icons.receipt_long_outlined,
                      'Date of Purchase',
                      _fmt(amc.product.billDate),
                    ),

                  // 2. Address
                  if (fullAddress.isNotEmpty)
                    _row(Icons.location_on_outlined, 'Address', fullAddress),

                  // 3. AMC Bill Date
                  if (amc.amc.amcDate.isNotEmpty)
                    _row(
                      Icons.calendar_today_outlined,
                      'AMC Bill Date',
                      _fmt(amc.amc.amcDate),
                    ),

                  // 4. AMC End Date
                  if (amc.amc.endDate.isNotEmpty)
                    _row(
                      Icons.event_outlined,
                      'AMC End Date',
                      _fmt(amc.amc.endDate),
                    ),

                  // 5. Route — stored as a document ID, resolved to name + path
                  //    RouteService caches results so Firestore is only hit once per route
                  if (routeId.isNotEmpty)
                    FutureBuilder<RouteInfo?>(
                      future: RouteService.getRoute(routeId),
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

                  // 6. AMC Details (schedule type)
                  if (amc.amc.type.isNotEmpty)
                    _row(
                      Icons.autorenew_rounded,
                      'AMC Details',
                      _cap(amc.amc.type),
                    ),

                  // 7. Schedule periods
                  if (amc.amc.schedule.isNotEmpty)
                    _row(
                      Icons.date_range_outlined,
                      'Schedule',
                      amc.amc.schedule.join(', '),
                    ),

                  // 8. Assigned Employee — resolved via UserService (cached)
                  if (amc.assignedEmployee.isNotEmpty)
                    FutureBuilder<String>(
                      future: UserService.getUserName(amc.assignedEmployee),
                      builder: (_, snap) => _row(
                        Icons.person_outline,
                        'Assigned To',
                        snap.data ?? 'Loading...',
                      ),
                    ),

                  // 9. Amount
                  _row(Icons.currency_rupee, 'Amount', amc.displayAmount),

                  // 10. Status
                  if (amc.status.isNotEmpty)
                    _row(Icons.info_outline, 'Status', _cap(amc.status)),

                  // 11. Products
                  if (products.isNotEmpty)
                    _row(Icons.solar_power_rounded, 'Products', products),

                  // 12. Comments — from comments[] array in Firestore
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

// ── AMC status badge ──────────────────────────────────────────────────────────
// Shows the computed end-date status as a coloured pill.
// Uses amcEndStatus which is computed in AmcModel — not the raw status field.

class _AmcStatusBadge extends StatelessWidget {
  final String status;
  const _AmcStatusBadge({required this.status});

  static const _colors = {
    'active': Color(0xFF10B981),
    'expiring': Color(0xFFF59E0B),
    'expired': Color(0xFFEF4444),
    'completed': Color(0xFF8B5CF6),
  };

  static const _labels = {
    'active': 'Active',
    'expiring': 'Expiring Soon',
    'expired': 'Expired',
    'completed': 'Completed',
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? Colors.grey;
    final label = _labels[status] ?? (status.isEmpty ? 'Unknown' : status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
