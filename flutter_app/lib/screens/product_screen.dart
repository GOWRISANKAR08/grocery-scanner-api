import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../services/auth_state.dart';
import 'subscription_screen.dart';

String gradeOf(double s) => s >= 80 ? 'A' : s >= 65 ? 'B' : s >= 50 ? 'C' : s >= 35 ? 'D' : 'E';

Color gradeColor(String g) => switch (g) {
      'A' => Colors.green.shade700,
      'B' => Colors.lightGreen.shade700,
      'C' => Colors.amber.shade700,
      'D' => Colors.orange.shade800,
      _ => Colors.red.shade700,
    };

class ProductScreen extends StatefulWidget {
  final String barcode;
  const ProductScreen({super.key, required this.barcode});
  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late Future<Product> _f = Api.product(widget.barcode);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user!;
    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: FutureBuilder<Product>(
        future: _f,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('${snap.error}')));
          final p = snap.data!;
          final shown = user.isDiabetic ? p.diabeticScore : p.score;
          final g = gradeOf(shown);
          return ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              if (p.imageUrl != null)
                ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: p.imageUrl!, width: 96, height: 96, fit: BoxFit.cover)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, style: Theme.of(context).textTheme.titleLarge),
                if (p.brand != null) Text(p.brand!, style: const TextStyle(color: Colors.grey)),
              ])),
            ]),
            const SizedBox(height: 16),
            Card(
              color: gradeColor(g).withOpacity(.12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  CircleAvatar(radius: 36, backgroundColor: gradeColor(g), child: Text(g, style: const TextStyle(fontSize: 34, color: Colors.white, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${shown.round()}/100', style: Theme.of(context).textTheme.headlineSmall),
                    Text(user.isDiabetic ? 'Diabetic-diet score' : 'Overall health score'),
                    const SizedBox(height: 4),
                    Text(p.summary),
                  ])),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Chip(
              avatar: Icon(p.diabeticFriendly ? Icons.check_circle : Icons.warning_amber, color: p.diabeticFriendly ? Colors.green : Colors.orange),
              label: Text(p.diabeticFriendly ? 'Suitable for diabetic diet (${p.diabeticScore.round()})' : 'Not ideal for diabetics (${p.diabeticScore.round()})'),
            ),
            const SizedBox(height: 16),
            if (p.locked) _lockedCard(context) else ..._premium(context, p),
          ]);
        },
      ),
    );
  }

  Widget _lockedCard(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const Icon(Icons.lock, size: 36),
            const SizedBox(height: 8),
            const Text('Unlock ingredient analysis, preservative details, healthier alternatives and score trends.', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                if (!mounted) return;
                if (context.read<AuthState>().user!.isPremium) setState(() => _f = Api.product(widget.barcode));
              },
              child: const Text('Go Premium'),
            ),
          ]),
        ),
      );

  List<Widget> _premium(BuildContext context, Product p) {
    final t = Theme.of(context).textTheme.titleMedium;
    return [
      if (p.flags.isNotEmpty) Wrap(spacing: 6, children: p.flags.map((f) => Chip(label: Text(f))).toList()),
      const SizedBox(height: 8),
      Text('Preservatives & additives', style: t),
      if (p.preservatives.isEmpty) const ListTile(leading: Icon(Icons.verified, color: Colors.green), title: Text('None detected')),
      ...p.preservatives.map((a) => ListTile(
            dense: true,
            leading: Icon(Icons.science, color: [Colors.green, Colors.lightGreen, Colors.orange, Colors.red][a['risk'] as int]),
            title: Text('${a['code']} · ${a['name']}'),
            subtitle: Text(a['note']),
          )),
      const SizedBox(height: 8),
      Text('Nutrition per 100g', style: t),
      ...p.nutrition.entries.where((e) => !e.key.contains('penalty')).map((e) => ListTile(dense: true, title: Text(e.key.replaceAll('_', ' ')), trailing: Text('${e.value}'))),
      const SizedBox(height: 8),
      Text('Ingredients', style: t),
      Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(p.ingredients.isEmpty ? 'Not available' : p.ingredients.join(', '))),
      const SizedBox(height: 8),
      Text('Healthier alternatives', style: t),
      if (p.alternatives.isEmpty) const Text('No alternatives found'),
      ...p.alternatives.map((a) => ListTile(
            leading: a.imageUrl != null ? CachedNetworkImage(imageUrl: a.imageUrl!, width: 48, height: 48, fit: BoxFit.cover) : const Icon(Icons.shopping_basket),
            title: Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(a.brand ?? ''),
            trailing: Text('${a.score.round()}', style: const TextStyle(fontWeight: FontWeight.bold)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductScreen(barcode: a.barcode))),
          )),
    ];
  }
}
