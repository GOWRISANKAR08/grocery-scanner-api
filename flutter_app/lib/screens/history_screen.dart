import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../services/auth_state.dart';
import 'product_screen.dart';
import 'subscription_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<HistoryItem>> _h = Api.history();
  Future<List<TrendPoint>>? _t;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user!;
    if (user.isPremium) _t ??= Api.trends();
    return Scaffold(
      appBar: AppBar(title: const Text('History'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() { _h = Api.history(); _t = user.isPremium ? Api.trends() : null; })),
      ]),
      body: ListView(children: [
        Padding(padding: const EdgeInsets.all(16), child: user.isPremium ? _trend() : _trendLocked(context)),
        FutureBuilder<List<HistoryItem>>(
          future: _h,
          builder: (c, s) {
            if (!s.hasData) return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
            if (s.data!.isEmpty) return const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No scans yet')));
            return Column(children: s.data!.map((i) => ListTile(
                  title: Text(i.name),
                  subtitle: Text(i.scannedAt.toLocal().toString().substring(0, 16)),
                  trailing: Text('${i.score.round()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => ProductScreen(barcode: i.barcode))),
                )).toList());
          },
        ),
      ]),
    );
  }

  Widget _trend() => FutureBuilder<List<TrendPoint>>(
        future: _t,
        builder: (c, s) {
          if (!s.hasData) return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
          final pts = s.data!;
          if (pts.length < 2) return const SizedBox(height: 80, child: Center(child: Text('Scan more to see your trend')));
          return SizedBox(
            height: 200,
            child: LineChart(LineChartData(
              minY: 0, maxY: 100,
              titlesData: const FlTitlesData(topTitles: AxisTitles(), rightTitles: AxisTitles(), bottomTitles: AxisTitles()),
              lineBarsData: [LineChartBarData(isCurved: true, barWidth: 3, spots: [for (var i = 0; i < pts.length; i++) FlSpot(i.toDouble(), pts[i].avg)])],
            )),
          );
        },
      );

  Widget _trendLocked(BuildContext context) => Card(
        child: ListTile(
          leading: const Icon(Icons.lock),
          title: const Text('Score trends'),
          subtitle: const Text('Premium feature'),
          trailing: FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())), child: const Text('Unlock')),
        ),
      );
}
