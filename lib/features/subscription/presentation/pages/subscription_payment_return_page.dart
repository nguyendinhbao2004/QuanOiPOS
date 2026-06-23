import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/subscription_providers.dart';

class SubscriptionPaymentReturnPage extends ConsumerStatefulWidget {
  final bool isCancelled;

  const SubscriptionPaymentReturnPage({super.key, required this.isCancelled});

  @override
  ConsumerState<SubscriptionPaymentReturnPage> createState() =>
      _SubscriptionPaymentReturnPageState();
}

class _SubscriptionPaymentReturnPageState
    extends ConsumerState<SubscriptionPaymentReturnPage> {
  @override
  void initState() {
    super.initState();
    unawaited(_completePaymentReturn());
  }

  Future<void> _completePaymentReturn() async {
    final notifier = ref.read(subscriptionNotifierProvider.notifier);
    await notifier.loadPlans();
    if (widget.isCancelled) {
      await notifier.cancelPendingPayment();
    } else {
      await notifier.refreshAfterPaymentReturn();
    }

    if (mounted) {
      context.go('/store-subscription');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
