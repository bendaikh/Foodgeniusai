import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';

class AdminPaymentsPage extends StatelessWidget {
  const AdminPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: FirestoreService().getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final users = snapshot.data ?? [];

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildRevenueCards(users),
                const SizedBox(height: 24),
                _buildTransactionsTable(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return const Column(
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
          'Monitor revenue and manage subscription payments',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.greyText,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueCards(List<UserModel> users) {
    final activeSubscriptions =
        users.where((u) => u.subscriptionStatus == 'active').length;
    
    final proUsers = users.where((u) => 
        u.subscriptionTier == 'pro' && u.subscriptionStatus == 'active').length;
    final eliteUsers = users.where((u) => 
        u.subscriptionTier == 'elite' && u.subscriptionStatus == 'active').length;
    
    final monthlyRevenue = (proUsers * 12.0) + (eliteUsers * 29.0);
    
    final avgRevenuePerUser = activeSubscriptions > 0
        ? (monthlyRevenue / activeSubscriptions).toStringAsFixed(2)
        : '0.00';
    
    final cancelledUsers = users.where((u) => 
        u.subscriptionStatus == 'cancelled').length;
    final totalPaidUsers = proUsers + eliteUsers;
    final churnRate = totalPaidUsers > 0
        ? ((cancelledUsers / (totalPaidUsers + cancelledUsers)) * 100).toStringAsFixed(1)
        : '0.0';

    return Row(
      children: [
        Expanded(
          child: _buildRevenueCard(
            'Monthly Revenue',
            '\$${monthlyRevenue.toStringAsFixed(2)}',
            'Estimated MRR',
            Icons.trending_up,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildRevenueCard(
            'Active Subscriptions',
            activeSubscriptions.toString(),
            'Paid subscribers',
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildRevenueCard(
            'Avg. Revenue Per User',
            '\$$avgRevenuePerUser',
            'Per active subscriber',
            Icons.person,
            AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildRevenueCard(
            'Churn Rate',
            '$churnRate%',
            'Cancelled users',
            Icons.cancel,
            Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueCard(
    String title,
    String value,
    String change,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
        ),
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
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.greyText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.filter_list, size: 16),
                      label: const Text('Filter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.greyText,
                        side: BorderSide(
                          color: AppTheme.primaryGreen.withOpacity(0.2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Export'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(48.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.payment,
                    size: 64,
                    color: AppTheme.greyText,
                  ),
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
                    'Payment transactions will appear here once payment integration is set up',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.greyText,
                    ),
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

  IconData _getPaymentIcon(String method) {
    if (method.contains('Visa')) return Icons.credit_card;
    if (method.contains('Mastercard')) return Icons.credit_card;
    if (method.contains('Amex')) return Icons.credit_card;
    return Icons.payment;
  }
}
