import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api.dart';
import '../services/auth_state.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _busy = false;

  /// Real flow:
  ///  1. Api.createOrder() -> order_id, key_id, amount
  ///  2. Open gateway SDK (e.g. razorpay_flutter) with those values
  ///  3. On success callback -> Api.verifyPayment(orderId, paymentId, signature)
  /// Until a gateway is wired in, this uses the dev-activate endpoint.
  Future<void> _subscribe() async {
    setState(() => _busy = true);
    try {
      final u = await Api.devActivate();
      if (!mounted) return;
      context.read<AuthState>().setUser(u);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _row(String t, bool free, bool prem) => ListTile(
        dense: true,
        title: Text(t),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(free ? Icons.check : Icons.close, color: free ? Colors.green : Colors.grey),
          const SizedBox(width: 32),
          Icon(prem ? Icons.check : Icons.close, color: prem ? Colors.green : Colors.grey),
        ]),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Go Premium')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const Align(alignment: Alignment.centerRight, child: Text('Free        Premium  ', style: TextStyle(fontWeight: FontWeight.bold))),
          _row('Overall health score & grade', true, true),
          _row('Diabetic suitability', true, true),
          _row('Basic scan history', true, true),
          _row('Full ingredient analysis', false, true),
          _row('Preservative & additive details', false, true),
          _row('Healthier alternatives', false, true),
          _row('Score trends over time', false, true),
          const SizedBox(height: 24),
          FilledButton(onPressed: _busy ? null : _subscribe, child: Text(_busy ? 'Please wait...' : 'Subscribe - Rs 99 / month')),
        ]),
      );
}
