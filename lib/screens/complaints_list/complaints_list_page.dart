import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'complaints_details.dart';

enum ComplaintFilter { newComplaints, delayed, completed, archived, all }

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

  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String? _error;

  late ComplaintFilter _activeFilter;

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.filter;
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

      final parsed = await compute(_parseComplaintList, rawList);

      if (!mounted) return;
      setState(() {
        _all = parsed;
        _applyFilters();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();

    _filtered = _all.where((detail) {
      final isArchive = detail['isarchive'] == true;
      final status = (detail['status'] ?? '').toString().toLowerCase();

      bool statusMatch;
      switch (_activeFilter) {
        case ComplaintFilter.newComplaints:
          statusMatch = status == 'new';
          break;
        case ComplaintFilter.delayed:
          statusMatch = status == 'delayed';
          break;
        case ComplaintFilter.completed:
          statusMatch = status == 'completed' && !isArchive;
          break;
        case ComplaintFilter.archived:
          statusMatch = isArchive;
          break;
        case ComplaintFilter.all:
          statusMatch = true;
          break;
      }

      if (!statusMatch) return false;
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

  // ── FIXED: counts now use the same logic as _applyFilters ─────────────────
  // Previously the stat-card counts were computed independently and could
  // diverge from the actual filtered list. Now each case mirrors _applyFilters
  // exactly so tapping a card always shows the same number of records as the
  // count displayed on it.
  int _count(ComplaintFilter f) {
    switch (f) {
      case ComplaintFilter.all:
        // mirrors _applyFilters: no status restriction
        return _all.length;

      case ComplaintFilter.newComplaints:
        // mirrors _applyFilters: status == 'new'
        return _all
            .where(
              (d) => (d['status'] ?? '').toString().toLowerCase() == 'new',
            )
            .length;

      case ComplaintFilter.delayed:
        // mirrors _applyFilters: status == 'delayed'
        return _all
            .where(
              (d) => (d['status'] ?? '').toString().toLowerCase() == 'delayed',
            )
            .length;

      case ComplaintFilter.completed:
        // mirrors _applyFilters: status == 'completed' AND not archived
        return _all
            .where(
              (d) =>
                  (d['status'] ?? '').toString().toLowerCase() == 'completed' &&
                  d['isarchive'] != true,
            )
            .length;

      case ComplaintFilter.archived:
        // mirrors _applyFilters: isarchive == true
        return _all.where((d) => d['isarchive'] == true).length;
    }
  }

  Color _filterColor(ComplaintFilter f) {
    switch (f) {
      case ComplaintFilter.all:
        return const Color(0xFF3B82F6);
      case ComplaintFilter.newComplaints:
        return const Color(0xFFF59E0B);
      case ComplaintFilter.delayed:
        return const Color(0xFFEF4444);
      case ComplaintFilter.completed:
        return const Color(0xFF10B981);
      case ComplaintFilter.archived:
        return const Color(0xFF94A3B8);
    }
  }

  String _filterLabel(ComplaintFilter f) {
    switch (f) {
      case ComplaintFilter.all:
        return 'All';
      case ComplaintFilter.newComplaints:
        return 'New';
      case ComplaintFilter.delayed:
        return 'Delayed';
      case ComplaintFilter.completed:
        return 'Completed';
      case ComplaintFilter.archived:
        return 'Archived';
    }
  }

  Color get _accentColor => _filterColor(_activeFilter);

  void _onFilterTap(ComplaintFilter f) {
    setState(() {
      _activeFilter = f;
      _applyFilters();
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Filter by Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Select a filter to narrow the list',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ComplaintFilter.all,
                      ComplaintFilter.archived,
                      ComplaintFilter.completed,
                    ].map((f) {
                      final color = _filterColor(f);
                      final isSelected = _activeFilter == f;
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() {});
                          _onFilterTap(f);
                          Navigator.pop(context);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color
                                : color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : color.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '${_filterLabel(f)} (${_count(f)})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : color,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  if (_activeFilter != ComplaintFilter.all)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _activeFilter = ComplaintFilter.all;
                            _applyFilters();
                          });
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Clear Filter'),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDetail(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) =>
          ComplaintDetailSheet(data: data, accentColor: _accentColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Complaints & Support',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B2B5E)),
            )
          : _error != null
          ? _ErrorView(error: _error!, onRetry: _loadData)
          : Column(
              children: [
                // ── Stat cards ──
                ColoredBox(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Row(
                      children: [
                        ComplaintFilter.newComplaints,
                        ComplaintFilter.delayed,
                      ].map((f) {
                        final color = _filterColor(f);
                        final isSelected = _activeFilter == f;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => _onFilterTap(f),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withValues(alpha: 0.12)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? color
                                      : Colors.grey.shade200,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${_count(f)}',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _filterLabel(f),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isSelected
                                          ? color
                                          : Colors.grey[600],
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // ── Search bar + filter icon ──
                ColoredBox(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(_applyFilters),
                            decoration: InputDecoration(
                              hintText:
                                  'Search by name, phone, complaint no...',
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
                        ),
                        const SizedBox(width: 8),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Material(
                              color: _activeFilter != ComplaintFilter.all
                                  ? _accentColor
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: _showFilterSheet,
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Icon(
                                    Icons.tune_rounded,
                                    size: 22,
                                    color: _activeFilter != ComplaintFilter.all
                                        ? Colors.white
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                            if (_activeFilter != ComplaintFilter.all)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── List ──
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'No records found.',
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                        )
                      : ListView.builder(
                          cacheExtent: 500,
                          padding: const EdgeInsets.only(top: 8, bottom: 24),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _ComplaintTile(
                            key: ValueKey(_filtered[i]['id']),
                            data: _filtered[i],
                            accentColor: _accentColor,
                            onTap: () => _showDetail(_filtered[i]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

// ── Complaint tile ────────────────────────────────────────────────────────────

class _ComplaintTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color accentColor;
  final VoidCallback onTap;

  const _ComplaintTile({
    super.key,
    required this.data,
    required this.accentColor,
    required this.onTap,
  });

  Color _dotColor(String status) {
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

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] ?? '').toString();
    final phone = (data['phone'] ?? '').toString();
    final address = (data['address'] ?? '').toString();
    final status = (data['status'] ?? '').toString().toLowerCase();
    final priority = () {
      final c = data['customer'];
      if (c is Map) return (c['priority'] ?? data['priority'] ?? '').toString();
      return (data['priority'] ?? '').toString();
    }();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: accentColor.withValues(alpha: 0.14),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _dotColor(status),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (priority == 'highvaluecustomer')
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFF59E0B),
                            size: 15,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (phone.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 13,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Something went wrong.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B2B5E),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}