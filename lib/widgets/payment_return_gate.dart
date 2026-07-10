import 'package:flutter/material.dart';

import '../services/payment_return_service.dart';

/// Listens for payment deep links and app resume to finish mobile checkout.
class PaymentReturnGate extends StatefulWidget {
  final Widget child;

  const PaymentReturnGate({super.key, required this.child});

  @override
  State<PaymentReturnGate> createState() => _PaymentReturnGateState();
}

class _PaymentReturnGateState extends State<PaymentReturnGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PaymentReturnService.instance.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PaymentReturnService.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      PaymentReturnService.instance.handleAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
