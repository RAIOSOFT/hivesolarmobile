class AmcCustomer {
  final String name;
  final String phone;
  final String address;
  final String address1;
  final String priority; // 'highvaluecustomer' shows a star icon

  const AmcCustomer({
    required this.name,
    required this.phone,
    required this.address,
    required this.address1,
    required this.priority,
  });

  factory AmcCustomer.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AmcCustomer(
        name: 'N/A',
        phone: '',
        address: '',
        address1: '',
        priority: '',
      );
    }
    return AmcCustomer(
      name: json['name']?.toString() ?? 'N/A',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      address1: json['address1']?.toString() ?? '',
      priority: json['priority']?.toString() ?? '',
    );
  }
}

// ── Product purchase info ─────────────────────────────────────────────────────

class AmcProduct {
  final String billDate; // epoch ms as string
  final List<Map<String, dynamic>> products; // list of product objects

  const AmcProduct({required this.billDate, required this.products});

  factory AmcProduct.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AmcProduct(billDate: '', products: []);
    return AmcProduct(
      billDate: _toEpochString(json['billDate']),
      products: json['products'] != null
          ? List<Map<String, dynamic>>.from(json['products'])
          : const [],
    );
  }
}

// ── AMC contract details ──────────────────────────────────────────────────────

class AmcDetail {
  final String amcDate; // AMC bill date — epoch ms as string
  final String endDate; // AMC end date — epoch ms as string
  final String type; // 'quarterly' or 'halfyearly'
  final String route; // document ID from amc-routes collection
  final String amount; // raw amount string — '0' means free
  final String validity; // validity in years e.g. '1', '0.5'
  final List<String> schedule; // list of schedule period strings

  const AmcDetail({
    required this.amcDate,
    required this.endDate,
    required this.type,
    required this.route,
    required this.amount,
    required this.validity,
    required this.schedule,
  });

  factory AmcDetail.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AmcDetail(
        amcDate: '',
        endDate: '',
        type: '',
        route: '',
        amount: '',
        validity: '',
        schedule: [],
      );
    }

    // Route can be stored two ways in Firestore:
    //   1. A plain string ID:  "abc123"
    //   2. A Map with id key: { "id": "abc123", "name": "..." }
    // Angular handles this as: detail?.amc?.route?.id || detail?.amc?.route
    final rawRoute = json['route'];
    final route = rawRoute is Map
        ? (rawRoute['id'] ?? '').toString()
        : (rawRoute?.toString() ?? '');

    return AmcDetail(
      amcDate: _toEpochString(json['amcDate']),
      endDate: _toEpochString(json['endDate']),
      type: json['type']?.toString() ?? '',
      route: route,
      amount: json['amount']?.toString() ?? '0',
      validity: json['validity']?.toString() ?? '',
      schedule: json['schedule'] != null
          ? List<String>.from(json['schedule'])
          : const [],
    );
  }
}

// ── Date helper ───────────────────────────────────────────────────────────────
//
// Firestore / API can send dates in several formats. This function normalises
// all of them into a single epoch-ms string so the UI can always use
// DateTime.fromMillisecondsSinceEpoch() without worrying about the format.
//
// Supported inputs:
//   • int    — already epoch ms           → "1700000000000"
//   • double — large ints as float        → "1700000000000"
//   • String — numeric epoch ms           → returned as-is
//   • String — ISO date "2024-01-15"      → converted to epoch ms
//   • null   — nothing to parse           → ""

String _toEpochString(dynamic raw) {
  if (raw == null) return '';
  if (raw is int) return raw.toString();
  if (raw is double) return raw.toInt().toString();
  final str = raw.toString().trim();
  if (str.isEmpty) return '';
  if (int.tryParse(str) != null) return str; // already epoch string
  final dt = DateTime.tryParse(str);
  if (dt != null) return dt.millisecondsSinceEpoch.toString();
  return '';
}

// ── Main AMC record model ─────────────────────────────────────────────────────

class AmcModel {
  final String id;
  final bool isDeleted;
  final bool isArchive;
  final String status; // 'inprogress', 'completed', 'visited', ''
  final String optForAmc; // 'Yes' or 'notinterested'
  final String assignedEmployee; // user document ID

  final AmcCustomer customer;
  final AmcProduct product;
  final AmcDetail amc;

  // Comments — list of maps each containing: bywhom, cdate, comments
  // Sorted newest-first to match Angular's .slice().reverse()
  final List<Map<String, dynamic>> comments;

  // Computed fields — set once in the constructor, never change
  late final String amcEndStatus; // 'active', 'expiring', 'expired', 'unknown'
  late final String displayAmount; // '₹1500' or 'Free'

  AmcModel({
    required this.id,
    required this.isDeleted,
    required this.isArchive,
    required this.status,
    required this.optForAmc,
    required this.assignedEmployee,
    required this.customer,
    required this.product,
    required this.amc,
    required this.comments,
  }) {
    amcEndStatus = _computeEndStatus();
    displayAmount = _computeDisplayAmount();
  }

  factory AmcModel.fromJson(Map<String, dynamic> json) {
    // Parse comments array and sort newest first
    final rawComments = json['comments'];
    List<Map<String, dynamic>> comments = [];
    if (rawComments is List) {
      comments =
          rawComments
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
            ..sort((a, b) {
              final aDate = (a['cdate'] as int?) ?? 0;
              final bDate = (b['cdate'] as int?) ?? 0;
              return bDate.compareTo(aDate); // newest first
            });
    }

    return AmcModel(
      id: json['id']?.toString() ?? '',
      isDeleted: json['isdeleted'] == true,
      isArchive: json['isarchive'] == true,
      // Keep raw values — filters use .toLowerCase() at comparison time
      status: json['status']?.toString() ?? '',
      optForAmc: json['optforamc']?.toString() ?? '',
      assignedEmployee: json['assignedemployee']?.toString() ?? '',
      customer: AmcCustomer.fromJson(json['customer'] as Map<String, dynamic>?),
      product: AmcProduct.fromJson(json['product'] as Map<String, dynamic>?),
      amc: AmcDetail.fromJson(json['amc'] as Map<String, dynamic>?),
      comments: comments,
    );
  }

  // Mirrors Angular's getAmcStatus() function exactly
  String _computeEndStatus() {
    if (amc.endDate.isEmpty) return 'unknown';
    final ms = int.tryParse(amc.endDate);
    if (ms == null) return 'unknown';
    final endDate = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final oneMonthLater = DateTime(now.year, now.month + 1, now.day);
    if (endDate.isBefore(now)) return 'expired';
    if (endDate.isBefore(oneMonthLater)) return 'expiring';
    return 'active';
  }

  // Mirrors Angular's amount display logic:
  // amount === '0' || amount === 0 ? 'Free' : currency format
  String _computeDisplayAmount() {
    if (amc.amount == '0' || amc.amount.isEmpty) return 'Free';
    return '₹${amc.amount}';
  }
}
