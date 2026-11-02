import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../providers/analytics_providers.dart';

const Map<String, String> kRangeLabels = {
  '3m': '3 Bulan Terakhir',
  '6m': '6 Bulan Terakhir',
  '12m': '12 Bulan Terakhir',
  'ytd': 'Tahun Ini',
  'all': 'Semua Waktu',
};

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRange = ref.watch(analyticsRangeProvider);
    final revenueAsync = ref.watch(monthlyRevenueProvider);
    final topServicesAsync = ref.watch(topServicesProvider);
    final topCustomersAsync = ref.watch(topCustomersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analitik'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(monthlyRevenueProvider);
            ref.invalidate(topServicesProvider);
            ref.invalidate(topCustomersProvider);
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Range Filter Dropdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Rentang Waktu',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    DropdownButton<String>(
                      value: currentRange,
                      borderRadius: BorderRadius.circular(16),
                      underline: const SizedBox.shrink(),
                      icon: const Icon(Icons.arrow_drop_down_rounded,
                          color: AppColors.primary),
                      items: kRangeLabels.entries.map((e) {
                        return DropdownMenuItem(
                          value: e.key,
                          child: Text(
                            e.value,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          ref
                              .read(analyticsRangeProvider.notifier)
                              .setRange(val);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2 Summary Cards (Total Revenue & Total Orders)
                revenueAsync.when(
                  data: (items) {
                    final totalRevenue =
                        items.fold<num>(0, (sum, i) => sum + i.revenue);
                    final totalOrders =
                        items.fold<int>(0, (sum, i) => sum + i.totalOrders);

                    return Row(
                      children: [
                        Expanded(
                          child: _metricCard(
                            'TOTAL PENDAPATAN',
                            formatCurrency(totalRevenue),
                            AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _metricCard(
                            'TOTAL ORDER',
                            '$totalOrders',
                            AppColors.statusProses,
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (e, _) => Text('Gagal memuat metrik: $e'),
                ),
                const SizedBox(height: 20),

                // Chart Card
                revenueAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final maxRevenue = items
                        .map((e) => e.revenue.toDouble())
                        .reduce((a, b) => a > b ? a : b);

                    final barGroups = items.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return BarChartGroupData(
                        x: idx,
                        barRods: [
                          BarChartRodData(
                            toY: item.revenue.toDouble(),
                            color: AppColors.primary,
                            width: 14,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                          ),
                        ],
                      );
                    }).toList();

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border, width: 0.8),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Grafik Pendapatan per Bulan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Berdasarkan tanggal pembayaran masuk riil',
                            style: TextStyle(
                                fontSize: 11.5, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                maxY: maxRevenue * 1.15,
                                barGroups: barGroups,
                                gridData: const FlGridData(show: false),
                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                  leftTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (val, meta) {
                                        final idx = val.toInt();
                                        if (idx >= 0 && idx < items.length) {
                                          final dt = DateTime.tryParse(
                                                  items[idx].month) ??
                                              DateTime.now();
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 6),
                                            child: Text(
                                              DateFormat('MMM').format(dt),
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 20),

                // Top Services List (PRD §6.7)
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
                          'Layanan Terlaris',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      topServicesAsync.when(
                        data: (services) {
                          if (services.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(18),
                              child: Text('Belum ada data',
                                  textAlign: TextAlign.center),
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: services.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1, color: AppColors.divider),
                            itemBuilder: (context, idx) {
                              final s = services[idx];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: idx == 0
                                            ? AppColors.primary
                                            : AppColors.primarySoft,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${idx + 1}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: idx == 0
                                                ? Colors.white
                                                : AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s.serviceName,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textMain,
                                            ),
                                          ),
                                          Text(
                                            '${s.totalOrder} order',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      formatCurrency(s.totalRevenue),
                                      style: AppTheme.monoStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.statusSelesai,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(
                            child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator())),
                        error: (e, _) => Text('Gagal: $e'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Top Customers List (PRD §6.7)
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
                          'Customer Terbaik',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      topCustomersAsync.when(
                        data: (customers) {
                          if (customers.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(18),
                              child: Text('Belum ada data',
                                  textAlign: TextAlign.center),
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: customers.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1, color: AppColors.divider),
                            itemBuilder: (context, idx) {
                              final c = customers[idx];
                              return InkWell(
                                onTap: () =>
                                    context.push('/customers/${c.id}'),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: idx == 0
                                              ? AppColors.statusProses
                                              : AppColors.primarySoft,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${idx + 1}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: idx == 0
                                                  ? Colors.white
                                                  : AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              c.name,
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textMain,
                                              ),
                                            ),
                                            Text(
                                              '${c.totalOrder} order',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textMuted),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        formatCurrency(c.totalSpent),
                                        style: AppTheme.monoStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.chevron_right_rounded,
                                          size: 18,
                                          color: AppColors.textMuted),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(
                            child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator())),
                        error: (e, _) => Text('Gagal: $e'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.monoStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
