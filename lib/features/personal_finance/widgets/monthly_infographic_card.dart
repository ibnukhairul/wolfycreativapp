import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../providers/personal_finance_providers.dart';
import '../repositories/personal_finance_repository.dart';

const List<Color> kChartColors = [
  Color(0xFF6366F1),
  Color(0xFF22C55E),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFF8B5CF6),
  Color(0xFF06B6D4),
  Color(0xFFEC4899),
  Color(0xFF84CC16),
  Color(0xFFF97316),
  Color(0xFF14B8A6),
];

class MonthlyInfographicCard extends ConsumerWidget {
  final bool hideBalance;

  const MonthlyInfographicCard({super.key, required this.hideBalance});

  void _shareReport(BuildContext context, PersonalMonthlyReportData report) {
    final monthStr = DateFormat('MMMM yyyy', 'id_ID').format(
      DateTime.parse('${report.monthKey}-01'),
    );

    final buffer = StringBuffer();
    buffer.writeln('📊 *LAPORAN KEUANGAN PRIBADI — $monthStr*');
    buffer.writeln('------------------------------------');
    buffer.writeln('• Pemasukan: ${formatCurrency(report.totalMasuk)}');
    buffer.writeln('• Pengeluaran: ${formatCurrency(report.totalKeluar)}');
    buffer.writeln('• Net: ${report.net >= 0 ? "+" : ""}${formatCurrency(report.net)}');
    buffer.writeln('• Total Transaksi: ${report.count}');
    buffer.writeln('');

    if (report.byCategory.any((c) => c.type == 'keluar')) {
      buffer.writeln('📉 *Rincian Pengeluaran:*');
      for (final c in report.byCategory.where((c) => c.type == 'keluar')) {
        final pct = report.totalKeluar > 0 ? (c.total / report.totalKeluar * 100).toStringAsFixed(1) : '0';
        buffer.writeln('  - ${c.category}: ${formatCurrency(c.total)} ($pct%)');
      }
      buffer.writeln('');
    }

    if (report.byCategory.any((c) => c.type == 'masuk')) {
      buffer.writeln('📈 *Rincian Pemasukan:*');
      for (final c in report.byCategory.where((c) => c.type == 'masuk')) {
        final pct = report.totalMasuk > 0 ? (c.total / report.totalMasuk * 100).toStringAsFixed(1) : '0';
        buffer.writeln('  - ${c.category}: ${formatCurrency(c.total)} ($pct%)');
      }
      buffer.writeln('');
    }

    if (report.byAccount.isNotEmpty) {
      buffer.writeln('💳 *Ringkasan Akun / Dompet:*');
      for (final a in report.byAccount) {
        buffer.writeln('  - ${a.accountName}: Net ${a.net >= 0 ? "+" : ""}${formatCurrency(a.net)}');
      }
    }

    buffer.writeln('------------------------------------');
    buffer.writeln('_Dicatat via WolfyCreativ Mobile_');

    SharePlus.instance.share(
      ShareParams(
        text: buffer.toString(),
        subject: 'Laporan Keuangan Pribadi $monthStr',
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(personalMonthlyReportProvider);
    final selectedMonth = ref.watch(selectedReportMonthProvider);
    final monthStr = DateFormat('MMMM yyyy', 'id_ID').format(selectedMonth);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Month Navigator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Laporan & Infografis',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Rekap detail evaluasi bulanan',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              // Export / Share Button
              reportAsync.maybeWhen(
                data: (report) => IconButton(
                  icon: const Icon(Icons.share_outlined, size: 20),
                  tooltip: 'Bagikan Laporan',
                  color: AppColors.primary,
                  onPressed: () => _shareReport(context, report),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Month selector bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Bulan sebelumnya',
                  onPressed: () {
                    ref.read(selectedReportMonthProvider.notifier).prevMonth();
                  },
                ),
                InkWell(
                  onTap: () {
                    ref.read(selectedReportMonthProvider.notifier).setMonth(DateTime.now());
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          monthStr,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Bulan berikutnya',
                  onPressed: () {
                    ref.read(selectedReportMonthProvider.notifier).nextMonth();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Report Content
          reportAsync.when(
            data: (report) => _buildReportContent(context, report),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Gagal memuat infografis: $e', style: const TextStyle(fontSize: 12, color: AppColors.destructive)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(BuildContext context, PersonalMonthlyReportData report) {
    final pengeluaran = report.byCategory.where((c) => c.type == 'keluar').toList();
    final pemasukan = report.byCategory.where((c) => c.type == 'masuk').toList();
    final grandTotalKeluar = report.totalKeluar > 0 ? report.totalKeluar : 1;
    final grandTotalMasuk = report.totalMasuk > 0 ? report.totalMasuk : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Empat Stat Box Ringkasan
        Row(
          children: [
            Expanded(
              child: _buildStatMiniCard(
                'Pemasukan',
                hideBalance ? '••••••' : formatCurrency(report.totalMasuk),
                Icons.trending_up_rounded,
                AppColors.statusSelesai,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatMiniCard(
                'Pengeluaran',
                hideBalance ? '••••••' : formatCurrency(report.totalKeluar),
                Icons.trending_down_rounded,
                AppColors.destructive,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatMiniCard(
                'Net Kas',
                hideBalance ? '••••••' : '${report.net >= 0 ? "+" : ""}${formatCurrency(report.net)}',
                Icons.account_balance_wallet_outlined,
                report.net >= 0 ? AppColors.statusSelesai : AppColors.destructive,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatMiniCard(
                'Transaksi',
                '${report.count}',
                Icons.receipt_long_outlined,
                AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 2. Komposisi Pengeluaran per Kategori (Donut Chart)
        const Text(
          'Komposisi Pengeluaran',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 10),
        if (pengeluaran.isEmpty)
          _buildEmptyText('Belum ada pengeluaran pada bulan ini')
        else ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 140,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      sections: pengeluaran.take(6).map((c) {
                        final idx = pengeluaran.indexOf(c);
                        final color = kChartColors[idx % kChartColors.length];
                        final pct = (c.total / grandTotalKeluar) * 100;
                        return PieChartSectionData(
                          color: color,
                          value: c.total.toDouble(),
                          title: '${pct.toStringAsFixed(0)}%',
                          radius: 22,
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Legend list
                ...pengeluaran.take(6).map((c) {
                  final idx = pengeluaran.indexOf(c);
                  final color = kChartColors[idx % kChartColors.length];
                  final pct = (c.total / grandTotalKeluar) * 100;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            c.category,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          hideBalance ? '•••' : '${pct.toStringAsFixed(1)}% · ${formatCurrency(c.total)}',
                          style: AppTheme.monoStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),

        // 3. Sumber Pemasukan per Kategori
        const Text(
          'Sumber Pemasukan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 10),
        if (pemasukan.isEmpty)
          _buildEmptyText('Belum ada pemasukan pada bulan ini')
        else ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: pemasukan.take(6).map((c) {
                final pct = (c.total / grandTotalMasuk).clamp(0.0, 1.0).toDouble();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            c.category,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            hideBalance ? '••••••' : formatCurrency(c.total),
                            style: AppTheme.monoStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.statusSelesai,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.statusSelesai),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 20),

        // 4. Aktivitas per Akun/Dompet
        const Text(
          'Aktivitas per Akun / Dompet',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 10),
        if (report.byAccount.isEmpty)
          _buildEmptyText('Belum ada aktivitas akun')
        else ...[
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: const [
                      Expanded(
                        flex: 3,
                        child: Text('AKUN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.5)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('MASUK', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.statusSelesai, letterSpacing: 0.5)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('KELUAR', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.destructive, letterSpacing: 0.5)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('NET', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                ...report.byAccount.asMap().entries.map((entry) {
                  final i = entry.key;
                  final a = entry.value;
                  final isLast = i == report.byAccount.length - 1;
                  final netPositive = a.net >= 0;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      a.accountName,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMain,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                hideBalance ? '•••' : formatCurrency(a.masuk),
                                textAlign: TextAlign.right,
                                style: AppTheme.monoStyle(
                                  fontSize: 11.5,
                                  color: AppColors.statusSelesai,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                hideBalance ? '•••' : formatCurrency(a.keluar),
                                textAlign: TextAlign.right,
                                style: AppTheme.monoStyle(
                                  fontSize: 11.5,
                                  color: AppColors.destructive,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (netPositive ? AppColors.statusSelesai : AppColors.destructive).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    hideBalance
                                        ? '•••'
                                        : '${netPositive ? "+" : ""}${formatCurrency(a.net)}',
                                    style: AppTheme.monoStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: netPositive ? AppColors.statusSelesai : AppColors.destructive,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast) const Divider(height: 1, color: AppColors.border),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatMiniCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTheme.monoStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyText(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

