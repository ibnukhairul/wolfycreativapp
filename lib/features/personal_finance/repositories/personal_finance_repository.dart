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

class PersonalCategoryReport {
  final String category;
  final String type; // 'masuk' | 'keluar'
  final num total;
  final int count;

  PersonalCategoryReport({
    required this.category,
    required this.type,
    required this.total,
    required this.count,
  });
}

class PersonalAccountReport {
  final String accountId;
  final String accountName;
  final num masuk;
  final num keluar;
  final num net;

  PersonalAccountReport({
    required this.accountId,
    required this.accountName,
    required this.masuk,
    required this.keluar,
    required this.net,
  });
}

class PersonalDailyFlow {
  final String date;
  final num masuk;
  final num keluar;

  PersonalDailyFlow({
    required this.date,
    required this.masuk,
    required this.keluar,
  });
}

class PersonalMonthlyReportData {
  final String monthKey;
  final num totalMasuk;
  final num totalKeluar;
  final num net;
  final int count;
  final List<PersonalCategoryReport> byCategory;
  final List<PersonalAccountReport> byAccount;
  final List<PersonalDailyFlow> dailyFlow;
  final List<PersonalTransactionModel> transactions;

  PersonalMonthlyReportData({
    required this.monthKey,
    required this.totalMasuk,
    required this.totalKeluar,
    required this.net,
    required this.count,
    required this.byCategory,
    required this.byAccount,
    required this.dailyFlow,
    required this.transactions,
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

  /// Get comprehensive monthly report matching web version
  Future<PersonalMonthlyReportData> getMonthlyReport(DateTime monthDate) async {
    final monthKey = DateFormat('yyyy-MM').format(monthDate);
    final start = DateFormat('yyyy-MM-01').format(monthDate);
    final lastDay = DateTime(monthDate.year, monthDate.month + 1, 0);
    final end = DateFormat('yyyy-MM-dd').format(lastDay);

    final response = await _client
        .from('personal_transactions')
        .select('*, account:personal_accounts(name)')
        .gte('trx_date', start)
        .lte('trx_date', end)
        .order('trx_date', ascending: true)
        .order('created_at', ascending: true);

    final txList = (response as List<dynamic>)
        .map((t) => PersonalTransactionModel.fromJson(t as Map<String, dynamic>))
        .toList();

    final Map<String, ({String name, num masuk, num keluar})> accountMap = {};
    final Map<String, ({String type, num total, int count})> categoryMap = {};
    final Map<String, ({num masuk, num keluar})> dailyMap = {};

    num totalMasuk = 0;
    num totalKeluar = 0;

    for (final t in txList) {
      final amt = t.amount;
      final accId = t.accountId;
      final accName = t.accountName ?? '—';

      // Account activity (includes transfer)
      final prevAcc = accountMap[accId] ?? (name: accName, masuk: 0, keluar: 0);
      if (t.type == 'masuk') {
        accountMap[accId] = (name: accName, masuk: prevAcc.masuk + amt, keluar: prevAcc.keluar);
      } else {
        accountMap[accId] = (name: accName, masuk: prevAcc.masuk, keluar: prevAcc.keluar + amt);
      }

      // Totals & Categories (exclude transfer)
      if (!t.isTransfer) {
        if (t.type == 'masuk') {
          totalMasuk += amt;
        } else {
          totalKeluar += amt;
        }

        final catKey = '${t.type}::${t.category}';
        final prevCat = categoryMap[catKey] ?? (type: t.type, total: 0, count: 0);
        categoryMap[catKey] = (
          type: t.type,
          total: prevCat.total + amt,
          count: prevCat.count + 1,
        );
      }

      // Daily flow (exclude transfer)
      final prevDay = dailyMap[t.trxDate] ?? (masuk: 0, keluar: 0);
      if (!t.isTransfer) {
        if (t.type == 'masuk') {
          dailyMap[t.trxDate] = (masuk: prevDay.masuk + amt, keluar: prevDay.keluar);
        } else {
          dailyMap[t.trxDate] = (masuk: prevDay.masuk, keluar: prevDay.keluar + amt);
        }
      }
    }

    final byAccount = accountMap.entries
        .map((e) => PersonalAccountReport(
              accountId: e.key,
              accountName: e.value.name,
              masuk: e.value.masuk,
              keluar: e.value.keluar,
              net: e.value.masuk - e.value.keluar,
            ))
        .toList()
      ..sort((a, b) => (b.masuk + b.keluar).compareTo(a.masuk + a.keluar));

    final byCategory = categoryMap.entries
        .map((e) => PersonalCategoryReport(
              category: e.key.split('::')[1],
              type: e.value.type,
              total: e.value.total,
              count: e.value.count,
            ))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    final dailyFlow = dailyMap.entries
        .map((e) => PersonalDailyFlow(
              date: e.key,
              masuk: e.value.masuk,
              keluar: e.value.keluar,
            ))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return PersonalMonthlyReportData(
      monthKey: monthKey,
      totalMasuk: totalMasuk,
      totalKeluar: totalKeluar,
      net: totalMasuk - totalKeluar,
      count: txList.length,
      byCategory: byCategory,
      byAccount: byAccount,
      dailyFlow: dailyFlow,
      transactions: txList,
    );
  }
}
