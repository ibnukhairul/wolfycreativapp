import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/models.dart';
import '../../../core/models/order_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/payment_badge.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/order_providers.dart';

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortModal(BuildContext context) {
    final currentSort = ref.read(orderSortByProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Urutkan Order Berdasarkan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _sortOption(ctx, 'Terbaru (Tanggal Order)', 'latest', currentSort),
                _sortOption(ctx, 'Terlama (Tanggal Order)', 'oldest', currentSort),
                _sortOption(ctx, 'Deadline Terdekat', 'deadline_nearest', currentSort),
                _sortOption(ctx, 'Harga Tertinggi', 'price_highest', currentSort),
                _sortOption(ctx, 'Harga Terendah', 'price_lowest', currentSort),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sortOption(
      BuildContext ctx, String label, String value, String current) {
    final isSelected = value == current;
    return InkWell(
      onTap: () {
        ref.read(orderSortByProvider.notifier).setSortBy(value);
        Navigator.pop(ctx);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textMain,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersListProvider);
    final selectedPeriod = ref.watch(orderPeriodFilterProvider);
    final selectedStatus = ref.watch(orderStatusFilterProvider);
    final selectedPayment = ref.watch(orderPaymentFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daftar Order'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded, color: AppColors.textMain),
            tooltip: 'Urutkan',
            onPressed: () => _showSortModal(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/orders/new'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Order Baru', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari invoice, customer, layanan...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 20, color: AppColors.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(orderSearchQueryProvider.notifier).setQuery('');
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  ref.read(orderSearchQueryProvider.notifier).setQuery(val);
                  setState(() {});
                },
              ),
            ),

            // Period Filter Chips (Horizontal Scroll)
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _PeriodFilterChip(
                    label: 'Bulan Ini',
                    isSelected: selectedPeriod == 'this_month',
                    onTap: () => ref.read(orderPeriodFilterProvider.notifier).setPeriod('this_month'),
                  ),
                  const SizedBox(width: 8),
                  _PeriodFilterChip(
                    label: 'Bulan Lalu',
                    isSelected: selectedPeriod == 'last_month',
                    onTap: () => ref.read(orderPeriodFilterProvider.notifier).setPeriod('last_month'),
                  ),
                  const SizedBox(width: 8),
                  _PeriodFilterChip(
                    label: '3 Bulan',
                    isSelected: selectedPeriod == 'last_3_months',
                    onTap: () => ref.read(orderPeriodFilterProvider.notifier).setPeriod('last_3_months'),
                  ),
                  const SizedBox(width: 8),
                  _PeriodFilterChip(
                    label: 'Semua Periode',
                    isSelected: selectedPeriod == 'all',
                    onTap: () => ref.read(orderPeriodFilterProvider.notifier).setPeriod('all'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Status Filter Chips
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _StatusFilterChip(
                    label: 'Semua Status',
                    isSelected: selectedStatus == null,
                    onTap: () => ref.read(orderStatusFilterProvider.notifier).setStatus(null),
                  ),
                  ...OrderStatus.values.map(
                    (st) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _StatusFilterChip(
                        label: st.label,
                        color: st.color,
                        isSelected: selectedStatus == st,
                        onTap: () => ref.read(orderStatusFilterProvider.notifier).setStatus(st),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Payment Filter Chips
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _PaymentFilterChip(
                    label: 'Semua Pembayaran',
                    isSelected: selectedPayment == null,
                    onTap: () => ref.read(orderPaymentFilterProvider.notifier).setFilter(null),
                  ),
                  const SizedBox(width: 8),
                  _PaymentFilterChip(
                    label: 'Belum Lunas',
                    isSelected: selectedPayment == 'belum_lunas',
                    activeColor: const Color(0xFFF59E0B),
                    onTap: () => ref.read(orderPaymentFilterProvider.notifier).setFilter('belum_lunas'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Orders List
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(ordersListProvider);
                },
                child: ordersAsync.when(
                  data: (orders) {
                    if (orders.isEmpty) {
                      return ListView(
                        children: const [
                          SizedBox(height: 80),
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.inbox_outlined,
                                    size: 48, color: AppColors.textMuted),
                                SizedBox(height: 12),
                                Text(
                                  'Tidak ada order ditemukan',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMain,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Coba ubah filter atau kata kunci pencarian',
                                  style: TextStyle(
                                      fontSize: 13, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                      itemCount: orders.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return _OrderListItemCard(
                          order: order,
                          index: index + 1,
                          onTap: () => context.push('/orders/${order.id}'),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Terjadi kesalahan: $err',
                          style: const TextStyle(color: AppColors.destructive)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 0.9,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMain,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusFilterChip({
    required this.label,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveColor.withValues(alpha: 0.18)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? effectiveColor : AppColors.border,
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? effectiveColor : AppColors.textMuted,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _PaymentFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;

  const _PaymentFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : AppColors.textMuted,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _OrderListItemCard extends StatelessWidget {
  final OrderModel order;
  final int index;
  final VoidCallback onTap;

  const _OrderListItemCard({
    required this.order,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Index, Invoice & Badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '#$index',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order.invoiceNumber,
                      style: AppTheme.monoStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const Spacer(),
                    StatusBadge(status: order.status),
                    const SizedBox(width: 6),
                    PaymentBadge(
                      price: order.price,
                      totalPaid: order.totalPaid,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Row 2: Customer · Service
                Text(
                  '${order.customerName ?? 'Customer'} · ${order.serviceName ?? 'Layanan'}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 8),

                // Row 3: Price and Deadline
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatCurrency(order.price),
                      style: AppTheme.monoStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.event_outlined,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          'Deadline: ${formatDate(order.deadline)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
