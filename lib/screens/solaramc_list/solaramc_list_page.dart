import 'package:flutter/material.dart';
import '../../../services/api_services.dart';
import '../../../models/amc_model.dart';
import 'solaramc_details.dart';

enum SolarAmcFilter {
  inprogress,
  notInterested,
  completed,
  cleaningMaintenance,
  archived,
  all,
}

enum SolarTopFilter { expiringSoon, active, expired, all }

class SolarAmcListPage extends StatefulWidget {
  final SolarAmcFilter initialFilter;
  final SolarTopFilter? topFilter;

  const SolarAmcListPage({
    super.key,
    this.initialFilter = SolarAmcFilter.all,
    this.topFilter,
  });

  @override
  State<SolarAmcListPage> createState() => _SolarAmcListPageState();
}

class _SolarAmcListPageState extends State<SolarAmcListPage> {
  final _searchController = TextEditingController();

  List<AmcModel> _all = [];
  List<AmcModel> _filtered = [];
  Map<String, int> _summary = {};

  bool _loading = true;
  String? _error;

  SolarTopFilter? _topFilter;
  SolarAmcFilter? _chipFilter;

  @override
  void initState() {
    super.initState();
    if (widget.topFilter != null) {
      _topFilter = widget.topFilter;
      _chipFilter = null;
    } else {
      _chipFilter = widget.initialFilter == SolarAmcFilter.all
          ? null
          : widget.initialFilter;
      _topFilter = widget.initialFilter == SolarAmcFilter.all
          ? SolarTopFilter.all
          : null;
    }
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final result = await ApiService.fetchSolarAmcList();
      if (!mounted) return;
      int visited = 0;
      int noClient = 0;

      for (final a in _all) {
        if (a.status == 'visited') visited++;
        if (a.status == 'no client available') noClient++;
      }

      print("VISITED: $visited");
      print("NO CLIENT: $noClient");
      print("TOTAL CLEANING SHOULD BE: ${visited + noClient}");
      setState(() {
        _all = result.records;
        _summary = result.summary;
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
    final q = _searchController.text.toLowerCase().trim();

    _filtered = _all.where((amc) {
      if (_topFilter != null) {
        if (amc.isArchive) return false;
        switch (_topFilter!) {
          case SolarTopFilter.expiringSoon:
            if (amc.amcEndStatus != 'expiring') return false;
            break;
          case SolarTopFilter.active:
            if (amc.optForAmc.toLowerCase() == 'notinterested') return false;
            break;
          case SolarTopFilter.expired:
            if (amc.amcEndStatus != 'expired') return false;
            break;
          case SolarTopFilter.all:
            break;
        }
      }

      if (_chipFilter != null) {
        switch (_chipFilter!) {
          case SolarAmcFilter.inprogress:
            if (amc.status.toLowerCase() != 'inprogress') return false;
            break;
          case SolarAmcFilter.notInterested:
            if (amc.optForAmc.toLowerCase() != 'notinterested') return false;
            break;
          case SolarAmcFilter.completed:
            if (amc.status.toLowerCase() != 'completed') return false;
            break;
          case SolarAmcFilter.cleaningMaintenance:
            if (!(amc.status == 'visited' ||
                amc.status == 'no client available')) {
              return false;
            }
            break;
          case SolarAmcFilter.archived:
            if (!amc.isArchive) return false;
            break;
          case SolarAmcFilter.all:
            break;
        }
      }

      if (q.isEmpty) return true;
      return amc.customer.name.toLowerCase().contains(q) ||
          amc.customer.address.toLowerCase().contains(q) ||
          amc.customer.phone.toLowerCase().contains(q) ||
          amc.amc.type.toLowerCase().contains(q) ||
          amc.assignedEmployee.toLowerCase().contains(q);
    }).toList();
  }

  int _countTop(SolarTopFilter f) {
    switch (f) {
      case SolarTopFilter.expiringSoon:
        return _summary['expiring'] ?? 0;
      case SolarTopFilter.active:
        return _summary['active'] ?? 0;
      case SolarTopFilter.expired:
        return _summary['expired'] ?? 0;
      case SolarTopFilter.all:
        return _all.length;
    }
  }

  int _countChip(SolarAmcFilter f) {
    switch (f) {
      case SolarAmcFilter.inprogress:
        return _all.where((a) => a.status.toLowerCase() == 'inprogress').length;
      case SolarAmcFilter.notInterested:
        return _all
            .where((a) => a.optForAmc.toLowerCase() == 'notinterested')
            .length;
      case SolarAmcFilter.completed:
        return _all.where((a) => a.status.toLowerCase() == 'completed').length;
      case SolarAmcFilter.cleaningMaintenance:
        return _all
            .where(
              (a) => a.status == 'visited' || a.status == 'no client available',
            )
            .length;
      case SolarAmcFilter.archived:
        return _all.where((a) => a.isArchive).length;
      case SolarAmcFilter.all:
        return _all.length;
    }
  }

  Color get _accentColor {
    if (_topFilter != null) {
      switch (_topFilter!) {
        case SolarTopFilter.active:
          return const Color(0xFF10B981);
        case SolarTopFilter.expiringSoon:
          return const Color(0xFFF59E0B);
        case SolarTopFilter.expired:
          return const Color(0xFFEF4444);
        case SolarTopFilter.all:
          return const Color(0xFF3B82F6);
      }
    }
    switch (_chipFilter) {
      case SolarAmcFilter.inprogress:
        return const Color(0xFFF59E0B);
      case SolarAmcFilter.notInterested:
        return const Color(0xFFEF4444);
      case SolarAmcFilter.completed:
        return const Color(0xFF10B981);
      case SolarAmcFilter.cleaningMaintenance:
        return const Color(0xFF06B6D4);
      case SolarAmcFilter.archived:
        return const Color(0xFF94A3B8);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  bool get _isChipActive => _chipFilter != null;

  void _onTopTap(SolarTopFilter f) => setState(() {
    _topFilter = f;
    _chipFilter = null;
    _applyFilters();
  });

  void _onChipTap(SolarAmcFilter f) => setState(() {
    _chipFilter = (_chipFilter == f) ? null : f;
    _topFilter = null;
    _applyFilters();
  });

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
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
                'Workflow filters',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SolarAmcFilter.values.map((f) {
                  const labels = {
                    SolarAmcFilter.inprogress: 'Inprogress',
                    SolarAmcFilter.notInterested: 'Not-Interested',
                    SolarAmcFilter.completed: 'Completed',
                    SolarAmcFilter.cleaningMaintenance:
                        'Cleaning / Maintenance',
                    SolarAmcFilter.archived: 'Archived',
                    SolarAmcFilter.all: 'All Clients',
                  };
                  const colors = {
                    SolarAmcFilter.inprogress: Color(0xFFF59E0B),
                    SolarAmcFilter.notInterested: Color(0xFFEF4444),
                    SolarAmcFilter.completed: Color(0xFF10B981),
                    SolarAmcFilter.cleaningMaintenance: Color(0xFF06B6D4),
                    SolarAmcFilter.archived: Color(0xFF94A3B8),
                    SolarAmcFilter.all: Color(0xFF3B82F6),
                  };
                  final color = colors[f]!;
                  final sel = _chipFilter == f;
                  return GestureDetector(
                    onTap: () {
                      setSheet(() {});
                      _onChipTap(f);
                      Navigator.pop(ctx);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? color : color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? color : color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${labels[f]} (${_countChip(f)})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : color,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              if (_chipFilter != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _topFilter = SolarTopFilter.all;
                        _chipFilter = null;
                        _applyFilters();
                      });
                      Navigator.pop(ctx);
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Solar AMC List',
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
                _TopCards(
                  counts: {
                    for (final f in SolarTopFilter.values) f: _countTop(f),
                  },
                  selected: _chipFilter == null ? _topFilter : null,
                  onTap: _onTopTap,
                ),
                ColoredBox(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(_applyFilters),
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
                        ),
                        const SizedBox(width: 8),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Material(
                              color: _isChipActive
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
                                    color: _isChipActive
                                        ? Colors.white
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                            if (_isChipActive)
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
                          itemBuilder: (_, i) => _SolarTile(
                            key: ValueKey(_filtered[i].id),
                            amc: _filtered[i],
                            accentColor: _accentColor,
                            onTap: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              useSafeArea: true,
                              builder: (_) => SolarAmcDetailSheet(
                                amc: _filtered[i],
                                accentColor: _accentColor,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────
// UNCHANGED WIDGETS BELOW (Except for standard styling)
// ─────────────────────────────────────────────

class _TopCards extends StatelessWidget {
  final Map<SolarTopFilter, int> counts;
  final SolarTopFilter? selected;
  final ValueChanged<SolarTopFilter> onTap;

  const _TopCards({
    required this.counts,
    required this.selected,
    required this.onTap,
  });

  static const _labels = {
    SolarTopFilter.expiringSoon: 'Expiring Soon',
    SolarTopFilter.active: 'Active AMCs',
    SolarTopFilter.expired: 'Expired',
    SolarTopFilter.all: 'AMC Database',
  };

  static const _colors = {
    SolarTopFilter.expiringSoon: Color(0xFFF59E0B),
    SolarTopFilter.active: Color(0xFF10B981),
    SolarTopFilter.expired: Color(0xFFEF4444),
    SolarTopFilter.all: Color(0xFF3B82F6),
  };

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Row(
          children: SolarTopFilter.values.map((f) {
            final color = _colors[f]!;
            final isSel = selected == f;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSel
                        ? color.withValues(alpha: 0.12)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSel ? color : Colors.grey.shade200,
                      width: isSel ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${counts[f]}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _labels[f]!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSel ? color : Colors.grey[600],
                          fontWeight: isSel
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
    );
  }
}

class _SolarTile extends StatelessWidget {
  final AmcModel amc;
  final Color accentColor;
  final VoidCallback onTap;

  const _SolarTile({
    super.key,
    required this.amc,
    required this.accentColor,
    required this.onTap,
  });

  Color _dot(String s) {
    switch (s) {
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

  @override
  Widget build(BuildContext context) {
    final address = [
      amc.customer.address,
      amc.customer.address1,
    ].where((s) => s.isNotEmpty).join(', ');

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
                      amc.customer.name.isNotEmpty
                          ? amc.customer.name[0].toUpperCase()
                          : '?',
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
                        color: _dot(amc.amcEndStatus),
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
                            amc.customer.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (amc.customer.priority == 'highvaluecustomer')
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFF59E0B),
                            size: 15,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (amc.customer.phone.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 13,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            amc.customer.phone,
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
