import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models.dart';
import '../services/db_service.dart';
import '../theme.dart';
import '../widgets.dart';

class SavingsScreen extends StatelessWidget {
  final Group group;
  const SavingsScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: StreamBuilder<List<Txn>>(
            stream: Db.transactions(group.id),
            builder: (context, snap) {
              final txns = snap.data ?? const <Txn>[];
              final totalSaved = txns.fold(0.0, (a, t) => a + t.saved);
              final totalOrig = txns.fold(0.0, (a, t) => a + t.original);
              final eff = totalOrig > 0 ? totalSaved / totalOrig * 100 : 0.0;

              // last 6 months
              final now = DateTime.now();
              final months = [for (var i = 5; i >= 0; i--) DateTime(now.year, now.month - i, 1)];
              final perMonth = [
                for (final m in months)
                  txns.where((t) => t.date.year == m.year && t.date.month == m.month).fold(0.0, (a, t) => a + t.saved)
              ];
              final cur = perMonth.last, prev = perMonth[4];
              final trend = prev > 0 ? (cur - prev) / prev * 100 : null;
              final maxV = perMonth.reduce(max);

              // by category
              final byCat = <String, double>{};
              final cnt = <String, int>{};
              for (final t in txns) {
                byCat[t.category] = (byCat[t.category] ?? 0) + t.saved;
                cnt[t.category] = (cnt[t.category] ?? 0) + 1;
              }
              final cats = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

              return ListView(padding: const EdgeInsets.only(bottom: 30), children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 16, 0),
                  child: Row(children: [
                    IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).maybePop()),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Group Savings', style: hs(24)),
                        Text('Paisa Vasool Performance', style: bs(11, c: PV.muted)),
                      ]),
                    ),
                    const IconBox(Icons.insights, size: 44),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(children: [
                    Row(children: [
                      Expanded(child: PvCard(
                        radius: 18,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Total Saved', style: bs(12, c: PV.muted)),
                          const SizedBox(height: 6),
                          Text(inr(totalSaved), style: hs(24)),
                          const SizedBox(height: 4),
                          Row(children: [
                            Icon(trend != null && trend < 0 ? Icons.trending_down : Icons.trending_up, size: 14, color: trend != null && trend < 0 ? PV.red : PV.green),
                            const SizedBox(width: 4),
                            Flexible(child: Text(trend == null ? 'This month ${inr(cur)}' : '${trend >= 0 ? '+' : ''}${trend.round()}% vs last month',
                                style: bs(10, w: FontWeight.w600, c: trend != null && trend < 0 ? PV.red : PV.green))),
                          ]),
                        ]),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: PvCard(
                        radius: 18,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Eff. Discount', style: bs(12, c: PV.muted)),
                          const SizedBox(height: 6),
                          Text('${eff.toStringAsFixed(1)}%', style: hs(24)),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.trending_up, size: 14, color: PV.green),
                            const SizedBox(width: 4),
                            Text('Optimizing', style: bs(10, w: FontWeight.w600, c: PV.green)),
                          ]),
                        ]),
                      )),
                    ]),
                    const SizedBox(height: 14),
                    PvCard(
                      radius: 22,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('Savings Trend', style: hs(15)),
                          const Pill('Last 6 Months', fg: PV.ink, bg: Colors.white),
                        ]),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 170,
                          child: LineChart(LineChartData(
                            minY: 0,
                            maxY: max(1, maxV * 1.25),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            lineTouchData: const LineTouchData(enabled: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 26,
                                  interval: 1,
                                  getTitlesWidget: (v, meta) {
                                    final i = v.round();
                                    if (i < 0 || i > 5) return const SizedBox.shrink();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(monthName(months[i].month), style: bs(10, c: PV.muted)),
                                    );
                                  },
                                ),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: [for (var i = 0; i < 6; i++) FlSpot(i.toDouble(), perMonth[i])],
                                isCurved: true,
                                curveSmoothness: 0.3,
                                color: PV.green,
                                barWidth: 3,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(show: true, color: PV.green.withOpacity(0.12)),
                              ),
                            ],
                          )),
                        ),
                      ]),
                    ),
                    Align(alignment: Alignment.centerLeft, child: sectionTitle('Savings by Category')),
                    if (cats.isEmpty)
                      PvCard(child: Text('No payments yet. Savings appear here after your group pays through the optimizer.', style: bs(13, c: PV.muted))),
                    for (final c in cats)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: PvCard(
                          radius: 20,
                          child: Row(children: [
                            IconBox(catIcon(c.key), bg: catColor(c.key), size: 46),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('${c.key}${c.key == 'Travel' ? ' & Flights' : c.key == 'Food' ? ' & Dining' : ''}', style: hs(15)),
                                Text('${cnt[c.key]} transaction${cnt[c.key] == 1 ? '' : 's'} optimized', style: bs(11, c: PV.muted)),
                              ]),
                            ),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(inr(c.value), style: hs(16, c: PV.green)),
                              Text('${totalSaved > 0 ? (c.value / totalSaved * 100).round() : 0}% of total', style: bs(10, c: PV.muted)),
                            ]),
                          ]),
                        ),
                      ),
                  ]),
                ),
              ]);
            },
          ),
        ),
      );
}
