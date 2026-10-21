import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessProfitSummary {
  final num revenue;
  final num expenses;
  final num profit;

  BusinessProfitSummary({
    required this.revenue,
    required this.expenses,
    required this.profit,
  });

  factory BusinessProfitSummary.fromJson(Map<String, dynamic> json) {
    return BusinessProfitSummary(
      revenue: json['revenue'] as num? ?? 0,
      expenses: json['expenses'] as num? ?? 0,
      profit: json['profit'] as num? ?? 0,
    );
  }
}

class BusinessExpenseItem {
  final String id;
  final String category;
  final String? description;
  final num amount;
  final String expenseDate;
  final String? accountId;
  final DateTime? createdAt;

  BusinessExpenseItem({
    required this.id,
    required this.category,
    this.description,
    required this.amount,
    required this.expenseDate,
    this.accountId,
    this.createdAt,
  });

  factory BusinessExpenseItem.fromJson(Map<String, dynamic> json) {
    return BusinessExpenseItem(
      id: json['id'] as String,
      category: json['category'] as String? ?? 'Operasional',
      description: json['description'] as String?,
      amount: json['amount'] as num? ?? 0,
      expenseDate: json['expense_date'] as String? ?? '',
      accountId: json['account_id'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}

class FinanceRepository {
  final SupabaseClient _client;

  FinanceRepository(this._client);

  Future<BusinessProfitSummary> getProfitSummary() async {
    final response =
        await _client.from('v_profit_this_month').select('*').single();
    return BusinessProfitSummary.fromJson(response);
  }

  Future<List<BusinessExpenseItem>> getExpenses() async {
    final response = await _client
        .from('expenses')
        .select('*')
        .order('expense_date', ascending: false);

    return (response as List<dynamic>)
        .map((e) => BusinessExpenseItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addExpense({
    required String category,
    String? description,
    required num amount,
    required String expenseDate,
    String? accountId,
  }) async {
    await _client.rpc('add_business_expense', params: {
      'p_category': category.trim(),
      'p_description': description?.trim().isEmpty == true ? null : description?.trim(),
      'p_amount': amount,
      'p_expense_date': expenseDate,
      'p_account_id': accountId,
    });
  }

  Future<void> updateExpense({
    required String id,
    required String category,
    String? description,
    required num amount,
    required String expenseDate,
    String? accountId,
  }) async {
    await _client.rpc('update_business_expense', params: {
      'p_expense_id': id,
      'p_category': category.trim(),
      'p_description': description?.trim().isEmpty == true ? null : description?.trim(),
      'p_amount': amount,
      'p_expense_date': expenseDate,
      'p_account_id': accountId,
    });
  }

  Future<void> deleteExpense(String id) async {
    await _client.rpc('delete_business_expense', params: {
      'p_expense_id': id,
    });
  }
}
