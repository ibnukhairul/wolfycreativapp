import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../orders/providers/order_providers.dart';
import '../providers/finance_providers.dart';
import '../repositories/finance_repository.dart';

const List<String> kExpenseCategories = [
  'Bahan Baku',
  'Printer',
  'Internet',
  'Hosting',
  'Domain',
  'Software',
  'Operasional',
  'Lainnya',
];

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  void _showExpenseDialog(BuildContext context, WidgetRef ref, [BusinessExpenseItem? item]) {
    final isEdit = item != null;
    String selectedCategory = item?.category ?? kExpenseCategories.first;
    final amountCtrl = TextEditingController(
      text: item != null ? item.amount.toStringAsFixed(0) : '',
    );
    final descCtrl = TextEditingController(text: item?.description ?? '');
    DateTime expenseDate = item != null ? DateTime.tryParse(item.expenseDate) ?? DateTime.now() : DateTime.now();
    String? selectedAccountId = item?.accountId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final accountsAsync = ref.watch(personalAccountsListProvider);

            return StatefulBuilder(
              builder: (context, setModalState) {
                return SafeArea(
                  child: Container(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              isEdit ? 'Edit Pengeluaran Bisnis' : 'Catat Pengeluaran Bisnis',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMain,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Kategori Dropdown
                            const Text('Kategori', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: selectedCategory,
                              decoration: const InputDecoration(),
                              items: kExpenseCategories.map((c) {
                                return DropdownMenuItem(value: c, child: Text(c));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => selectedCategory = val);
                              },
                            ),
                            const SizedBox(height: 14),

                            // Nominal
                            const Text('Jumlah Pengeluaran (Rp)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: amountCtrl,
                              keyboardType: TextInputType.number,
                              autofocus: !isEdit,
                              style: AppTheme.monoStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              decoration: const InputDecoration(
                                prefixText: 'Rp ',
                                hintText: '100.000',
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Deskripsi
                            const Text('Deskripsi / Catatan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: descCtrl,
                              decoration: const InputDecoration(hintText: 'Beli tinta, perpanjang domain, dll.'),
                            ),
                            const SizedBox(height: 14),

                            // Tanggal
                            const Text('Tanggal Pengeluaran', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: expenseDate,
                                  firstDate: DateTime(2024),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setModalState(() => expenseDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textMuted),
                                    const SizedBox(width: 8),
                                    Text(formatDate(expenseDate), style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Bayar dari Dompet Pribadi
                            const Text('Bayar dari Dompet Pribadi (Opsional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            accountsAsync.when(
                              data: (accounts) {
                                return DropdownButtonFormField<String?>(
                                  initialValue: selectedAccountId,
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 20),
                                  ),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('Tidak dicatat ke dompet'),
                                    ),
                                    ...accounts.map(
                                      (a) => DropdownMenuItem<String?>(
                                        value: a['id'] as String,
                                        child: Text('${a['name']} (${formatCurrency(a['balance'] as num)})'),
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    setModalState(() => selectedAccountId = val);
                                  },
                                );
                              },
                              loading: () => const LinearProgressIndicator(),
                              error: (e, _) => Text('Gagal: $e'),
                            ),
                            const SizedBox(height: 20),

                            ElevatedButton(
                              onPressed: () async {
                                final amount = num.tryParse(amountCtrl.text) ?? 0;
                                if (amount <= 0) return;
                                Navigator.pop(ctx);

                                final dateStr = DateFormat('yyyy-MM-dd').format(expenseDate);
                                try {
                                  final repo = ref.read(financeRepositoryProvider);
                                  if (isEdit) {
                                    await repo.updateExpense(
                                      id: item.id,
                                      category: selectedCategory,
                                      description: descCtrl.text,
                                      amount: amount,
                                      expenseDate: dateStr,
                                      accountId: selectedAccountId,
                                    );
                                  } else {
                                    await repo.addExpense(
                                      category: selectedCategory,
                                      description: descCtrl.text,
                                      amount: amount,
                                      expenseDate: dateStr,
                                      accountId: selectedAccountId,
                                    );
                                  }
                                  ref.invalidate(profitSummaryProvider);
                                  ref.invalidate(businessExpensesProvider);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Gagal menyimpan pengeluaran: $e'),
                                        backgroundColor: AppColors.destructive,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Simpan Pengeluaran'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(profitSummaryProvider);
    final expensesAsync = ref.watch(businessExpensesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Keuangan Bisnis'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExpenseDialog(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Pengeluaran', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(profitSummaryProvider);
            ref.invalidate(businessExpensesProvider);
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 3 Profit Summary Cards (PRD §6.11)
                summaryAsync.when(
                  data: (s) => Row(
                    children: [
                      Expanded(
                        child: _summaryCard('Pendapatan', s.revenue, AppColors.statusSelesai),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _summaryCard('Pengeluaran', s.expenses, AppColors.destructive),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _summaryCard('Laba Bersih', s.profit, s.profit >= 0 ? AppColors.primary : AppColors.destructive),
                      ),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Gagal memuat ringkasan: $e'),
                ),
                const SizedBox(height: 20),

                // Expenses Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 0.8),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Riwayat Pengeluaran',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMain,
                              ),
                            ),
                            expensesAsync.maybeWhen(
                              data: (list) => Text(
                                '${list.length} transaksi',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                              orElse: () => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.divider),

                      expensesAsync.when(
                        data: (expenses) {
                          if (expenses.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                'Belum ada catatan pengeluaran bisnis.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: expenses.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.divider),
                            itemBuilder: (context, idx) {
                              final item = expenses[idx];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primarySoft,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  item.category,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                formatDate(item.expenseDate),
                                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                              ),
                                            ],
                                          ),
                                          if (item.description != null && item.description!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              item.description!,
                                              style: const TextStyle(fontSize: 13, color: AppColors.textMain),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          formatCurrency(item.amount),
                                          style: AppTheme.monoStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.destructive,
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textMuted),
                                              onPressed: () => _showExpenseDialog(context, ref, item),
                                            ),
                                            const SizedBox(width: 10),
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.textMuted),
                                              onPressed: () async {
                                                final confirmed = await showDialog<bool>(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: const Text('Hapus Pengeluaran?'),
                                                    content: const Text('Saldo dompet akan disesuaikan jika pengeluaran ini dibayar dari dompet.'),
                                                    actions: [
                                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                                      ElevatedButton(
                                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.destructive),
                                                        onPressed: () => Navigator.pop(ctx, true),
                                                        child: const Text('Hapus'),
                                                      ),
                                                    ],
                                                  ),
                                                );

                                                if (confirmed == true) {
                                                  await ref.read(financeRepositoryProvider).deleteExpense(item.id);
                                                  ref.invalidate(profitSummaryProvider);
                                                  ref.invalidate(businessExpensesProvider);
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
                        error: (err, _) => Padding(padding: const EdgeInsets.all(16), child: Text('Gagal: $err')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 70),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(String label, num amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.4),
          ),
          const SizedBox(height: 4),
          Text(
            formatCurrency(amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.monoStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
