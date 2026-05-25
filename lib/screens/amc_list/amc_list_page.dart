import 'package:flutter/material.dart';
import '../../../services/api_services.dart';
import '../../../models/amc_model.dart';
import 'amc_details.dart';

enum AmcTopFilter { active, expiringSoon, expired, all }

enum AmcChipFilter {
  inprogress,
  notInterested,
  allClients,
  archived,
  completed,
}

class AmcListPage extends StatefulWidget {
  final AmcTopFilter initialFilter;

  const AmcListPage({super.key, this.initialFilter = AmcTopFilter.active});

  @override
  State<AmcListPage> createState() => _AmcListPageState();
}

class _AmcListPageState extends State<AmcListPage> {
  final TextEditingController _searchController = TextEditingController();

  List<AmcModel> _all = [];
  List<AmcModel> _filtered = [];
  Map<String, int> _summary = {};

  bool _loading = true;
  String? _error;

  late AmcTopFilter? _topFilter;
  AmcChipFilter? _chipFilter;

  @override
  void initState() {
    super.initState();
    _topFilter = widget.initialFilter;
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final result = await ApiService.fetchAmcList();
      if (!mounted) return;
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
    final query = _searchController.text.toLowerCase().trim();

    _filtered = _all.where((amc) {
      // ── Top filter ────────────────────────────────────────────────────────
      if (_topFilter != null) {
        if (amc.isArchive) return false;
        switch (_topFilter!) {
          case AmcTopFilter.active:
            // FIX: must match _countTop — exclude notinterested AND
            // only include records whose amcEndStatus is truly 'active'
            if (amc.optForAmc.toLowerCase() == 'notinterested') return false;
            if (amc.amcEndStatus != 'active') return false;
            break;
          case AmcTopFilter.expiringSoon:
            if (amc.amcEndStatus != 'expiring') return false;
            break;
          case AmcTopFilter.expired:
            if (amc.amcEndStatus != 'expired') return false;
            break;
          case AmcTopFilter.all:
            break;
        }
      }

      // ── Chip filter ───────────────────────────────────────────────────────
      if (_chipFilter != null) {
        switch (_chipFilter!) {
          case AmcChipFilter.inprogress:
            if (amc.status.toLowerCase() != 'inprogress') return false;
            break;
          case AmcChipFilter.notInterested:
            if (amc.optForAmc.toLowerCase() != 'notinterested') return false;
            break;
          case AmcChipFilter.allClients:
            break;
          case AmcChipFilter.archived:
            if (!amc.isArchive) return false;
            break;
          case AmcChipFilter.completed:
            if (amc.status.toLowerCase() != 'completed') return false;
            break;
        }
      }

      // ── Search query ──────────────────────────────────────────────────────
      if (query.isEmpty) return true;
      return amc.customer.name.toLowerCase().contains(query) ||
          amc.customer.address.toLowerCase().contains(query) ||
          amc.customer.phone.toLowerCase().contains(query) ||
          amc.amc.type.toLowerCase().contains(query) ||
          amc.assignedEmployee.toLowerCase().contains(query);
    }).toList();
  }

  // ── FIX: _countTop mirrors _applyFilters exactly ──────────────────────────
  // active now requires amcEndStatus == 'active' so card count == list count.
  int _countTop(AmcTopFilter f) {
    switch (f) {
      case AmcTopFilter.active:
        return _all
            .where(
              (amc) =>
                  !amc.isArchive &&
                  amc.optForAmc.toLowerCase() != 'notinterested' &&
                  amc.amcEndStatus == 'active', // ← was missing before
            )
            .length;

      case AmcTopFilter.expiringSoon:
        return _all
            .where((amc) => !amc.isArchive && amc.amcEndStatus == 'expiring')
            .length;

      case AmcTopFilter.expired:
        return _all
            .where((amc) => !amc.isArchive && amc.amcEndStatus == 'expired')
            .length;

      case AmcTopFilter.all:
        return _all.length;
    }
  }

  int _countChip(AmcChipFilter f) {
    switch (f) {
      case AmcChipFilter.inprogress:
        return _summary['inprogress'] ?? 0;
      case AmcChipFilter.notInterested:
        return _summary['notinterested'] ?? 0;
      case AmcChipFilter.allClients:
        return _all.length;
      case AmcChipFilter.archived:
        return _summary['isarchive'] ?? 0;
      case AmcChipFilter.completed:
        return _summary['completed'] ?? 0;
    }
  }

