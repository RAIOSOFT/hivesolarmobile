// ─────────────────────────────────────────────────────────────────────────────
// shared_detail_widgets.dart
//
// Small widgets that are reused across multiple detail sheets:
//   • CommentBubble  — single comment item (used in Solar AMC + Complaints)
//   • DetailRow      — icon + label + value row (used in all detail sheets)
//
// Keeping shared widgets in one place means any style change applies
// everywhere automatically — no need to update multiple files.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../services/user_service.dart';

// ── Detail row ────────────────────────────────────────────────────────────────
// A single labelled row: [icon]  [label:]  [value]
// Used by every detail sheet to keep spacing and typography consistent.

class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: accentColor),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
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

// ── Comment bubble ────────────────────────────────────────────────────────────
// Displays a single comment from the comments[] array.
//
// Each comment map has:
//   • bywhom   — user document ID (resolved to a name via UserService)
//   • cdate    — timestamp in epoch ms
//   • comments — the comment text string
//
// Used by: SolarAmcDetailSheet, ComplaintDetailSheet

class CommentBubble extends StatelessWidget {
  final Map<String, dynamic> comment;
  final Color accentColor;

  const CommentBubble({
    super.key,
    required this.comment,
    required this.accentColor,
  });

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    final ms = raw is int ? raw : int.tryParse(raw.toString()) ?? 0;
    if (ms == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final text = (comment['comments'] ?? '').toString();
    final bywhom = (comment['bywhom'] ?? '').toString();
    final date = _formatDate(comment['cdate']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author name (async) + date on the same line
          Row(
            children: [
              if (bywhom.isNotEmpty)
                FutureBuilder<String>(
                  // UserService caches results so this only hits Firestore once
                  // per user ID per app session
                  future: UserService.getUserName(bywhom),
                  builder: (_, snap) => Text(
                    snap.data ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ),
              const Spacer(),
              if (date.isNotEmpty)
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
            ],
          ),

          // Comment text
          if (text.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Comments section header ───────────────────────────────────────────────────
// Shows "Comments (N)" with an icon — used above the comment list.

class CommentsSectionHeader extends StatelessWidget {
  final int count;
  final Color accentColor;

  const CommentsSectionHeader({
    super.key,
    required this.count,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Row(
        children: [
          Icon(Icons.comment_outlined, size: 17, color: accentColor),
          const SizedBox(width: 10),
          Text(
            'Comments ($count)',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sheet drag handle ─────────────────────────────────────────────────────────
// The grey pill at the top of every bottom sheet — indicates it's draggable.

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
