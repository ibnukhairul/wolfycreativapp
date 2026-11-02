import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 19) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final todoAsync = ref.watch(todoTodayProvider);
    final isObscured = ref.watch(obscureRevenueProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(dashboardStatsProvider);
            ref.invalidate(todoTodayProvider);
            ref.invalidate(personalTodosProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Hero Greeting Card
                _buildHeroCard(context, ref, statsAsync),
                const SizedBox(height: 18),

                // 2. Stat Grid (5 Cards)
                _buildStatGrid(context, ref, statsAsync, isObscured),
                const SizedBox(height: 22),

                // 3. To Do Hari Ini Widget
                _buildTodoTodaySection(context, ref, todoAsync),
                const SizedBox(height: 20),

                // 4. To Do Pribadi Widget
                const _PersonalTodoSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<DashboardStats> statsAsync,
  ) {
    final now = DateTime.now();
    final todayStr = formatFullDate(now);
    final greeting = _getGreeting();

    final activeCount = statsAsync.maybeWhen(
      data: (stats) => stats.totalBaru + stats.totalProses,
      orElse: () => null,
    );

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
      child: Stack(
        children: [
          // Decorative blur elements
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            left: -35,
            bottom: -35,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.1),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date & Greeting
                Text(
                  todayStr.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$greeting, ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      'Khairul 👋',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Active orders headline
                Text(
                  activeCount == null
                      ? 'Memuat ringkasan...'
                      : activeCount > 0
                          ? 'Ada $activeCount order yang perlu dikerjakan'
                          : 'Semua order sudah beres! 🎉',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 18),

                // 3 Quick Action Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _QuickActionChip(
                      label: 'Order Baru',
                      icon: Icons.add_rounded,
                      isPrimary: true,
                      onTap: () => context.push('/orders/new'),
                    ),
                    _QuickActionChip(
                      label: 'Tambah Customer',
                      icon: Icons.person_add_outlined,
                      isPrimary: false,
                      onTap: () => context.push('/customers'),
                    ),
                    _QuickActionChip(
                      label: 'Lihat Kalender',
                      icon: Icons.calendar_month_outlined,
                      isPrimary: false,
                      onTap: () => context.push('/calendar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<DashboardStats> statsAsync,
    bool isObscured,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Order Baru',
                value: statsAsync.maybeWhen(
                  data: (s) => s.totalBaru.toString(),
                  orElse: () => '...',
                ),
                icon: Icons.assignment_outlined,
                iconColor: AppColors.statusBaru,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Order Proses',
                value: statsAsync.maybeWhen(
                  data: (s) => s.totalProses.toString(),
                  orElse: () => '...',
                ),
                icon: Icons.autorenew_rounded,
                iconColor: AppColors.statusProses,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Order Selesai',
                value: statsAsync.maybeWhen(
                  data: (s) => s.totalSelesai.toString(),
                  orElse: () => '...',
                ),
                icon: Icons.check_circle_outline_rounded,
                iconColor: AppColors.statusSelesai,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Piutang',
                value: statsAsync.maybeWhen(
                  data: (s) => formatCurrency(s.receivables),
                  orElse: () => '...',
                ),
                icon: Icons.credit_card_outlined,
                iconColor: AppColors.destructive,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Pendapatan Bulan Ini with eye toggle
        _StatCard(
          label: 'Pendapatan Bulan Ini',
          value: statsAsync.maybeWhen(
            data: (s) => isObscured ? 'Rp••••••••' : formatCurrency(s.revenue),
            orElse: () => '...',
          ),
          icon: Icons.account_balance_wallet_outlined,
          iconColor: AppColors.primary,
          trailing: IconButton(
            icon: Icon(
              isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: AppColors.textMuted,
            ),
            onPressed: () => ref.read(obscureRevenueProvider.notifier).toggle(),
          ),
        ),
      ],
    );
  }

  Widget _buildTodoTodaySection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<TodoItem>> todoAsync,
  ) {
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
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'To Do Hari Ini',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    todoAsync.maybeWhen(
                      data: (todos) => Text(
                        todos.isEmpty
                            ? 'Tidak ada order aktif'
                            : '${todos.length} order perlu perhatian',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      orElse: () => const Text(
                        'Memuat...',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
                todoAsync.maybeWhen(
                  data: (todos) => todos.isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${todos.length}',
                            style: AppTheme.monoStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Items
          todoAsync.when(
            data: (todos) {
              if (todos.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.inbox_outlined,
                            size: 26, color: AppColors.primary),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tidak ada order aktif',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Semua order sudah beres. Saatnya istirahat! ☕',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todos.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (context, index) {
                  final item = todos[index];
                  final overdue = item.daysLeft < 0;
                  final urgent = !overdue && item.daysLeft <= 2;

                  final deadlineText = overdue
                      ? 'Terlambat ${item.daysLeft.abs()} hari'
                      : item.daysLeft == 0
                          ? 'Deadline hari ini'
                          : '${item.daysLeft} hari lagi';

                  final deadlineColor = overdue
                      ? AppColors.destructive
                      : urgent
                          ? AppColors.statusProses
                          : AppColors.textMuted;

                  return InkWell(
                    onTap: () => context.push('/orders/${item.id}'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      item.invoiceNumber,
                                      style: AppTheme.monoStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textMain,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    StatusBadge(status: item.status),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.customerName} · ${item.serviceName}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.schedule_rounded,
                                        size: 13, color: deadlineColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      deadlineText,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: deadlineColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'Gagal memuat to-do: $err',
                style: const TextStyle(color: AppColors.destructive, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isPrimary
                ? Colors.white
                : Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isPrimary ? AppColors.primary : Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? AppColors.primary : Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Widget? trailing;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.monoStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _PersonalTodoSection extends ConsumerStatefulWidget {
  const _PersonalTodoSection();

  @override
  ConsumerState<_PersonalTodoSection> createState() => _PersonalTodoSectionState();
}

class _PersonalTodoSectionState extends ConsumerState<_PersonalTodoSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleAdd() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await ref.read(dashboardRepositoryProvider).addPersonalTodo(text);
    ref.invalidate(personalTodosProvider);
  }

  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(personalTodosProvider);

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
                'To Do Pribadi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              todosAsync.maybeWhen(
                data: (todos) {
                  final completed = todos.where((t) => t.isDone).length;
                  if (completed > 0) {
                    return TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () async {
                        await ref
                            .read(dashboardRepositoryProvider)
                            .clearCompletedPersonalTodos();
                        ref.invalidate(personalTodosProvider);
                      },
                      child: const Text(
                        'Clear selesai',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.destructive,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Input form
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Tambah pengingat...',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  onSubmitted: (_) => _handleAdd(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                onPressed: _handleAdd,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Checklist items
          todosAsync.when(
            data: (todos) {
              if (todos.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Belum ada pengingat. Tambahkan yang pertama!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todos.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (context, index) {
                  final todo = todos[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            todo.isDone
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 20,
                            color: todo.isDone
                                ? AppColors.statusSelesai
                                : AppColors.textMuted,
                          ),
                          onPressed: () async {
                            await ref
                                .read(dashboardRepositoryProvider)
                                .togglePersonalTodo(todo.id, !todo.isDone);
                            ref.invalidate(personalTodosProvider);
                          },
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            todo.title,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: todo.isDone
                                  ? AppColors.textMuted
                                  : AppColors.textMain,
                              decoration: todo.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppColors.textMuted),
                          onPressed: () async {
                            await ref
                                .read(dashboardRepositoryProvider)
                                .deletePersonalTodo(todo.id);
                            ref.invalidate(personalTodosProvider);
                          },
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
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, _) => Text(
              'Gagal memuat: $e',
              style: const TextStyle(fontSize: 12, color: AppColors.destructive),
            ),
          ),
        ],
      ),
    );
  }
}
