import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/customer_providers.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  void _showEditCustomerDialog(BuildContext context, WidgetRef ref, Customer customer) {
    final nameCtrl = TextEditingController(text: customer.name);
    final waCtrl = TextEditingController(text: customer.whatsapp);
    final igCtrl = TextEditingController(text: customer.instagram ?? '');
    final notesCtrl = TextEditingController(text: customer.notes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: waCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Nomor WhatsApp'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: igCtrl,
                decoration: const InputDecoration(labelText: 'Instagram (Opsional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Catatan (Opsional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);

              try {
                await ref.read(customerRepositoryProvider).updateCustomer(
                      id: customer.id,
                      name: name,
                      whatsapp: waCtrl.text.trim(),
                      instagram: igCtrl.text.trim(),
                      notes: notesCtrl.text.trim(),
                    );
                ref.invalidate(customerDetailProvider(customer.id));
                ref.invalidate(customersListProvider);
              } catch (e) {
                if (context.mounted) {
                  ErrorHandler.showError(context, e, prefix: 'Gagal memperbarui customer');
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
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(customerId));
    final ordersAsync = ref.watch(customerOrdersProvider(customerId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Customer'),
        actions: [
          customerAsync.maybeWhen(
            data: (c) => Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Customer',
                  onPressed: () => _showEditCustomerDialog(context, ref, c),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.destructive),
                  tooltip: 'Hapus Customer',
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Hapus Customer?'),
                        content: Text(
                            'Customer "${c.name}" akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.destructive),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      try {
                        await ref
                            .read(customerRepositoryProvider)
                            .deleteCustomer(c.id);
                        ref.invalidate(customersListProvider);
                        if (context.mounted) {
                          context.pop();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ErrorHandler.showError(context, e, prefix: 'Gagal menghapus customer');
                        }
                      }
                    }
                  },
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: customerAsync.when(
        data: (customer) {
          final totalOrders = ordersAsync.maybeWhen(
            data: (orders) => orders.length,
            orElse: () => 0,
          );

          // Real total spent from payments (PRD §6.8)
          final totalSpent = ordersAsync.maybeWhen(
            data: (orders) => orders.fold<num>(
                0, (sum, o) => sum + o.totalPaid),
            orElse: () => 0,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 0.8),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // WhatsApp clickable link
                      if (customer.whatsapp.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            final digits = customer.whatsapp
                                .replaceAll(RegExp(r'\D'), '');
                            final normalized = digits.startsWith('0')
                                ? '62${digits.substring(1)}'
                                : digits;
                            launchUrl(Uri.parse('https://wa.me/$normalized'),
                                mode: LaunchMode.externalApplication);
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.chat_outlined,
                                  size: 16, color: Color(0xFF25D366)),
                              const SizedBox(width: 6),
                              Text(
                                customer.whatsapp,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF25D366),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Instagram link
                      if (customer.instagram != null &&
                          customer.instagram!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {
                            final clean = customer.instagram!
                                .replaceAll('@', '')
                                .trim();
                            launchUrl(
                                Uri.parse('https://instagram.com/$clean'),
                                mode: LaunchMode.externalApplication);
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.camera_alt_outlined,
                                  size: 16, color: Color(0xFFE1306C)),
                              const SizedBox(width: 6),
                              Text(
                                customer.instagram!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFE1306C),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Notes
                      if (customer.notes != null &&
                          customer.notes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppColors.divider),
                        const SizedBox(height: 10),
                        Text(
                          customer.notes!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2 Stat Cards: Total Order & Total Pengeluaran
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border:
                              Border.all(color: AppColors.border, width: 0.8),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL ORDER',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalOrders',
                              style: AppTheme.monoStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border:
                              Border.all(color: AppColors.border, width: 0.8),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL PENGELUARAN',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatCurrency(totalSpent),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.monoStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Riwayat Order
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
                          'Riwayat Order',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      ordersAsync.when(
                        data: (orders) {
                          if (orders.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'Belum ada riwayat order.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13, color: AppColors.textMuted),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: orders.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1, color: AppColors.divider),
                            itemBuilder: (context, idx) {
                              final o = orders[idx];
                              return InkWell(
                                onTap: () => context.push('/orders/${o.id}'),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 13),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              o.invoiceNumber,
                                              style: AppTheme.monoStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textMain,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${o.serviceName ?? "Layanan"} — ${formatDate(o.orderDate)}',
                                              style: const TextStyle(
                                                fontSize: 12,
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
                                            formatCurrency(o.price),
                                            style: AppTheme.monoStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          StatusBadge(status: o.status),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        error: (err, _) => Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Gagal memuat riwayat order: $err'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Text('Gagal memuat data customer: $err'),
        ),
      ),
    );
  }
}
