import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/error_handler.dart';
import '../providers/personal_finance_providers.dart';
import '../repositories/personal_finance_repository.dart';

const List<String> kPersonalCategorySuggestions = [
  'Gaji',
  'Freelance',
  'Jajan',
  'Belanja',
  'Transport',
  'Tagihan',
  'Nabung',
  'Lainnya',
];

class PersonalFinanceScreen extends ConsumerStatefulWidget {
  const PersonalFinanceScreen({super.key});

  @override
  ConsumerState<PersonalFinanceScreen> createState() =>
      _PersonalFinanceScreenState();
}

class _PersonalFinanceScreenState extends ConsumerState<PersonalFinanceScreen> {
  final _localAuth = LocalAuthentication();
  final _pinController = TextEditingController();
  bool _isCheckingAuth = false;
  String? _authError;

  @override
  void initState() {
    super.initState();
    _tryBiometricAuth();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometricAuth() async {
    final unlocked = ref.read(personalFinanceUnlockedProvider);
    if (unlocked) return;

    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();

      if (canCheck && isSupported) {
        final didAuth = await _localAuth.authenticate(
          localizedReason: 'Buka akses Keuangan Pribadi',
          biometricOnly: false,
          persistAcrossBackgrounding: true,
        );

        if (didAuth) {
          ref.read(personalFinanceUnlockedProvider.notifier).unlock();
        }
      }
    } catch (_) {
      // Biometrics not available or cancelled, use fallback PIN
    }
  }

