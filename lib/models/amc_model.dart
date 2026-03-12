class AmcCustomer {
  final String name;
  final String phone;
  final String address;
  final String address1;
  final String priority;

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

class AmcProduct {
  final String billDate;
  final List<Map<String, dynamic>> products;

  const AmcProduct({required this.billDate, required this.products});

  factory AmcProduct.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AmcProduct(billDate: '', products: []);
    return AmcProduct(
      billDate: json['billDate']?.toString() ?? '',
      products: json['products'] != null
          ? List<Map<String, dynamic>>.from(json['products'])
          : const [],
    );
  }
}

class AmcDetail {
  final String amcDate;
  final String endDate;
  final String type;
  final String route;
  final String amount;
  final String validity;
  final List<String> schedule;

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
    return AmcDetail(
      amcDate: json['amcDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      route: json['route']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0',
      validity: json['validity']?.toString() ?? '',
      schedule: json['schedule'] != null
          ? List<String>.from(json['schedule'])
          : const [],
    );
  }
}

class AmcModel {
  final String id;
  final bool isDeleted;
  final bool isArchive;
  final String status;
  final String optForAmc;
  final String assignedEmployee;
  final AmcCustomer customer;
  final AmcProduct product;
  final AmcDetail amc;
  late final String amcEndStatus;
  late final String displayAmount;

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
  }) {
    // Compute once here — never recomputed during UI builds
    amcEndStatus = _computeEndStatus();
    displayAmount = _computeDisplayAmount();
  }

  factory AmcModel.fromJson(Map<String, dynamic> json) {
    return AmcModel(
      id: json['id']?.toString() ?? '',
      isDeleted: json['isdeleted'] == true,
      isArchive: json['isarchive'] == true,
      status: json['status']?.toString() ?? '',
      optForAmc: json['optforamc']?.toString() ?? '',
      assignedEmployee: json['assignedemployee']?.toString() ?? '',
      customer: AmcCustomer.fromJson(json['customer'] as Map<String, dynamic>?),
      product: AmcProduct.fromJson(json['product'] as Map<String, dynamic>?),
      amc: AmcDetail.fromJson(json['amc'] as Map<String, dynamic>?),
    );
  }

  // Private — called once in constructor
  String _computeEndStatus() {
    if (amc.endDate.isEmpty) return 'unknown';

    DateTime? endDate;
    final ms = int.tryParse(amc.endDate);
    if (ms != null) {
      endDate = DateTime.fromMillisecondsSinceEpoch(ms);
    } else {
      endDate = DateTime.tryParse(amc.endDate);
    }
    if (endDate == null) return 'unknown';

    final now = DateTime.now();
    final oneMonthLater = DateTime(now.year, now.month + 1, now.day);

    if (endDate.isBefore(now)) return 'expired';
    if (endDate.isBefore(oneMonthLater)) return 'expiring';
    return 'active';
  }

  String _computeDisplayAmount() {
    if (amc.amount == '0' || amc.amount.isEmpty) return 'Free';
    return '₹${amc.amount}';
  }
}
