import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/models.dart';
import '../../../core/models/order_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/invoice_text_generator.dart';
import '../../../core/widgets/payment_badge.dart';
import '../../../core/widgets/status_badge.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../providers/order_providers.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  final _picker = ImagePicker();
  bool _isActionLoading = false;

  void _refreshAll() {
    ref.invalidate(orderDetailProvider(widget.orderId));
    ref.invalidate(orderPaymentsProvider(widget.orderId));
    ref.invalidate(orderFilesProvider(widget.orderId));
    ref.invalidate(ordersListProvider);
    ref.invalidate(calendarOrdersProvider);
  }

  Future<void> _handleStatusChange(OrderStatus newStatus) async {
    if (newStatus == OrderStatus.batal) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Batalkan Order?'),
          content: const Text(
              'Yakin ingin membatalkan order ini? Status akan ditandai sebagai Batal.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Tidak'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.destructive,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ya, Batalkan'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    try {
      await ref
          .read(orderRepositoryProvider)
          .updateOrderStatus(widget.orderId, newStatus);
      _refreshAll();
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, prefix: 'Gagal mengubah status');
      }
    }
  }

  void _showAddPaymentModal(OrderModel order) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DateTime paidAt = DateTime.now();
    String? selectedAccountId;

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
                // Default select "DANA" wallet if not selected yet (PRD §6.5)
                accountsAsync.whenData((accounts) {
                  if (selectedAccountId == null) {
                    final dana = accounts.where((a) =>
                        (a['name'] as String).toUpperCase().contains('DANA')).firstOrNull;
                    if (dana != null) {
                      selectedAccountId = dana['id'] as String;
                    }
                  }
                });

                return SafeArea(
                  child: Container(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
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
                            'Catat Pembayaran Order',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sisa belum dibayar: ${formatCurrency(order.remaining)}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Nominal Field
                          const Text(
                            'Nominal Pembayaran (Rp)',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            autofocus: true,
                            style: AppTheme.monoStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: const InputDecoration(
                              prefixText: 'Rp ',
                              hintText: '250.000',
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Wallet Selection Dropdown
                          const Text(
                            'Masuk ke Dompet Pribadi (Opsional)',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
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
                                      child: Text(
                                        '${a['name']} (${formatCurrency(a['balance'] as num)})',
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  setModalState(() => selectedAccountId = val);
                                },
                              );
                            },
                            loading: () => const LinearProgressIndicator(),
                            error: (e, _) => Text('Gagal memuat dompet: $e'),
                          ),
                          const SizedBox(height: 14),

                          // Catatan
                          const Text(
                            'Catatan Pembayaran (Opsional)',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: noteController,
                            decoration: const InputDecoration(
                              hintText: 'DP 50%, pelunasan, transfer BCA, dll.',
                            ),
                          ),
                          const SizedBox(height: 20),

                          ElevatedButton(
                            onPressed: () async {
                              final amount =
                                  num.tryParse(amountController.text) ?? 0;
                              if (amount <= 0) {
                                ErrorHandler.showWarning(context, 'Nominal harus lebih dari 0');
                                return;
                              }

                              Navigator.pop(ctx);
                              setState(() => _isActionLoading = true);

                              try {
                                final paidAtStr =
                                    "${paidAt.year}-${paidAt.month.toString().padLeft(2, '0')}-${paidAt.day.toString().padLeft(2, '0')}";
                                await ref
                                    .read(orderRepositoryProvider)
                                    .addPayment(
                                      orderId: widget.orderId,
                                      amount: amount,
                                      paidAt: paidAtStr,
                                      note: noteController.text,
                                      accountId: selectedAccountId,
                                    );
                                _refreshAll();
                              } catch (e) {
                                if (context.mounted) {
                                  ErrorHandler.showError(context, e, prefix: 'Gagal mencatat pembayaran');
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isActionLoading = false);
                                }
                              }
                            },
                            child: const Text('Simpan Pembayaran'),
                          ),
                        ],
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

  Future<void> _handleUploadPreview() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isActionLoading = true);
    try {
      final bytes = await image.readAsBytes();
      await ref.read(orderRepositoryProvider).uploadFile(
            orderId: widget.orderId,
            kind: 'preview',
            fileName: image.name,
            bytes: bytes,
          );
      _refreshAll();
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, prefix: 'Gagal mengunggah preview');
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleUploadFinal() async {
    final files = await FilePicker.pickFiles();
    if (files.isEmpty) return;

    final picked = files.first;
    final bytes = await picked.readAsBytes();

    setState(() => _isActionLoading = true);
    try {
      await ref.read(orderRepositoryProvider).uploadFile(
            orderId: widget.orderId,
            kind: 'final',
            fileName: picked.name,
            bytes: bytes,
          );
      _refreshAll();
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, prefix: 'Gagal mengunggah file final');
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));
    final paymentsAsync = ref.watch(orderPaymentsProvider(widget.orderId));
    final filesAsync = ref.watch(orderFilesProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Order'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Order',
            onPressed: () => context.push('/orders/${widget.orderId}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.destructive),
            tooltip: 'Hapus Order',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Hapus Order?'),
                  content: const Text(
                      'Tindakan ini permanen. Semua file dan riwayat pembayaran order ini akan ikut terhapus.'),
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
                await ref
                    .read(orderRepositoryProvider)
                    .deleteOrder(widget.orderId);
                ref.invalidate(ordersListProvider);
                ref.invalidate(calendarOrdersProvider);
                if (context.mounted) {
                  context.pop();
                }
              }
            },
          ),
        ],
      ),
      body: orderAsync.when(
        data: (order) {
          final totalPaid = paymentsAsync.maybeWhen(
            data: (pList) =>
                pList.fold<num>(0, (sum, item) => sum + item.amount),
            orElse: () => order.totalPaid,
          );
          final remaining = (order.price - totalPaid).clamp(0, double.infinity);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => _refreshAll(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Order Info Card
                  _buildHeaderCard(order, totalPaid),
                  const SizedBox(height: 16),

                  // 2. Status Changer Row (7 Status Buttons)
                  _buildStatusChangerSection(order.status),
                  const SizedBox(height: 16),

                  // 3. Payment Card
                  _buildPaymentCard(order, totalPaid, remaining, paymentsAsync),
                  const SizedBox(height: 16),

                  // 4. Invoice Card (Monospace generator + WA + Share)
                  _buildInvoiceCard(order, totalPaid),
                  const SizedBox(height: 16),

                  // 5. Files Card (Preview & Final)
                  _buildFilesCard(filesAsync),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text('Gagal memuat detail order: $e',
              style: const TextStyle(color: AppColors.destructive)),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(OrderModel order, num totalPaid) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.invoiceNumber,
                style: AppTheme.monoStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 14),

          // Customer and WhatsApp intent
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 18, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName ?? 'Customer',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    if (order.customerWhatsapp != null &&
                        order.customerWhatsapp!.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          final url =
                              'https://wa.me/${order.customerWhatsapp!.replaceAll(RegExp(r'\D'), '')}';
                          launchUrl(Uri.parse(url),
                              mode: LaunchMode.externalApplication);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            order.customerWhatsapp!,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Service
          Row(
            children: [
              const Icon(Icons.checkroom_outlined,
                  size: 18, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Text(
                order.serviceName ?? 'Layanan',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dates
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    'Order: ${formatDate(order.orderDate)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.event_available_outlined,
                      size: 16, color: AppColors.statusProses),
                  const SizedBox(width: 6),
                  Text(
                    'Deadline: ${formatDate(order.deadline)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.statusProses,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (order.notes != null && order.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 10),
            Text(
              'Catatan: ${order.notes}',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChangerSection(OrderStatus currentStatus) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ubah Status Pengerjaan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: OrderStatus.values.map((status) {
              final isSelected = status == currentStatus;
              return InkWell(
                onTap: () => _handleStatusChange(status),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? status.color
                        : status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: status.color.withValues(alpha: isSelected ? 1 : 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        const Padding(
                          padding: EdgeInsets.only(right: 5),
                          child: Icon(Icons.check_rounded,
                              size: 14, color: Colors.white),
                        ),
                      Text(
                        status.label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : status.color,
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(
    OrderModel order,
    num totalPaid,
    num remaining,
    AsyncValue<List<PaymentModel>> paymentsAsync,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pembayaran',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              PaymentBadge(price: order.price, totalPaid: totalPaid),
            ],
          ),
          const SizedBox(height: 14),

          // Total, Dibayar, Sisa Row
          Row(
            children: [
              Expanded(
                child: _paymentStatBox('Total', formatCurrency(order.price),
                    AppColors.textMain),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _paymentStatBox(
                    'Dibayar', formatCurrency(totalPaid), AppColors.statusSelesai),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _paymentStatBox(
                  'Sisa',
                  formatCurrency(remaining),
                  remaining > 0 ? AppColors.destructive : AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Button Add Payment
          OutlinedButton.icon(
            onPressed: () => _showAddPaymentModal(order),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('+ Catat Pembayaran'),
          ),

          // Payments history list
          paymentsAsync.when(
            data: (payments) {
              if (payments.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'Riwayat Pembayaran',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: payments.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (context, idx) {
                      final p = payments[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatCurrency(p.amount),
                                  style: AppTheme.monoStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.statusSelesai,
                                  ),
                                ),
                                Text(
                                  '${formatDate(p.paidAt)}${p.note != null && p.note!.isNotEmpty ? " · ${p.note}" : ""}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 18, color: AppColors.textMuted),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Hapus Pembayaran?'),
                                    content: const Text(
                                        'Yakin ingin menghapus pembayaran ini? Saldo dompet akan disesuaikan otomatis.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Batal'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.destructive,
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
                                      .read(orderRepositoryProvider)
                                      .deletePayment(p.id);
                                  _refreshAll();
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (err, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _paymentStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.monoStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(OrderModel order, num totalPaid) {
    final invoiceText = generateInvoiceText(order: order, totalPaid: totalPaid);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Invoice Pemesanan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 12),

          // Monospace Preview Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E28),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              invoiceText,
              style: AppTheme.monoStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFE2E4EE),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons: Copy Text & Kirim WhatsApp
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: invoiceText));
                    ErrorHandler.showSuccess(context, 'Teks invoice berhasil disalin!');
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Salin Teks'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                  ),
                  onPressed: () {
                    final phone = order.customerWhatsapp ?? '';
                    final waUrl = toWhatsAppUrl(phone, invoiceText);
                    launchUrl(Uri.parse(waUrl),
                        mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.chat_outlined, size: 16),
                  label: const Text('Kirim via WA'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilesCard(AsyncValue<List<OrderFileModel>> filesAsync) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'File Desain & Hasil',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate_outlined,
                        size: 20, color: AppColors.primary),
                    tooltip: 'Upload Preview (Gambar)',
                    onPressed: _isActionLoading ? null : _handleUploadPreview,
                  ),
                  IconButton(
                    icon: const Icon(Icons.upload_file_outlined,
                        size: 20, color: AppColors.primary),
                    tooltip: 'Upload File Final',
                    onPressed: _isActionLoading ? null : _handleUploadFinal,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          filesAsync.when(
            data: (files) {
              if (files.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Belum ada file preview atau final yang di-upload.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: files.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (context, idx) {
                  final file = files[idx];
                  final isPreview = file.kind == 'preview';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPreview
                                ? AppColors.statusPreview.withValues(alpha: 0.15)
                                : AppColors.statusSelesai.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isPreview ? 'PREVIEW' : 'FINAL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isPreview
                                  ? AppColors.statusPreview
                                  : AppColors.statusSelesai,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            file.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.download_rounded,
                              size: 18, color: AppColors.primary),
                          onPressed: () async {
                            final url = await ref
                                .read(orderRepositoryProvider)
                                .getFileUrl(file);
                            if (url != null) {
                              launchUrl(Uri.parse(url),
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppColors.textMuted),
                          onPressed: () async {
                            await ref
                                .read(orderRepositoryProvider)
                                .deleteFile(file);
                            _refreshAll();
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Text('Gagal memuat file: $e'),
          ),
        ],
      ),
    );
  }
}
