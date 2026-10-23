import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PersonalAccountModel {
  final String id;
  final String name;
  final num balance;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PersonalAccountModel({
    required this.id,
    required this.name,
    required this.balance,
    this.createdAt,
    this.updatedAt,
  });

  factory PersonalAccountModel.fromJson(Map<String, dynamic> json) {
    return PersonalAccountModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      balance: json['balance'] as num? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }
}

class PersonalTransactionModel {
  final String id;
  final String accountId;
  final String type; // 'masuk' | 'keluar'
  final String category;
  final num amount;
  final String trxDate;
  final String? note;
  final bool isTransfer;
  final String? accountName;
  final DateTime? createdAt;

  PersonalTransactionModel({
    required this.id,
    required this.accountId,
    required this.type,
    required this.category,
    required this.amount,
    required this.trxDate,
    this.note,
    required this.isTransfer,
    this.accountName,
    this.createdAt,
  });

  factory PersonalTransactionModel.fromJson(Map<String, dynamic> json) {
    final account = json['account'] as Map<String, dynamic>?;
    return PersonalTransactionModel(
      id: json['id'] as String,
      accountId: json['account_id'] as String? ?? '',
      type: json['type'] as String? ?? 'keluar',
      category: json['category'] as String? ?? 'Lainnya',
      amount: json['amount'] as num? ?? 0,
      trxDate: json['trx_date'] as String? ?? '',
      note: json['note'] as String?,
      isTransfer: json['is_transfer'] as bool? ?? false,
      accountName: account?['name'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}

class PersonalMonthlySummary {
  final num totalMasuk;
  final num totalKeluar;
  final List<({String category, num total})> categories;

  PersonalMonthlySummary({
    required this.totalMasuk,
    required this.totalKeluar,
    required this.categories,
  });
}

class PersonalFinanceRepository {
  final SupabaseClient _client;

  PersonalFinanceRepository(this._client);

  /// Fetch PIN hash from personal_finance_lock
  Future<String?> getPinHash() async {
    final res = await _client
        .from('personal_finance_lock')
        .select('pin_hash')
        .eq('id', true)
        .maybeSingle();

    return res?['pin_hash'] as String?;
  }

  /// Update PIN hash in database
  Future<void> setPinHash(String pinHash) async {
    await _client.from('personal_finance_lock').update({
      'pin_hash': pinHash,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', true);
  }

  /// Get personal wallets/accounts
  Future<List<PersonalAccountModel>> getAccounts() async {
    final response = await _client
        .from('personal_accounts')
        .select('*')
        .order('name', ascending: true);

    return (response as List<dynamic>)
        .map((a) => PersonalAccountModel.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  Future<void> createAccount(String name, num balance) async {
    await _client.from('personal_accounts').insert({
      'name': name.trim(),
      'balance': balance,
    });
  }

  Future<void> updateAccount(String id, String name, num balance) async {
    await _client.from('personal_accounts').update({
      'name': name.trim(),
      'balance': balance,
    }).eq('id', id);
  }

  Future<void> deleteAccount(String id) async {
    await _client.from('personal_accounts').delete().eq('id', id);
  }

  /// Get recent transactions with account name
  Future<List<PersonalTransactionModel>> getTransactions({int limit = 50}) async {
    final response = await _client
        .from('personal_transactions')
        .select('*, account:personal_accounts(name)')
        .order('trx_date', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List<dynamic>)
        .map((t) => PersonalTransactionModel.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  /// Add personal transaction via RPC
  Future<void> addTransaction({
    required String accountId,
    required String type,
    required String category,
    required num amount,
    required String trxDate,
    String? note,
  }) async {
    await _client.rpc('add_personal_transaction', params: {
      'p_account_id': accountId,
      'p_type': type,
      'p_category': category.trim(),
      'p_amount': amount,
      'p_trx_date': trxDate,
      'p_note': note?.trim().isEmpty == true ? null : note?.trim(),
    });
  }

  /// Delete transaction via RPC
  Future<void> deleteTransaction(String transactionId) async {
    await _client.rpc('delete_personal_transaction', params: {
      'p_transaction_id': transactionId,
    });
  }

  /// Transfer between wallets via RPC
  Future<void> transferBetweenAccounts({
    required String fromAccountId,
    required String toAccountId,
    required num amount,
    required String trxDate,
    String? note,
  }) async {
    await _client.rpc('transfer_between_accounts', params: {
      'p_from_account_id': fromAccountId,
      'p_to_account_id': toAccountId,
      'p_amount': amount,
      'p_trx_date': trxDate,
      'p_note': note?.trim().isEmpty == true ? null : note?.trim(),
    });
  }

  /// Monthly summary excluding transfer transactions (PRD §4.4)
  Future<PersonalMonthlySummary> getMonthlySummary() async {
    final now = DateTime.now();
    final start = DateFormat('yyyy-MM-01').format(now);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final end = DateFormat('yyyy-MM-dd').format(lastDay);

    final response = await _client
        .from('personal_transactions')
        .select('type, category, amount')
        .eq('is_transfer', false)
        .gte('trx_date', start)
        .lte('trx_date', end);

    final list = response as List<dynamic>;
    num masuk = 0;
    num keluar = 0;
    final Map<String, num> catMap = {};

    for (final t in list) {
      final type = t['type'] as String? ?? 'keluar';
      final amt = t['amount'] as num? ?? 0;
      final cat = t['category'] as String? ?? 'Lainnya';

      if (type == 'masuk') {
        masuk += amt;
      } else {
        keluar += amt;
        catMap[cat] = (catMap[cat] ?? 0) + amt;
      }
    }

    final catList = catMap.entries
        .map((e) => (category: e.key, total: e.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    return PersonalMonthlySummary(
      totalMasuk: masuk,
      totalKeluar: keluar,
      categories: catList,
    );
  }
}
