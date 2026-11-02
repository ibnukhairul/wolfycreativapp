import 'order_status.dart';

class Customer {
  final String id;
  final String name;
  final String whatsapp;
  final String? instagram;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int totalOrders;
  final num totalSpent;

  Customer({
    required this.id,
    required this.name,
    required this.whatsapp,
    this.instagram,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.totalOrders = 0,
    this.totalSpent = 0,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      whatsapp: json['whatsapp'] as String? ?? '',
      instagram: json['instagram'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      totalOrders: json['total_order'] != null ? (json['total_order'] as num).toInt() : 0,
      totalSpent: json['total_spent'] as num? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'whatsapp': whatsapp,
      'instagram': instagram,
      'notes': notes,
    };
  }
}

class ServiceItem {
  final String id;
  final String name;
  final num defaultPrice;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ServiceItem({
    required this.id,
    required this.name,
    required this.defaultPrice,
    this.createdAt,
    this.updatedAt,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      defaultPrice: json['default_price'] as num? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'default_price': defaultPrice,
    };
  }
}

class OrderModel {
  final String id;
  final String invoiceNumber;
  final String customerId;
  final String serviceId;
  final num price;
  final String orderDate;
  final String deadline;
  final OrderStatus status;
  final String? notes;
  final String portalToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined fields
  final String? customerName;
  final String? customerWhatsapp;
  final String? serviceName;
  final num totalPaid;
  final num remaining;

  OrderModel({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.serviceId,
    required this.price,
    required this.orderDate,
    required this.deadline,
    required this.status,
    this.notes,
    required this.portalToken,
    this.createdAt,
    this.updatedAt,
    this.customerName,
    this.customerWhatsapp,
    this.serviceName,
    this.totalPaid = 0,
    this.remaining = 0,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customers'] as Map<String, dynamic>?;
    final service = json['services'] as Map<String, dynamic>?;
    final payments = json['payments'] as List<dynamic>?;
    
    num paid = 0;
    if (json['total_paid'] != null) {
      paid = json['total_paid'] as num;
    } else if (payments != null) {
      paid = payments.fold(0, (sum, p) => sum + (p['amount'] as num? ?? 0));
    }

    final pPrice = json['price'] as num? ?? 0;
    final pRemaining = json['remaining'] != null ? json['remaining'] as num : (pPrice - paid);

    return OrderModel(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? '',
      serviceId: json['service_id'] as String? ?? '',
      price: pPrice,
      orderDate: json['order_date'] as String? ?? '',
      deadline: json['deadline'] as String? ?? '',
      status: OrderStatus.fromString(json['status'] as String?),
      notes: json['notes'] as String?,
      portalToken: json['portal_token'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      customerName: customer?['name'] as String? ?? json['customer_name'] as String?,
      customerWhatsapp: customer?['whatsapp'] as String?,
      serviceName: service?['name'] as String? ?? json['service_name'] as String?,
      totalPaid: paid,
      remaining: pRemaining,
    );
  }

  /// Payment status badge category
  String get paymentStatus {
    if (price <= 0) return 'Lunas';
    if (totalPaid >= price) return 'Lunas';
    if (totalPaid > 0) return 'DP';
    return 'Belum Bayar';
  }

  bool get isBelumBayar => paymentStatus == 'Belum Bayar';
  bool get isDp => paymentStatus == 'DP';
  bool get isLunas => paymentStatus == 'Lunas';
}

class TodoItem {
  final String id;
  final String invoiceNumber;
  final String customerName;
  final String serviceName;
  final String deadline;
  final OrderStatus status;
  final int daysLeft;

  TodoItem({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    required this.serviceName,
    required this.deadline,
    required this.status,
    required this.daysLeft,
  });

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      serviceName: json['service_name'] as String? ?? '',
      deadline: json['deadline'] as String? ?? '',
      status: OrderStatus.fromString(json['status'] as String?),
      daysLeft: json['days_left'] as int? ?? 0,
    );
  }
}

class DashboardStats {
  final int totalBaru;
  final int totalProses;
  final int totalSelesai;
  final num revenue;
  final num receivables;

  DashboardStats({
    required this.totalBaru,
    required this.totalProses,
    required this.totalSelesai,
    required this.revenue,
    required this.receivables,
  });
}

class PaymentModel {
  final String id;
  final String orderId;
  final num amount;
  final String paidAt;
  final String? note;
  final String? accountId;
  final DateTime? createdAt;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.paidAt,
    this.note,
    this.accountId,
    this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      amount: json['amount'] as num? ?? 0,
      paidAt: json['paid_at'] as String? ?? '',
      note: json['note'] as String?,
      accountId: json['account_id'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}

class PersonalTodo {
  final String id;
  final String title;
  final bool isDone;
  final DateTime? createdAt;
  final DateTime? completedAt;

  PersonalTodo({
    required this.id,
    required this.title,
    required this.isDone,
    this.createdAt,
    this.completedAt,
  });

  factory PersonalTodo.fromJson(Map<String, dynamic> json) {
    return PersonalTodo(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      isDone: json['is_done'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at']) : null,
    );
  }
}

class OrderFileModel {
  final String id;
  final String orderId;
  final String kind; // 'preview' | 'final'
  final String storagePath;
  final String fileName;
  final DateTime? createdAt;

  OrderFileModel({
    required this.id,
    required this.orderId,
    required this.kind,
    required this.storagePath,
    required this.fileName,
    this.createdAt,
  });

  factory OrderFileModel.fromJson(Map<String, dynamic> json) {
    return OrderFileModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      kind: json['kind'] as String? ?? 'preview',
      storagePath: json['storage_path'] as String? ?? '',
      fileName: json['file_name'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}