  // ── FIX: accent color derived from the AMC record, not the filter ─────────
  // Used only for list-level styling; detail sheet gets its own per-record color.
  Color get _accentColor {
    if (_topFilter != null) {
      switch (_topFilter!) {
        case AmcTopFilter.active:
          return const Color(0xFF10B981);
        case AmcTopFilter.expiringSoon:
          return const Color(0xFFF59E0B);
        case AmcTopFilter.expired:
          return const Color(0xFFEF4444);
        case AmcTopFilter.all:
          return const Color(0xFF3B82F6);
      }
    }
    switch (_chipFilter) {
      case AmcChipFilter.archived:
        return const Color(0xFFD89C2C);
      case AmcChipFilter.completed:
        return const Color(0xFF8B5CF6);
      case AmcChipFilter.notInterested:
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  // ── FIX: per-record accent color for the detail sheet ────────────────────
  // Previously _accentColor (filter-level) was passed, causing the sheet to
  // show the wrong color when viewing e.g. an expired AMC from the Active list.
  Color _recordAccentColor(AmcModel amc) {
    switch (amc.amcEndStatus) {
      case 'active':
        return const Color(0xFF10B981);
      case 'expiring':
        return const Color(0xFFF59E0B);
      case 'expired':
        return const Color(0xFFEF4444);
      case 'completed':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  bool get _isChipFilterActive => _chipFilter != null;

  void _onTopFilterTap(AmcTopFilter f) {
    setState(() {
      _topFilter = f;
      _chipFilter = null;
      _applyFilters();
    });
  }

  void _onChipFilterTap(AmcChipFilter f) {
    setState(() {
      _chipFilter = (_chipFilter == f) ? null : f;
      _topFilter = null;
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
                    'Workflow filters',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AmcChipFilter.values.map((f) {
                      const labels = {
                        AmcChipFilter.inprogress: 'In Progress',
                        AmcChipFilter.notInterested: 'Not Interested',
                        AmcChipFilter.allClients: 'All Clients',
                        AmcChipFilter.archived: 'Archived',
                        AmcChipFilter.completed: 'Completed',
                      };
                      const colors = {
                        AmcChipFilter.inprogress: Color(0xFF3B82F6),
                        AmcChipFilter.notInterested: Color(0xFF64748B),
                        AmcChipFilter.allClients: Color(0xFF3B82F6),
                        AmcChipFilter.archived: Color(0xFFD89C2C),
                        AmcChipFilter.completed: Color(0xFF8B5CF6),
                      };
                      final color = colors[f]!;
                      final isSelected = _chipFilter == f;
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() {});
                          _onChipFilterTap(f);
                          Navigator.pop(context);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? color : color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : color.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            '${labels[f]} (${_countChip(f)})',
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
                  if (_chipFilter != null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _topFilter = widget.initialFilter;
                            _chipFilter = null;
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

  // ── FIX: pass per-record color to detail sheet, not filter-level color ────
  void _showDetail(AmcModel amc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => AmcDetailSheet(
        amc: amc,
        accentColor: _recordAccentColor(amc), // ← was _accentColor
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'AMC List',
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
                    for (final f in AmcTopFilter.values) f: _countTop(f),
                  },
                  selected: _chipFilter == null ? _topFilter : null,
                  onTap: _onTopFilterTap,
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
                              color: _isChipFilterActive
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
                                    color: _isChipFilterActive
                                        ? Colors.white
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                            if (_isChipFilterActive)
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
                          // ── FIX: capture amc locally so the closure is
                          // stable even if _filtered mutates during rebuild
                          itemBuilder: (_, i) {
                            final amc = _filtered[i];
                            return _PersonTile(
                              // ── FIX: compound key prevents collisions when
                              // two records share the same id (API duplicates)
                              key: ValueKey('${amc.id}_${amc.customer.phone}'),
                              amc: amc,
                              accentColor: _accentColor,
                              onTap: () => _showDetail(amc),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

// ── Stat cards ────────────────────────────────────────────────────────────────

class _TopCards extends StatelessWidget {
  final Map<AmcTopFilter, int> counts;
  final AmcTopFilter? selected;
  final ValueChanged<AmcTopFilter> onTap;

  const _TopCards({
    required this.counts,
    required this.selected,
    required this.onTap,
  });

  static const _labels = {
    AmcTopFilter.active: 'Active AMC',
    AmcTopFilter.expiringSoon: 'Expiring Soon',
    AmcTopFilter.expired: 'Expired',
    AmcTopFilter.all: 'AMC Database',
  };

  static const _colors = {
    AmcTopFilter.active: Color(0xFF10B981),
    AmcTopFilter.expiringSoon: Color(0xFFF59E0B),
    AmcTopFilter.expired: Color(0xFFEF4444),
    AmcTopFilter.all: Color(0xFF3B82F6),
  };

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Row(
          children: AmcTopFilter.values.map((f) {
            final color = _colors[f]!;
            final isSelected = selected == f;
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
                    color: isSelected
                        ? color.withOpacity(0.12)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1,
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
                          color: isSelected ? color : Colors.grey[600],
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
    );
  }
}

// ── Person tile ───────────────────────────────────────────────────────────────

class _PersonTile extends StatelessWidget {
  final AmcModel amc;
  final Color accentColor;
  final VoidCallback onTap;

  const _PersonTile({
    super.key,
    required this.amc,
    required this.accentColor,
    required this.onTap,
  });

  Color _dotColor(String status) {
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
                    backgroundColor: accentColor.withOpacity(0.14),
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
                        color: _dotColor(amc.amcEndStatus),
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
