import 'package:flutter/material.dart';
import 'dart:html' as html;

import '../../models/subscription_plan_model.dart';
import '../../models/user_model.dart';
import '../../services/dodopayment_service.dart';
import '../../services/firestore_service.dart';
import '../../services/subscription_plan_service.dart';
import '../../theme/app_theme.dart';
import 'inline_checkout_demo_page.dart';

class AdminPaymentsPage extends StatefulWidget {
  const AdminPaymentsPage({super.key});

  @override
  State<AdminPaymentsPage> createState() => _AdminPaymentsPageState();
}

class _AdminPaymentsPageState extends State<AdminPaymentsPage> {
  final SubscriptionPlanService _planService = SubscriptionPlanService();
  bool _isDodoPaymentConfigured = false;
  String? _testingCheckoutPlanId;

  @override
  void initState() {
    super.initState();
    _checkDodoPaymentConfig();
  }

  Future<void> _checkDodoPaymentConfig() async {
    await DodoPaymentService().loadConfiguration();
    if (mounted) {
      setState(() => _isDodoPaymentConfigured = DodoPaymentService().isConfigured);
    }
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  bool _isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }

  double _pagePadding(BuildContext context) {
    if (_isMobile(context)) return 16;
    if (_isTablet(context)) return 24;
    return 32;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: FirestoreService().getAllUsers(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (userSnapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${userSnapshot.error}'),
              ],
            ),
          );
        }

        final users = userSnapshot.data ?? [];

        return StreamBuilder<List<SubscriptionPlanModel>>(
          stream: _planService.watchAllPlans(),
          builder: (context, planSnapshot) {
            final plans = planSnapshot.data ?? [];

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(_pagePadding(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    if (!_isDodoPaymentConfigured)
                      _buildConfigurationWarning()
                    else ...[
                      _buildRevenueCards(context, users, plans),
                      const SizedBox(height: 24),
                      _buildPlansSection(context, plans),
                      const SizedBox(height: 24),
                      _buildTransactionsTable(context),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isMobile = _isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payments & Subscriptions',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create plans, manage DodoPayments products, and monitor revenue',
                style: TextStyle(fontSize: 14, color: AppTheme.greyText),
              ),
              if (_isDodoPaymentConfigured) ...[
                const SizedBox(height: 12),
                _buildConnectedBadge(),
              ],
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payments & Subscriptions',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create plans, manage DodoPayments products, and monitor revenue',
                      style: TextStyle(fontSize: 16, color: AppTheme.greyText),
                    ),
                  ],
                ),
              ),
              if (_isDodoPaymentConfigured) _buildConnectedBadge(),
            ],
          ),
      ],
    );
  }

  Widget _buildConnectedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          SizedBox(width: 8),
          Text(
            'DodoPayment Connected',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationWarning() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning, size: 64, color: Colors.orange),
          const SizedBox(height: 16),
          const Text(
            'DodoPayment Not Configured',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure DodoPayment in Settings before creating subscription plans.',
            style: TextStyle(fontSize: 16, color: AppTheme.greyText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCards(
    BuildContext context,
    List<UserModel> users,
    List<SubscriptionPlanModel> plans,
  ) {
    final activePlans = plans.where((p) => p.isActive).toList();
    final planPriceById = {for (final p in activePlans) p.id: p.price};

    double monthlyRevenue = 0;
    for (final user in users) {
      if (user.subscriptionStatus == 'active' &&
          user.subscriptionTier != 'free') {
        monthlyRevenue += planPriceById[user.subscriptionTier] ??
            _legacyPlanPrice(user.subscriptionTier);
      }
    }

    final activeSubscriptions =
        users.where((u) => u.subscriptionStatus == 'active' && u.subscriptionTier != 'free').length;

    final avgRevenuePerUser = activeSubscriptions > 0
        ? (monthlyRevenue / activeSubscriptions).toStringAsFixed(2)
        : '0.00';

    final cancelledUsers =
        users.where((u) => u.subscriptionStatus == 'cancelled').length;
    final totalPaidUsers = users
        .where((u) => u.subscriptionTier != 'free')
        .length;
    final churnRate = totalPaidUsers > 0
        ? ((cancelledUsers / (totalPaidUsers + cancelledUsers)) * 100)
            .toStringAsFixed(1)
        : '0.0';

    final cards = [
      _buildRevenueCard(
        'Monthly Revenue',
        '\$${monthlyRevenue.toStringAsFixed(2)}',
        'Estimated MRR',
        Icons.trending_up,
        Colors.green,
      ),
      _buildRevenueCard(
        'Active Subscriptions',
        activeSubscriptions.toString(),
        'Paid subscribers',
        Icons.people,
        Colors.blue,
      ),
      _buildRevenueCard(
        'Avg. Revenue Per User',
        '\$$avgRevenuePerUser',
        'Per active subscriber',
        Icons.person,
        AppTheme.primaryGreen,
      ),
      _buildRevenueCard(
        'Churn Rate',
        '$churnRate%',
        'Cancelled users',
        Icons.cancel,
        Colors.amber,
      ),
    ];

    if (_isMobile(context)) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    if (_isTablet(context)) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }

  double _legacyPlanPrice(String tier) {
    switch (tier) {
      case 'pro':
        return 12;
      case 'elite':
        return 29;
      default:
        return 0;
    }
  }

  Widget _buildRevenueCard(
    String title,
    String value,
    String change,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  change.split(' ')[0],
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: AppTheme.greyText),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansSection(
    BuildContext context,
    List<SubscriptionPlanModel> plans,
  ) {
    final isMobile = _isMobile(context);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DodoPayments Products & Checkout',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPlanActionButtons(context, isMobile: true),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DodoPayments Products & Checkout',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Plans created here appear on the user pricing page when active.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.greyText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildPlanActionButtons(context, isMobile: false),
                    ],
                  ),
          ),
          if (plans.isEmpty)
            Padding(
              padding: EdgeInsets.all(isMobile ? 24 : 48),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.inventory_2, size: 64, color: AppTheme.greyText),
                    const SizedBox(height: 16),
                    const Text(
                      'No Subscription Plans',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isMobile
                          ? 'Tap "Create Plan" to add your first product.'
                          : 'Click "Create Plan" to add your first subscription product.',
                      style: const TextStyle(fontSize: 14, color: AppTheme.greyText),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                0,
                isMobile ? 16 : 24,
                isMobile ? 16 : 24,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = isMobile
                      ? constraints.maxWidth
                      : _isTablet(context)
                          ? (constraints.maxWidth - 16) / 2
                          : 320.0;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: plans
                        .map((plan) => SizedBox(
                              width: cardWidth,
                              child: _buildPlanCard(context, plan),
                            ))
                        .toList(),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlanActionButtons(BuildContext context, {required bool isMobile}) {
    final createButton = ElevatedButton.icon(
      onPressed: () => _showPlanDialog(context),
      icon: const Icon(Icons.add, size: 16),
      label: const Text('Create Plan'),
      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
    );

    final demoButton = OutlinedButton.icon(
      onPressed: () => _showInlineCheckoutInfo(context),
      icon: const Icon(Icons.integration_instructions, size: 16),
      label: Text(isMobile ? 'Inline Demo' : 'View Inline Demo'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primaryGreen,
        side: const BorderSide(color: AppTheme.primaryGreen),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          createButton,
          const SizedBox(height: 8),
          demoButton,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        demoButton,
        const SizedBox(width: 12),
        createButton,
      ],
    );
  }

  Widget _buildPlanCard(BuildContext context, SubscriptionPlanModel plan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: plan.isActive
              ? AppTheme.primaryGreen.withOpacity(0.4)
              : AppTheme.greyText.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(plan.icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.description,
                      style: const TextStyle(fontSize: 13, color: AppTheme.greyText),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildStatusChip(plan.isActive),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${plan.formattedPrice}${plan.period}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
              if (plan.isPopular) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'POPULAR',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (plan.monthlyGenerationLimit > 0) ...[
            const SizedBox(height: 8),
            Text(
              plan.generationLimitLabel,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (plan.features.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...plan.features.take(3).map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check, size: 14, color: AppTheme.primaryGreen),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showPlanDialog(context, existing: plan),
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.4)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _togglePlanActive(plan),
                icon: Icon(plan.isActive ? Icons.visibility_off : Icons.visibility, size: 14),
                label: Text(plan.isActive ? 'Deactivate' : 'Activate'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: plan.isActive ? Colors.amber : Colors.green,
                  side: BorderSide(
                    color: (plan.isActive ? Colors.amber : Colors.green).withOpacity(0.5),
                  ),
                ),
              ),
              if (plan.isActive)
                ElevatedButton.icon(
                  onPressed: _testingCheckoutPlanId == plan.id
                      ? null
                      : () => _createCheckoutForPlan(plan),
                  icon: _testingCheckoutPlanId == plan.id
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.shopping_cart, size: 14),
                  label: Text(
                    _testingCheckoutPlanId == plan.id ? 'Creating…' : 'Test Checkout',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                ),
              TextButton.icon(
                onPressed: () => _confirmDeletePlan(plan),
                icon: const Icon(Icons.delete_outline, size: 14, color: Colors.red),
                label: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? Colors.green : Colors.grey).withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? Colors.green : AppTheme.greyText,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _togglePlanActive(SubscriptionPlanModel plan) async {
    try {
      await _planService.setPlanActive(plan.id, !plan.isActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              plan.isActive
                  ? '"${plan.name}" deactivated — hidden from users'
                  : '"${plan.name}" activated — visible on pricing page',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDeletePlan(SubscriptionPlanModel plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Delete Plan', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${plan.name}"? This removes it from Firestore but not from DodoPayments.',
          style: const TextStyle(color: AppTheme.greyText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.greyText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _planService.deletePlan(plan.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${plan.name}" deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showPlanDialog(BuildContext context, {SubscriptionPlanModel? existing}) {
    final isEditing = existing != null;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');
    final priceController = TextEditingController(
      text: existing != null ? existing.price.toString() : '',
    );
    final currencyController =
        TextEditingController(text: existing?.currency ?? 'USD');
    final iconController = TextEditingController(text: existing?.icon ?? '💎');
    final buttonTextController =
        TextEditingController(text: existing?.buttonText ?? 'Subscribe');
    final periodController =
        TextEditingController(text: existing?.period ?? '/ month');
    final featuresController = TextEditingController(
      text: existing?.features.join('\n') ?? '',
    );
    final generationLimitController = TextEditingController(
      text: existing != null && existing.monthlyGenerationLimit > 0
          ? existing.monthlyGenerationLimit.toString()
          : '',
    );
    var isPopular = existing?.isPopular ?? false;
    var isActive = existing?.isActive ?? true;
    var isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text(
            isEditing ? 'Edit Subscription Plan' : 'Create Subscription Plan',
            style: const TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Plan Name *',
                      hintText: 'e.g., Gourmet Pro',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Short plan description',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: priceController,
                          enabled: !isEditing,
                          decoration: InputDecoration(
                            labelText: 'Price *',
                            hintText: '10.00',
                            prefixText: currencyController.text == 'USD' ? '\$ ' : null,
                            helperText: isEditing
                                ? 'Price is set at creation (Dodo product)'
                                : 'Enter normal price (e.g. 10 for \$10)',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: currencyController,
                          enabled: !isEditing,
                          decoration: const InputDecoration(
                            labelText: 'Currency',
                            hintText: 'USD',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: iconController,
                          decoration: const InputDecoration(
                            labelText: 'Icon (emoji)',
                            hintText: '💎',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: periodController,
                          decoration: const InputDecoration(
                            labelText: 'Billing period label',
                            hintText: '/ month',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: buttonTextController,
                    decoration: const InputDecoration(
                      labelText: 'Button text',
                      hintText: 'Subscribe with DodoPayment',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: generationLimitController,
                    decoration: const InputDecoration(
                      labelText: 'Monthly AI recipe generations *',
                      hintText: 'e.g., 10, 25, 50',
                      helperText:
                          'Enforced automatically across the app and API',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: featuresController,
                    decoration: const InputDecoration(
                      labelText: 'Features (one per line)',
                      hintText: 'Unlock full recipes\nUnlimited portfolio',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mark as popular', style: TextStyle(color: Colors.white)),
                    subtitle: const Text(
                      'Shows a "POPULAR" badge on the pricing page',
                      style: TextStyle(color: AppTheme.greyText, fontSize: 12),
                    ),
                    value: isPopular,
                    activeColor: AppTheme.primaryGreen,
                    onChanged: (value) => setDialogState(() => isPopular = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active', style: TextStyle(color: Colors.white)),
                    subtitle: const Text(
                      'Only active plans appear for users',
                      style: TextStyle(color: AppTheme.greyText, fontSize: 12),
                    ),
                    value: isActive,
                    activeColor: AppTheme.primaryGreen,
                    onChanged: (value) => setDialogState(() => isActive = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.greyText)),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      final priceText = priceController.text.trim();
                      if (name.isEmpty || (!isEditing && priceText.isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Name and price are required'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      final features = featuresController.text
                          .split('\n')
                          .map((f) => f.trim())
                          .where((f) => f.isNotEmpty)
                          .toList();
                      final generationLimit =
                          int.tryParse(generationLimitController.text.trim()) ??
                              0;
                      if (generationLimit <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Monthly AI recipe generations must be greater than 0',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);

                      try {
                        if (isEditing) {
                          await _planService.updatePlan(
                            existing.copyWith(
                              name: name,
                              description: descriptionController.text.trim(),
                              features: features,
                              monthlyGenerationLimit: generationLimit,
                              icon: iconController.text.trim().isEmpty
                                  ? '💎'
                                  : iconController.text.trim(),
                              buttonText: buttonTextController.text.trim().isEmpty
                                  ? 'Subscribe'
                                  : buttonTextController.text.trim(),
                              period: periodController.text.trim().isEmpty
                                  ? '/ month'
                                  : periodController.text.trim(),
                              isPopular: isPopular,
                              isActive: isActive,
                            ),
                          );
                        } else {
                          final price = double.tryParse(priceText);
                          if (price == null || price <= 0) {
                            throw Exception('Enter a valid price greater than 0');
                          }

                          await _planService.createPlan(
                            name: name,
                            description: descriptionController.text.trim(),
                            price: price,
                            currency: currencyController.text.trim().toUpperCase(),
                            features: features,
                            monthlyGenerationLimit: generationLimit,
                            icon: iconController.text.trim().isEmpty
                                ? '💎'
                                : iconController.text.trim(),
                            buttonText: buttonTextController.text.trim().isEmpty
                                ? 'Subscribe'
                                : buttonTextController.text.trim(),
                            period: periodController.text.trim().isEmpty
                                ? '/ month'
                                : periodController.text.trim(),
                            isPopular: isPopular,
                            isActive: isActive,
                          );
                        }

                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEditing
                                    ? 'Plan updated successfully'
                                    : 'Plan created and synced to DodoPayments',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isEditing ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createCheckoutForPlan(SubscriptionPlanModel plan) async {
    if (plan.dodoProductId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This plan is missing a DodoPayments product ID. Recreate the plan.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _testingCheckoutPlanId = plan.id);

    try {
      await DodoPaymentService().loadConfiguration();
      if (!DodoPaymentService().isConfigured) {
        throw Exception('DodoPayment is not configured. Go to Settings first.');
      }

      final origin = html.window.location.origin;
      final successUrl =
          '$origin/payment-success?planId=${Uri.encodeComponent(plan.id)}';

      final session = await DodoPaymentService().createCheckoutSession(
        items: [
          {'product_id': plan.dodoProductId, 'quantity': 1},
        ],
        successUrl: successUrl,
        cancelUrl: '$origin/payment-cancel',
        metadata: {'planId': plan.id, 'tier': plan.id},
      );

      final sessionId = session['session_id']?.toString() ??
          session['id']?.toString() ??
          session['checkout_id']?.toString();

      final checkoutUrl = session['checkout_url'] as String? ??
          (sessionId != null
              ? DodoPaymentService().getCheckoutUrl(sessionId)
              : null);

      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw Exception('Checkout URL was not returned by DodoPayments.');
      }

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: const Text(
            'Checkout Session Created',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Test checkout for "${plan.name}"',
                  style: const TextStyle(color: AppTheme.greyText),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            InlineCheckoutDemoPage(checkoutUrl: checkoutUrl),
                      ),
                    );
                  },
                  icon: const Icon(Icons.integration_instructions),
                  label: const Text('Inline Checkout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => html.window.open(checkoutUrl, '_blank'),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open in New Window'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    checkoutUrl,
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close', style: TextStyle(color: AppTheme.greyText)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _testingCheckoutPlanId = null);
      }
    }
  }

  void _showInlineCheckoutInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Inline Checkout Demo', style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 64, color: AppTheme.primaryGreen),
            SizedBox(height: 16),
            Text(
              '1. Create or activate a plan\n'
              '2. Click "Test Checkout" on the plan card\n'
              '3. Choose "Inline Checkout" to preview the integration',
              style: TextStyle(fontSize: 14, color: AppTheme.greyText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(color: AppTheme.primaryGreen)),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTable(BuildContext context) {
    final isMobile = _isMobile(context);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: isMobile
                ? const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 48,
              0,
              isMobile ? 16 : 48,
              isMobile ? 24 : 48,
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.payment, size: 64, color: AppTheme.greyText),
                  SizedBox(height: 16),
                  Text(
                    'No Transaction Data',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Payment transactions will appear here once connected to DodoPayments reporting',
                    style: TextStyle(fontSize: 14, color: AppTheme.greyText),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
