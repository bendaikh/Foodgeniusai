import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:js' as js;
import '../../theme/app_theme.dart';
import '../../services/dodopayment_service.dart';

class InlineCheckoutDemoPage extends StatefulWidget {
  final String checkoutUrl;

  const InlineCheckoutDemoPage({
    super.key,
    required this.checkoutUrl,
  });

  @override
  State<InlineCheckoutDemoPage> createState() => _InlineCheckoutDemoPageState();
}

class _InlineCheckoutDemoPageState extends State<InlineCheckoutDemoPage> {
  final String _viewId = 'dodo-inline-checkout-${DateTime.now().millisecondsSinceEpoch}';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeCheckout();
  }

  void _initializeCheckout() {
    // Register the view factory for the inline checkout container
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) {
        final div = html.DivElement()
          ..id = 'dodo-inline-checkout'
          ..style.width = '100%'
          ..style.height = '600px'
          ..style.border = 'none';

        // Load DodoPayments SDK
        _loadDodoPaymentsSDK(div);

        return div;
      },
    );
  }

  void _loadDodoPaymentsSDK(html.DivElement container) {
    // Check if SDK is already loaded
    if (js.context.hasProperty('DodoPaymentsCheckout')) {
      _initializeDodoPayments();
      return;
    }

    // Load the SDK script
    final script = html.ScriptElement()
      ..src = 'https://cdn.jsdelivr.net/npm/dodopayments-checkout@latest/dist/index.js'
      ..onLoad.listen((_) {
        _initializeDodoPayments();
      })
      ..onError.listen((_) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load DodoPayments SDK'),
            backgroundColor: Colors.red,
          ),
        );
      });

    html.document.head?.append(script);
  }

  void _initializeDodoPayments() {
    try {
      // Initialize DodoPayments
      js.context.callMethod('eval', [
        '''
        DodoPaymentsCheckout.DodoPayments.Initialize({
          mode: "test",
          displayType: "inline",
          onEvent: function(event) {
            console.log('Checkout event:', event);
            
            if (event.event_type === 'checkout.breakdown') {
              console.log('Price breakdown:', event.data?.message);
            }
            
            if (event.event_type === 'checkout.form_ready') {
              console.log('Checkout form ready');
            }
            
            if (event.event_type === 'checkout.pay_button_clicked') {
              console.log('Pay button clicked');
            }
          }
        });
        
        DodoPaymentsCheckout.DodoPayments.Checkout.open({
          checkoutUrl: "${widget.checkoutUrl}",
          elementId: "dodo-inline-checkout",
          options: {
            showTimer: true,
            showSecurityBadge: true,
            payButtonText: "Complete Purchase",
          }
        });
        '''
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing DodoPayments: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('DodoPayment Inline Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isNarrow ? 16 : 32),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCheckoutPanel(),
                    const SizedBox(height: 16),
                    _buildOrderSummary(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildCheckoutPanel()),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: _buildOrderSummary()),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCheckoutPanel() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shopping_cart,
                    color: AppTheme.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complete Your Purchase',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Secure checkout powered by DodoPayments',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.greyText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Column(
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryGreen),
                  SizedBox(height: 16),
                  Text(
                    'Loading checkout...',
                    style: TextStyle(color: AppTheme.greyText),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 600,
              child: HtmlElementView(viewType: _viewId),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
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
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          _buildSummaryRow('Subtotal', 'Shown at checkout'),
          const SizedBox(height: 12),
          _buildSummaryRow('Tax', 'Calculated at checkout'),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.greyText),
          const SizedBox(height: 12),
          _buildSummaryRow('Total', 'See checkout form', isTotal: true),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.3),
              ),
            ),
            child: const Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.security, color: AppTheme.primaryGreen, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Secure Payment',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Your payment information is encrypted and secure',
                  style: TextStyle(fontSize: 12, color: AppTheme.greyText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.white : AppTheme.greyText,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppTheme.primaryGreen : Colors.white,
          ),
        ),
      ],
    );
  }
}
