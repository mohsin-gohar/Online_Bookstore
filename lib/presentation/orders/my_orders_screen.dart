import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order_model.dart';
import '../../logic/auth_provider.dart';
import '../../logic/order_provider.dart';
import '../common_widgets/custom_appbar.dart';
import '../common_widgets/empty_state.dart';
import '../common_widgets/error_state.dart';
import 'widgets/order_status_chip.dart';

/// "My Orders": Order history matching Screen 5 in reference design.
class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(refresh: true));
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 300;
    if (_scrollController.position.pixels >= threshold) {
      final uid = context.read<AuthProvider>().uid;
      if (uid != null) context.read<OrderProvider>().loadMoreUserOrders(uid);
    }
  }

  Future<void> _load({bool refresh = false}) async {
    final uid = context.read<AuthProvider>().uid;
    if (uid == null) return;
    await context.read<OrderProvider>().loadUserOrders(uid, refresh: refresh);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orders = context.watch<OrderProvider>();
    final list = orders.orders;

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: const CustomAppBar(title: AppStrings.orders, showCart: false),
        body: EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Log in to see your orders',
          message: 'Your order history will appear here.',
          actionLabel: AppStrings.login,
          onAction: () => context.go(AppRoutes.loginPath),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: AppStrings.orders, showCart: true),
      body: orders.isLoadingOrders && list.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : orders.ordersError != null && list.isEmpty
          ? ErrorState(
              message: orders.ordersError!,
              onRetry: () => _load(refresh: true),
            )
          : list.isEmpty
          ? EmptyState(
              icon: Icons.receipt_long_outlined,
              title: AppStrings.emptyOrders,
              message: AppStrings.emptyOrdersBody,
              actionLabel: 'Start shopping',
              onAction: () => context.go(AppRoutes.catalogPath),
            )
          : RefreshIndicator(
              onRefresh: () => _load(refresh: true),
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  children: [
                    _OrderTableHeader(),
                    const Divider(height: 1),
                    ...list.map(
                      (order) => InkWell(
                        onTap: () =>
                            context.push(AppRoutes.orderDetails(order.id)),
                        child: _OrderTableRow(order: order),
                      ),
                    ),
                    if (orders.hasMoreOrders)
                      const Padding(
                        padding: EdgeInsets.all(AppSizes.md),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    Gaps.lg,
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go(AppRoutes.homePath),
                        icon: const Icon(Icons.home_outlined),
                        label: const Text('Back to Home'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _OrderTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 13,
      color: scheme.primary,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: scheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text('Order #', style: labelStyle),
          ),
          Expanded(
            flex: 2,
            child: Text('Date', style: labelStyle),
          ),
          Expanded(
            flex: 2,
            child: Text('Status', style: labelStyle),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Total',
              textAlign: TextAlign.right,
              style: labelStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTableRow extends StatelessWidget {
  const _OrderTableRow({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final dateStr = order.orderDate != null
        ? Formatters.date(order.orderDate!)
        : 'Recent';
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              Formatters.orderNumber(order.id),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              dateStr,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: OrderStatusChip(status: order.status, dense: true),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              Formatters.price(order.total),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
