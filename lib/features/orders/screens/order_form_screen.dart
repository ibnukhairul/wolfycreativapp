import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../providers/order_providers.dart';

class OrderFormScreen extends ConsumerStatefulWidget {
  final String? orderId;

  const OrderFormScreen({super.key, this.orderId});

  @override
  ConsumerState<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends ConsumerState<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();

  Customer? _selectedCustomer;
  ServiceItem? _selectedService;
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _orderDate = DateTime.now();
  DateTime _deadline = DateTime.now().add(const Duration(days: 2));

  bool _isLoading = false;
  bool _isInitLoading = false;
  List<Customer> _allCustomers = [];
  List<ServiceItem> _allServices = [];

  bool get _isEdit => widget.orderId != null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isInitLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);

      final custRes = await client
          .from('customers')
          .select('id, name, whatsapp, instagram, notes')
          .order('name', ascending: true);
      final servRes = await client
          .from('services')
          .select('id, name, default_price')
          .order('name', ascending: true);

      _allCustomers = (custRes as List<dynamic>)
          .map((c) => Customer.fromJson(c as Map<String, dynamic>))
          .toList();
      _allServices = (servRes as List<dynamic>)
          .map((s) => ServiceItem.fromJson(s as Map<String, dynamic>))
          .toList();

      if (_isEdit) {
        final order =
            await ref.read(orderRepositoryProvider).getOrderById(widget.orderId!);
        _selectedCustomer = _allCustomers
            .where((c) => c.id == order.customerId)
            .firstOrNull;
        _selectedService = _allServices
            .where((s) => s.id == order.serviceId)
            .firstOrNull;
        _priceController.text = order.price.toStringAsFixed(0);
        _notesController.text = order.notes ?? '';
        _orderDate = DateTime.tryParse(order.orderDate) ?? DateTime.now();
        _deadline = DateTime.tryParse(order.deadline) ?? DateTime.now();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data awal: $e'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isInitLoading = false);
      }
    }
  }

  void _showCustomerPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String filter = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _allCustomers.where((c) {
              final q = filter.toLowerCase();
              return c.name.toLowerCase().contains(q) ||
                  c.whatsapp.contains(q);
            }).toList();

            return SafeArea(
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pilih Customer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showQuickAddCustomerDialog();
                            },
                            icon: const Icon(Icons.person_add_outlined, size: 18),
                            label: const Text('Customer Baru'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Ketik nama customer atau WA...',
                          prefixIcon: Icon(Icons.search_rounded, size: 20),
                        ),
                        onChanged: (val) {
                          setModalState(() => filter = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Tidak ada customer yang cocok'),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _showQuickAddCustomerDialog(
                                            initialName: filter);
                                      },
                                      icon: const Icon(Icons.add_rounded),
                                      label: Text(
                                          'Tambah "${filter.trim()}" Cepat'),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) => const Divider(
                                    height: 1, color: AppColors.divider),
                                itemBuilder: (context, idx) {
                                  final c = filtered[idx];
                                  final isSelected =
                                      _selectedCustomer?.id == c.id;
                                  return ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 8),
                                    title: Text(
                                      c.name,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textMain,
                                      ),
                                    ),
                                    subtitle: Text(
                                      c.whatsapp.isEmpty ? '-' : c.whatsapp,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted),
                                    ),
                                    trailing: isSelected
                                        ? const Icon(Icons.check_rounded,
                                            color: AppColors.primary)
                                        : null,
                                    onTap: () {
                                      setState(() => _selectedCustomer = c);
                                      Navigator.pop(ctx);
                                    },
                                  );
                                },
                              ),
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
  }

  void _showQuickAddCustomerDialog({String initialName = ''}) {
    final nameCtrl = TextEditingController(text: initialName);
    final waCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Tambah Customer Cepat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nama Customer',
                  hintText: 'Contoh: Ayiep',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: waCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor WhatsApp',
                  hintText: '08123456789',
                ),
              ),
            ],
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
                  final client = ref.read(supabaseClientProvider);
                  final res = await client.from('customers').insert({
                    'name': name,
                    'whatsapp': waCtrl.text.trim(),
                  }).select().single();

                  final newCust = Customer.fromJson(res);
                  setState(() {
                    _allCustomers.insert(0, newCust);
                    _selectedCustomer = newCust;
                  });
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal tambah customer: $e'),
                        backgroundColor: AppColors.destructive,
                      ),
                    );
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih customer terlebih dahulu'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih layanan terlebih dahulu'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    final price = num.tryParse(_priceController.text) ?? 0;
    final orderDateStr = DateFormat('yyyy-MM-dd').format(_orderDate);
    final deadlineStr = DateFormat('yyyy-MM-dd').format(_deadline);

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(orderRepositoryProvider);
      if (_isEdit) {
        await repo.updateOrder(
          id: widget.orderId!,
          customerId: _selectedCustomer!.id,
          serviceId: _selectedService!.id,
          price: price,
          deadline: deadlineStr,
          notes: _notesController.text,
        );
        ref.invalidate(orderDetailProvider(widget.orderId!));
        ref.invalidate(ordersListProvider);
        if (mounted) {
          context.pop();
        }
      } else {
        final newOrder = await repo.createOrder(
          customerId: _selectedCustomer!.id,
          serviceId: _selectedService!.id,
          price: price,
          orderDate: orderDateStr,
          deadline: deadlineStr,
          notes: _notesController.text,
        );
        ref.invalidate(ordersListProvider);
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(todoTodayProvider);
        if (mounted) {
          // Replace to newly created order detail screen
          context.pushReplacement('/orders/${newOrder.id}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan order: $e'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(_isEdit ? 'Edit Order' : 'Order Baru')),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Order' : 'Order Baru'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isEdit ? 'Simpan Perubahan' : 'Buat Order',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Customer Selector
              const Text(
                'Customer',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _showCustomerPicker,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        color: _selectedCustomer != null
                            ? AppColors.primary
                            : AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedCustomer != null
                              ? '${_selectedCustomer!.name} (${_selectedCustomer!.whatsapp.isEmpty ? "Tanpa WA" : _selectedCustomer!.whatsapp})'
                              : 'Pilih atau cari customer...',
                          style: TextStyle(
                            color: _selectedCustomer != null
                                ? AppColors.textMain
                                : AppColors.textMuted,
                            fontWeight: _selectedCustomer != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down_rounded,
                          color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 2. Service Dropdown
              const Text(
                'Layanan Master',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<ServiceItem>(
                initialValue: _selectedService,
                decoration: const InputDecoration(
                  hintText: 'Pilih layanan...',
                  prefixIcon: Icon(Icons.checkroom_outlined, size: 20),
                ),
                items: _allServices.map((s) {
                  return DropdownMenuItem<ServiceItem>(
                    value: s,
                    child: Text(
                      '${s.name} (${formatCurrency(s.defaultPrice)})',
                      style: const TextStyle(fontSize: 13.5),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedService = val;
                    // Auto-fill price only when creating order, don't overwrite if editing (PRD §6.4)
                    if (!_isEdit && val != null) {
                      _priceController.text =
                          val.defaultPrice.toStringAsFixed(0);
                    }
                  });
                },
                validator: (val) =>
                    val == null ? 'Layanan wajib dipilih' : null,
              ),
              const SizedBox(height: 18),

              // 3. Price Field
              const Text(
                'Harga Order (Rp)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                style: AppTheme.monoStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                  hintText: '500.000',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Harga wajib diisi';
                  }
                  if (num.tryParse(val) == null) {
                    return 'Format nominal angka tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // 4. Dates: Order Date & Deadline
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tanggal Order',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _isEdit
                              ? null // Order date is fixed on edit
                              : () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _orderDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setState(() => _orderDate = picked);
                                  }
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 16, color: AppColors.textMuted),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    formatDate(_orderDate),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Deadline',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _deadline,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() => _deadline = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event_available_outlined,
                                    size: 16, color: AppColors.statusProses),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    formatDate(_deadline),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 5. Notes Field
              const Text(
                'Catatan (Opsional)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Detail ukuran, revisi desain, dll...',
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