  Future<void> _handlePinSubmit() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) return;

    setState(() {
      _isCheckingAuth = true;
      _authError = null;
    });

    try {
      final repo = ref.read(personalFinanceRepositoryProvider);
      final storedHash = await repo.getPinHash();

      final inputHash = sha256.convert(utf8.encode(pin)).toString();

      if (storedHash == null || storedHash.isEmpty || storedHash == inputHash) {
        ref.read(personalFinanceUnlockedProvider.notifier).unlock();
      } else {
        setState(() {
          _authError = 'PIN salah. Coba lagi.';
          _pinController.clear();
        });
      }
    } catch (e) {
      setState(() {
        _authError = 'Gagal memverifikasi: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isCheckingAuth = false);
      }
    }
  }

  void _refreshAll() {
    ref.invalidate(personalAccountsProvider);
    ref.invalidate(personalTransactionsProvider);
    ref.invalidate(personalMonthlySummaryProvider);
  }

  void _showAddTransactionModal([PersonalAccountModel? defaultAccount]) {
    String type = 'keluar';
    PersonalAccountModel? selectedAcc = defaultAccount;
    String category = kPersonalCategorySuggestions.first;
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime trxDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final accountsAsync = ref.watch(personalAccountsProvider);

            return StatefulBuilder(
              builder: (context, setModalState) {
                accountsAsync.whenData((accs) {
                  selectedAcc ??= accs.firstOrNull;
                });

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
                            const Text(
                              'Catat Transaksi Pribadi',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMain,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Segmented Button: Masuk / Keluar
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'keluar',
                                  label: Text('Pengeluaran'),
                                  icon: Icon(Icons.arrow_upward_rounded),
                                ),
                                ButtonSegment(
                                  value: 'masuk',
                                  label: Text('Pemasukan'),
                                  icon: Icon(Icons.arrow_downward_rounded),
                                ),
                              ],
                              selected: {type},
                              onSelectionChanged: (set) {
                                setModalState(() => type = set.first);
                              },
                            ),
                            const SizedBox(height: 14),

                            // Pilih Akun / Dompet
                            const Text('Pilih Dompet / Akun',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            accountsAsync.when(
                              data: (accs) => DropdownButtonFormField<PersonalAccountModel>(
                                initialValue: selectedAcc,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 20),
                                ),
                                items: accs.map((a) {
                                  return DropdownMenuItem(
                                    value: a,
                                    child: Text('${a.name} (${formatCurrency(a.balance)})'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setModalState(() => selectedAcc = val);
                                },
                              ),
                              loading: () => const LinearProgressIndicator(),
                              error: (e, _) => Text('Gagal: $e'),
                            ),
                            const SizedBox(height: 14),

                            // Kategori
                            const Text('Kategori',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: category,
                              decoration: const InputDecoration(),
                              items: kPersonalCategorySuggestions.map((c) {
                                return DropdownMenuItem(value: c, child: Text(c));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => category = val);
                              },
                            ),
                            const SizedBox(height: 14),

                            // Nominal
                            const Text('Nominal (Rp)',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: amountCtrl,
                              keyboardType: TextInputType.number,
                              autofocus: true,
                              style: AppTheme.monoStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: const InputDecoration(
                                prefixText: 'Rp ',
                                hintText: '50.000',
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Catatan
                            const Text('Catatan (Opsional)',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: noteCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Kopi, makan siang, gaji bulanan...',
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Tanggal
                            const Text('Tanggal',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: trxDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setModalState(() => trxDate = picked);
                                }
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded,
                                        size: 18, color: AppColors.textMuted),
                                    const SizedBox(width: 10),
                                    Text(
                                      DateFormat('d MMM yyyy').format(trxDate),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMain,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            ElevatedButton(
                              onPressed: () async {
                                final amount = num.tryParse(amountCtrl.text) ?? 0;
                                if (amount <= 0 || selectedAcc == null) return;
                                Navigator.pop(ctx);

                                final dateStr =
                                    DateFormat('yyyy-MM-dd').format(trxDate);

                                try {
                                  await ref
                                      .read(personalFinanceRepositoryProvider)
                                      .addTransaction(
                                        accountId: selectedAcc!.id,
                                        type: type,
                                        category: category,
                                        amount: amount,
                                        trxDate: dateStr,
                                        note: noteCtrl.text,
                                      );
                                  _refreshAll();
                                } catch (e) {
                                  if (context.mounted) {
                                    ErrorHandler.showError(context, e, prefix: 'Gagal mencatat transaksi');
                                  }
                                }
                              },
                              child: const Text('Simpan Transaksi'),
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

  void _showTransferModal() {
    PersonalAccountModel? fromAcc;
    PersonalAccountModel? toAcc;
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime trxDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final accountsAsync = ref.watch(personalAccountsProvider);

            return StatefulBuilder(
              builder: (context, setModalState) {
                accountsAsync.whenData((accs) {
                  if (accs.length >= 2) {
                    fromAcc ??= accs[0];
                    toAcc ??= accs[1];
                  }
                });

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
                            const Text(
                              'Pindah Uang Antar Dompet',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMain,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Dari Akun
                            const Text('Dari Dompet',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            accountsAsync.when(
                              data: (accs) => DropdownButtonFormField<PersonalAccountModel>(
                                initialValue: fromAcc,
                                items: accs.map((a) {
                                  return DropdownMenuItem(
                                    value: a,
                                    child: Text('${a.name} (${formatCurrency(a.balance)})'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setModalState(() => fromAcc = val);
                                },
                              ),
                              loading: () => const LinearProgressIndicator(),
                              error: (e, _) => Text('Gagal: $e'),
                            ),
                            const SizedBox(height: 14),

                            // Ke Akun
                            const Text('Ke Dompet Tujuan',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            accountsAsync.when(
                              data: (accs) => DropdownButtonFormField<PersonalAccountModel>(
                                initialValue: toAcc,
                                items: accs.map((a) {
                                  return DropdownMenuItem(
                                    value: a,
                                    child: Text('${a.name} (${formatCurrency(a.balance)})'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setModalState(() => toAcc = val);
                                },
                              ),
                              loading: () => const LinearProgressIndicator(),
                              error: (e, _) => Text('Gagal: $e'),
                            ),
                            const SizedBox(height: 14),

                            // Jumlah
                            const Text('Jumlah Pindah (Rp)',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: amountCtrl,
                              keyboardType: TextInputType.number,
                              autofocus: true,
                              style: AppTheme.monoStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: const InputDecoration(
                                prefixText: 'Rp ',
                                hintText: '100.000',
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Catatan
                            const Text('Catatan (Opsional)',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: noteCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Tarik tunai, top up e-wallet, dll.',
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Tanggal
                            const Text('Tanggal',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: trxDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setModalState(() => trxDate = picked);
                                }
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded,
                                        size: 18, color: AppColors.textMuted),
                                    const SizedBox(width: 10),
                                    Text(
                                      DateFormat('d MMM yyyy').format(trxDate),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMain,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            ElevatedButton(
                              onPressed: () async {
                                final amount = num.tryParse(amountCtrl.text) ?? 0;
                                if (amount <= 0 || fromAcc == null || toAcc == null) return;
                                if (fromAcc!.id == toAcc!.id) {
                                  ErrorHandler.showWarning(context, 'Dompet asal dan tujuan tidak boleh sama!');
                                  return;
                                }

                                Navigator.pop(ctx);
                                final dateStr =
                                    DateFormat('yyyy-MM-dd').format(trxDate);

                                try {
                                  await ref
                                      .read(personalFinanceRepositoryProvider)
                                      .transferBetweenAccounts(
                                        fromAccountId: fromAcc!.id,
                                        toAccountId: toAcc!.id,
                                        amount: amount,
                                        trxDate: dateStr,
                                        note: noteCtrl.text,
                                      );
                                  _refreshAll();
                                } catch (e) {
                                  if (context.mounted) {
                                    ErrorHandler.showError(context, e, prefix: 'Gagal melakukan transfer');
                                  }
                                }
                              },
                              child: const Text('Kirim / Pindahkan'),
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

  void _showAccountDialog([PersonalAccountModel? account]) {
    final isEdit = account != null;
    final nameCtrl = TextEditingController(text: account?.name ?? '');
    final balanceCtrl = TextEditingController(
      text: account != null ? account.balance.toStringAsFixed(0) : '0',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Koreksi Saldo Dompet' : 'Tambah Dompet Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Dompet (BCA, DANA, Cash, dll)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: balanceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Saldo Saat Ini (Rp)',
                prefixText: 'Rp ',
              ),
            ),
          ],
        ),
        actions: [
          if (isEdit)
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: ctx,
                  builder: (dCtx) => AlertDialog(
                    title: const Text('Hapus Dompet?'),
                    content: Text(
                      'Dompet "${account.name}" dan semua transaksi terkait akan dihapus permanen.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dCtx, false),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.destructive,
                        ),
                        onPressed: () => Navigator.pop(dCtx, true),
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  try {
                    await ref.read(personalFinanceRepositoryProvider).deleteAccount(account.id);
                    _refreshAll();
                  } catch (e) {
                    if (mounted) {
                      ErrorHandler.showError(context, e, prefix: 'Gagal menghapus dompet');
                    }
                  }
                }
              },
              child: const Text('Hapus', style: TextStyle(color: AppColors.destructive)),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final balance = num.tryParse(balanceCtrl.text) ?? 0;
              if (name.isEmpty) return;
              Navigator.pop(ctx);

              try {
                final repo = ref.read(personalFinanceRepositoryProvider);
                if (isEdit) {
                  await repo.updateAccount(account.id, name, balance);
                } else {
                  await repo.createAccount(name, balance);
                }
                _refreshAll();
              } catch (e) {
                if (mounted) {
                  ErrorHandler.showError(context, e, prefix: 'Gagal menyimpan dompet');
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUnlocked = ref.watch(personalFinanceUnlockedProvider);

    // GATE 1: Lock Screen
    if (!isUnlocked) {
      return _buildLockScreen();
    }

    // GATE 2: Unlocked Content
    final hideBalance = ref.watch(personalFinanceHideBalanceProvider);
    final accountsAsync = ref.watch(personalAccountsProvider);
    final transactionsAsync = ref.watch(personalTransactionsProvider);
    final summaryAsync = ref.watch(personalMonthlySummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Keuangan Pribadi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline_rounded),
            tooltip: 'Kunci Halaman',
            onPressed: () {
              ref.read(personalFinanceUnlockedProvider.notifier).lock();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionModal(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Transaksi', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => _refreshAll(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Total Saldo Hero Card with Eye Toggle (PRD §6.12)
                accountsAsync.when(
                  data: (accounts) {
                    final totalSaldo =
                        accounts.fold<num>(0, (sum, a) => sum + a.balance);

                    return Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(109, 40, 217, 0.28),
                            blurRadius: 18,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TOTAL SALDO SEMUA DOMPET',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  hideBalance
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () {
                                  ref
                                      .read(personalFinanceHideBalanceProvider
                                          .notifier)
                                      .toggle();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hideBalance
                                ? 'Rp••••••••'
                                : formatCurrency(totalSaldo),
                            style: AppTheme.monoStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                ),
                                onPressed: _showTransferModal,
                                icon: const Icon(Icons.swap_horiz_rounded,
                                    size: 18),
                                label: const Text('Pindah Uang'),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white70),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                ),
                                onPressed: () => _showAccountDialog(),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Tambah Dompet'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Gagal: $e'),
                ),
                const SizedBox(height: 18),

                // 2. Wallets Grid (PRD §6.12)
                accountsAsync.when(
                  data: (accounts) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.1,
                      ),
                      itemCount: accounts.length,
                      itemBuilder: (context, idx) {
                        final a = accounts[idx];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.border, width: 0.8),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          padding: const EdgeInsets.all(12),
                          child: InkWell(
                            onTap: () => _showAccountDialog(a),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      a.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textMain,
                                      ),
                                    ),
                                    const Icon(Icons.edit_outlined,
                                        size: 14, color: AppColors.textMuted),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hideBalance
                                      ? 'Rp••••••••'
                                      : formatCurrency(a.balance),
                                  style: AppTheme.monoStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 18),

                // 3. Ringkasan Masuk / Keluar Bulan Ini (Transfer dikecualikan!)
                summaryAsync.when(
                  data: (s) {
                    return Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.border, width: 0.8),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'MASUK BULAN INI',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hideBalance
                                      ? 'Rp••••••••'
                                      : formatCurrency(s.totalMasuk),
                                  style: AppTheme.monoStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.statusSelesai,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.border, width: 0.8),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'KELUAR BULAN INI',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hideBalance
                                      ? 'Rp••••••••'
                                      : formatCurrency(s.totalKeluar),
                                  style: AppTheme.monoStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.destructive,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 18),

                // 3b. Breakdown Pengeluaran per Kategori (PRD §6.12)
                summaryAsync.when(
                  data: (s) {
                    if (s.categories.isEmpty) return const SizedBox.shrink();
                    final maxVal = s.categories.first.total;
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border, width: 0.8),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                            child: Text(
                              'Pengeluaran per Kategori',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMain,
                              ),
                            ),
                          ),
                          const Divider(height: 1, color: AppColors.divider),
                          ...s.categories.map((cat) {
                            final fraction = maxVal > 0 ? (cat.total / maxVal).toDouble() : 0.0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        cat.category,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textMain,
                                        ),
                                      ),
                                      Text(
                                        hideBalance
                                            ? 'Rp••••••••'
                                            : formatCurrency(cat.total),
                                        style: AppTheme.monoStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.destructive,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: fraction,
                                      minHeight: 6,
                                      backgroundColor: AppColors.border,
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        AppColors.destructive,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 20),

                // 4. Riwayat Transaksi Pribadi (PRD §6.12)
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
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        child: Text(
                          'Riwayat Transaksi Pribadi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      transactionsAsync.when(
                        data: (transactions) {
                          if (transactions.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                'Belum ada transaksi pribadi.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13, color: AppColors.textMuted),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: transactions.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1, color: AppColors.divider),
                            itemBuilder: (context, idx) {
                              final t = transactions[idx];
                              final isTransfer = t.isTransfer;
                              final isMasuk = t.type == 'masuk';

                              final Color amountColor = isTransfer
                                  ? AppColors.textMuted
                                  : isMasuk
                                      ? AppColors.statusSelesai
                                      : AppColors.destructive;

                              final IconData icon = isTransfer
                                  ? Icons.swap_horiz_rounded
                                  : isMasuk
                                      ? Icons.arrow_downward_rounded
                                      : Icons.arrow_upward_rounded;

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: amountColor.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(icon,
                                          size: 18, color: amountColor),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isTransfer
                                                ? 'Pindah Uang'
                                                : t.category,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textMain,
                                            ),
                                          ),
                                          Text(
                                            '${t.accountName ?? "Dompet"} · ${formatDate(t.trxDate)}${t.note != null && t.note!.isNotEmpty ? " · ${t.note}" : ""}',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${isTransfer ? "" : isMasuk ? "+" : "-"}${formatCurrency(t.amount)}',
                                          style: AppTheme.monoStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: amountColor,
                                          ),
                                        ),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 16,
                                              color: AppColors.textMuted),
                                          onPressed: () async {
                                            final confirmed =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text(
                                                    'Hapus Transaksi?'),
                                                content: const Text(
                                                    'Saldo akun terkait akan otomatis disesuaikan.'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            ctx, false),
                                                    child: const Text('Batal'),
                                                  ),
                                                  ElevatedButton(
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          AppColors.destructive,
                                                    ),
                                                    onPressed: () =>
                                                        Navigator.pop(ctx, true),
                                                    child: const Text('Hapus'),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirmed == true) {
                                              await ref
                                                  .read(
                                                      personalFinanceRepositoryProvider)
                                                  .deleteTransaction(t.id);
                                              _refreshAll();
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => Text('Gagal: $e'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Keamanan')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppColors.border, width: 0.8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.shield_outlined,
                          size: 30, color: AppColors.primary),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Keuangan Pribadi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Masukkan PIN atau gunakan biometric untuk membuka modul ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 22),

                    // PIN Input Field
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: AppTheme.monoStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        hintText: '••••••',
                      ),
                      onSubmitted: (_) => _handlePinSubmit(),
                    ),

                    if (_authError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _authError!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.destructive),
                      ),
                    ],
                    const SizedBox(height: 18),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: _isCheckingAuth ? null : _handlePinSubmit,
                      child: _isCheckingAuth
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Buka Kunci'),
                    ),
                    const SizedBox(height: 12),

                    TextButton.icon(
                      onPressed: _tryBiometricAuth,
                      icon: const Icon(Icons.fingerprint_rounded, size: 20),
                      label: const Text('Gunakan Biometric'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
