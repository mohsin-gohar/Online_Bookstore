import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/utils/snackbar_helper.dart';
import '../data/models/faq_model.dart';
import '../data/repositories/support_repository.dart';
import 'common_widgets/custom_appbar.dart';
import 'common_widgets/loading_indicator.dart';

/// Help Center & FAQ Screen.
/// Directly satisfies the Non-Functional Requirement:
/// "Provide user guides, FAQs, and tutorials to help users understand and navigate the application."
class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  List<FaqModel> _allFaqs = [];
  List<FaqModel> _filteredFaqs = [];
  bool _loading = true;
  String _search = '';
  String _selectedCategory = 'All';

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = context.read<SupportRepository>();
      final faqs = await repo.getFaqs();
      if (!mounted) return;
      setState(() {
        _allFaqs = faqs;
        _applyFilter();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allFaqs = SupportRepository.fallbackFaqs;
        _applyFilter();
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _search.trim().toLowerCase();
    _filteredFaqs = _allFaqs.where((f) {
      final matchesSearch =
          query.isEmpty ||
          f.question.toLowerCase().contains(query) ||
          f.answer.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategory == 'All' ||
          f.category.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> _openContactSupportDialog() async {
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool sending = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            title: const Row(
              children: [
                Icon(Icons.support_agent_rounded, color: AppColors.accent),
                SizedBox(width: 8),
                Text(
                  'Contact Support',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Have an issue with your order or account? Send us a message and our team will get back to you.',
                      style: TextStyle(fontSize: 13, color: AppColors.grey400),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: subjectCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        hintText: 'e.g. Order #104 tracking update',
                        prefixIcon: Icon(Icons.subject_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter a subject'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: messageCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        hintText: 'Describe how we can help you...',
                      ),
                      validator: (v) => (v == null || v.trim().length < 10)
                          ? 'Please enter at least 10 characters'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: sending ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: sending
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => sending = true);
                        try {
                          await ctx.read<SupportRepository>().sendMessage(
                            subject: subjectCtrl.text,
                            message: messageCtrl.text,
                          );
                          if (!ctx.mounted) return;
                          Navigator.of(ctx).pop();
                          SnackbarHelper.showSuccess(
                            ctx,
                            'Message sent! Our support team will assist you.',
                          );
                        } catch (e) {
                          setDialogState(() => sending = false);
                          SnackbarHelper.showError(ctx, e.toString());
                        }
                      },
                child: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send Message'),
              ),
            ],
          ),
        ),
      );
    } finally {
      subjectCtrl.dispose();
      messageCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', 'Orders', 'Shipping', 'Payment', 'Account'];

    return Scaffold(
      appBar: const CustomAppBar(title: 'Help & FAQs', showCart: false),
      body: _loading
          ? const FullScreenLoader()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.md),
                children: [
                  // ── Search Input ──
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (val) {
                      setState(() {
                        _search = val;
                        _applyFilter();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search help questions & answers...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.accent,
                      ),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {
                                  _search = '';
                                  _applyFilter();
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(context).cardTheme.color,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        borderSide: BorderSide(
                          color: AppColors.accent.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                  Gaps.md,

                  // ── Category Chips ──
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = cat;
                                _applyFilter();
                              });
                            },
                            selectedColor: AppColors.accent.withValues(
                              alpha: 0.25,
                            ),
                            checkmarkColor: AppColors.accent,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.accent
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Gaps.lg,

                  // ── FAQ Accordion List ──
                  if (_filteredFaqs.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.help_outline_rounded,
                              size: 48,
                              color: AppColors.grey400,
                            ),
                            Gaps.sm,
                            const Text(
                              'No matching questions found',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Gaps.xs,
                            const Text(
                              'Try different keywords or contact our support team below.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.grey400),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._filteredFaqs.map((faq) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSizes.sm),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: ExpansionTile(
                          shape: const Border(),
                          collapsedShape: const Border(),
                          title: Text(
                            faq.question,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          leading: const Icon(
                            Icons.help_center_outlined,
                            color: AppColors.accent,
                            size: 22,
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  faq.answer,
                                  style: TextStyle(
                                    height: 1.5,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  Gaps.xl,

                  // ── Contact Support Card ──
                  Card(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.lightSurfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      side: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.headset_mic_rounded,
                            size: 40,
                            color: AppColors.accent,
                          ),
                          Gaps.sm,
                          const Text(
                            'Still have questions?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          Gaps.xs,
                          const Text(
                            'Our 24/7 dedicated customer care team is here to assist you.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.grey400,
                            ),
                          ),
                          Gaps.md,
                          ElevatedButton.icon(
                            onPressed: _openContactSupportDialog,
                            icon: const Icon(
                              Icons.mail_outline_rounded,
                              size: 18,
                            ),
                            label: const Text('Contact Support'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.brandDark,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Gaps.xl,
                ],
              ),
            ),
    );
  }
}
