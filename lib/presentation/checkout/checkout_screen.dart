import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/address_model.dart';
import '../../data/models/order_item_model.dart';
import '../../data/models/order_model.dart';
import '../../data/models/payment_method_model.dart';
import '../../logic/auth_provider.dart';
import '../../logic/cart_provider.dart';
import '../../logic/order_provider.dart';
import '../../logic/profile_provider.dart';
import '../common_widgets/custom_appbar.dart';
import '../common_widgets/empty_state.dart';
import 'widgets/address_form_sheet.dart';
import 'widgets/payment_form_sheet.dart';

/// Checkout: pick a shipping address + payment method, review the order and
/// place it.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  AddressModel? _selectedAddress;
  PaymentMethodModel? _selectedPayment;
  bool _initialised = false;

  // ── Promo Code Support ──
  final TextEditingController _promoCtrl = TextEditingController();
  String? _appliedPromo;
  double _discountAmount = 0.0;
  String? _promoError;

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Preselect defaults once, after the profile is available.
    if (_initialised) return;
    final profile = context.read<ProfileProvider>();
    _selectedAddress = profile.defaultAddress;
    _selectedPayment = profile.defaultPaymentMethod;
    _initialised = true;
  }

  double get _subtotal => context.read<CartProvider>().subtotal;
  double get _shipping =>
      _appliedPromo == 'FREESHIP' ? 0.0 : OrderModel.computeShipping(_subtotal);
  double get _total =>
      (_subtotal - _discountAmount + _shipping).clamp(0.0, double.infinity);

  void _applyPromoCode() {
    final code = _promoCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    FocusScope.of(context).unfocus();

    if (code == 'APTECH20') {
      final discount = _subtotal * 0.20;
      setState(() {
        _appliedPromo = code;
        _discountAmount = discount;
        _promoError = null;
      });
      SnackbarHelper.showSuccess(
        context,
        'Promo APTECH20 applied! 20% discount',
      );
    } else if (code == 'BOOKSTORE10') {
      final discount = _subtotal * 0.10;
      setState(() {
        _appliedPromo = code;
        _discountAmount = discount;
        _promoError = null;
      });
      SnackbarHelper.showSuccess(
        context,
        'Promo BOOKSTORE10 applied! 10% discount',
      );
    } else if (code == 'WELCOME15') {
      final discount = _subtotal > 15 ? 15.0 : _subtotal * 0.5;
      setState(() {
        _appliedPromo = code;
        _discountAmount = discount;
        _promoError = null;
      });
      SnackbarHelper.showSuccess(context, 'Promo WELCOME15 applied! \$15 off');
    } else if (code == 'FREESHIP') {
      setState(() {
        _appliedPromo = code;
        _discountAmount = 0.0;
        _promoError = null;
      });
      SnackbarHelper.showSuccess(
        context,
        'Promo FREESHIP applied! Free shipping',
      );
    } else {
      setState(() {
        _promoError = 'Invalid code. Try APTECH20 or BOOKSTORE10';
      });
      SnackbarHelper.showError(
        context,
        'Invalid promo code. Try APTECH20 or BOOKSTORE10',
      );
    }
  }

  void _removePromoCode() {
    setState(() {
      _appliedPromo = null;
      _discountAmount = 0.0;
      _promoCtrl.clear();
      _promoError = null;
    });
    SnackbarHelper.showSuccess(context, 'Promo code removed');
  }

  /// Cash-on-delivery pseudo-method always available as a fallback.
  static const _cashOnDelivery = PaymentMethodModel(
    id: '__cod__',
    type: 'Cash on Delivery',
    last4: '',
    holderName: '',
    isDefault: false,
  );

  AddressModel? get _effectiveAddress =>
      _selectedAddress ?? context.read<ProfileProvider>().defaultAddress;

  PaymentMethodModel get _effectivePayment =>
      _selectedPayment ??
      context.read<ProfileProvider>().defaultPaymentMethod ??
      _cashOnDelivery;

  // ── Actions ───────────────

  Future<void> _addAddress() async {
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
    final address = await AddressFormSheet.show(
      context,
      makeDefaultFirst: profile.addresses.isEmpty,
    );
    if (address == null || !mounted) return;
    final ok = await profile.saveAddress(auth.uid!, address);
    if (!mounted) return;
    if (ok) {
      setState(() => _selectedAddress = address);
    } else if (profile.error != null) {
      SnackbarHelper.showError(context, profile.error!);
    }
  }

  Future<void> _addPayment() async {
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
    final method = await PaymentFormSheet.show(
      context,
      makeDefaultFirst: profile.paymentMethods.isEmpty,
    );
    if (method == null || !mounted) return;
    final ok = await profile.savePaymentMethod(auth.uid!, method);
    if (!mounted) return;
    if (ok) {
      setState(() => _selectedPayment = method);
    } else if (profile.error != null) {
      SnackbarHelper.showError(context, profile.error!);
    }
  }

  /// Builds the [OrderModel] from the current cart + selections and places it.
  Future<void> _placeOrder() async {
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();
    final orders = context.read<OrderProvider>();

    final address = _effectiveAddress;
    if (address == null) {
      SnackbarHelper.showWarning(context, 'Please add a shipping address.');
      return;
    }
    if (cart.items.isEmpty) {
      SnackbarHelper.showWarning(context, 'Your cart is empty.');
      return;
    }

    final payment = _effectivePayment;
    final paymentLabel = payment.isCashOnDelivery
        ? payment.type
        : '${payment.type} •••• ${payment.last4}';

    final order = OrderModel(
      id: '',
      userId: auth.uid!,
      userName: auth.user?.name ?? '',
      items: cart.items
          .map(
            (i) => OrderItemModel(
              bookId: i.bookId,
              title: i.title,
              price: i.price,
              qty: i.qty,
              coverImage: i.coverImage,
            ),
          )
          .toList(),
      subtotal: _subtotal,
      shipping: _shipping,
      total: _total,
      address: address.summary,
      paymentMethod: paymentLabel,
      orderDate: DateTime.now(),
      deliveryDate: DateTime.now().add(const Duration(days: 5)),
    );

    final created = await orders.placeOrder(order);
    if (!mounted) return;

    if (created != null) {
      // Clear the cart server-side and locally, then show success.
      await cart.clearCart();
      cart.clearLocal();
      if (!mounted) return;
      context.go(AppRoutes.orderSuccessPath, extra: created);
    } else if (orders.checkoutError != null) {
      SnackbarHelper.showError(context, orders.checkoutError!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final profile = context.watch<ProfileProvider>();
    final orders = context.watch<OrderProvider>();

    if (cart.items.isEmpty) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: AppStrings.checkout,
          showCart: false,
          fallbackRoute: AppRoutes.cartPath,
        ),
        body: EmptyState(
          icon: Icons.shopping_cart_outlined,
          title: AppStrings.emptyCart,
          message: AppStrings.emptyCartBody,
          actionLabel: 'Browse books',
          onAction: () => context.go(AppRoutes.catalogPath),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: AppStrings.checkout,
        showCart: false,
        fallbackRoute: AppRoutes.cartPath,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          // ── Shipping address ──
          _Section(
            title: 'Shipping Address',
            actionLabel: 'Add',
            onAction: _addAddress,
          ),
          Gaps.xs,
          if (profile.addresses.isEmpty)
            _EmptyCard(
              icon: Icons.location_off_outlined,
              message: 'No address yet. Tap "Add" to create one.',
              onTap: _addAddress,
            )
          else
            ...profile.addresses.map(
              (a) => _SelectableTile(
                selected: _effectiveAddress?.id == a.id,
                onTap: () => setState(() => _selectedAddress = a),
                leading: Icons.location_on_outlined,
                title: a.label,
                subtitle: a.summary,
                trailing: a.isDefault ? 'Default' : null,
              ),
            ),
          Gaps.lg,

          // ── Payment ──
          _Section(
            title: 'Payment Method',
            actionLabel: 'Add',
            onAction: _addPayment,
          ),
          Gaps.xs,
          ...profile.paymentMethods.map(
            (p) => _SelectableTile(
              selected: _effectivePayment.id == p.id,
              onTap: () => setState(() => _selectedPayment = p),
              leading: Icons.credit_card_rounded,
              title: '${p.type} •••• ${p.last4}',
              subtitle: 'Expires ${p.expiry} · ${p.holderName}',
              trailing: p.isDefault ? 'Default' : null,
            ),
          ),
          _SelectableTile(
            selected: _effectivePayment.id == _cashOnDelivery.id,
            onTap: () => setState(() => _selectedPayment = _cashOnDelivery),
            leading: Icons.payments_outlined,
            title: 'Cash on Delivery',
            subtitle: 'Pay when your order arrives',
          ),
          Gaps.lg,

          // ── Promo Code ──
          _Section(title: 'Promo / Coupon Code'),
          Gaps.xs,
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_appliedPromo == null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _promoCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'e.g. APTECH20 or BOOKSTORE10',
                              prefixIcon: const Icon(
                                Icons.local_offer_outlined,
                                color: AppColors.accent,
                                size: 20,
                              ),
                              errorText: _promoError,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        Gaps.hSm,
                        ElevatedButton(
                          onPressed: _applyPromoCode,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                    Gaps.xs,
                    const Text(
                      'Try "APTECH20" (20% off), "BOOKSTORE10" (10% off), or "FREESHIP"',
                      style: TextStyle(fontSize: 11, color: AppColors.grey400),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 20,
                          ),
                          Gaps.hSm,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Coupon "$_appliedPromo" Applied!',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                                Text(
                                  _appliedPromo == 'FREESHIP'
                                      ? 'Free shipping unlocked'
                                      : 'You saved ${Formatters.price(_discountAmount)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _removePromoCode,
                            child: const Text(
                              'Remove',
                              style: TextStyle(
                                color: AppColors.danger,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Gaps.lg,

          // ── Order summary ──
          _Section(title: 'Order Summary'),
          Gaps.xs,
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Items (${cart.itemCount})',
                    value: Formatters.price(_subtotal),
                  ),
                  Gaps.xs,
                  _SummaryRow(
                    label: AppStrings.shipping,
                    value: _shipping == 0
                        ? 'Free'
                        : Formatters.price(_shipping),
                  ),
                  if (_discountAmount > 0) ...[
                    Gaps.xs,
                    _SummaryRow(
                      label: 'Discount ($_appliedPromo)',
                      value: '-${Formatters.price(_discountAmount)}',
                      valueColor: AppColors.success,
                    ),
                  ],
                  const Divider(height: AppSizes.lg),
                  _SummaryRow(
                    label: AppStrings.total,
                    value: Formatters.price(_total),
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          Gaps.xxl,
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.total,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    Formatters.price(_total),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Gaps.hMd,
              Expanded(
                child: ElevatedButton(
                  onPressed: orders.isPlacingOrder ? null : _placeOrder,
                  child: orders.isPlacingOrder
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(AppStrings.placeOrder),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small building blocks ─────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        if (actionLabel != null && onAction != null)
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.message,
    required this.onTap,
  });

  final IconData icon;
  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.35),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          color: scheme.primary.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Icon(icon, color: scheme.primary),
            Gaps.hSm,
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.selected,
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final bool selected;
  final VoidCallback onTap;
  final IconData leading;
  final String title;
  final String subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
              color: selected
                  ? AppColors.brand
                  : scheme.onSurface.withValues(alpha: 0.12),
              width: selected ? 1.6 : 1,
            ),
            color: selected
                ? AppColors.brand.withValues(alpha: 0.05)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                leading,
                color: selected ? AppColors.brand : scheme.onSurface,
              ),
              Gaps.hSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (trailing != null) ...[
                          Gaps.hXs,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusPill,
                              ),
                            ),
                            child: Text(
                              trailing!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Gaps.xxs,
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? AppColors.brand
                    : scheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = bold
        ? theme.textTheme.titleMedium
        : theme.textTheme.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          value,
          style: style?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor ?? (bold ? AppColors.brand : null),
          ),
        ),
      ],
    );
  }
}
