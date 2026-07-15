import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class DaromadHisobot extends StatefulWidget {
  final String period;
  const DaromadHisobot({required this.period});

  @override
  _DaromadHisobotState createState() => _DaromadHisobotState();
}

class _DaromadHisobotState extends State<DaromadHisobot> {
  Map<String, double> _incomeData = {};
  List<String> _labels = [];
  double _totalIncome = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(DaromadHisobot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('tolovlar').get();

    _incomeData.clear();
    _totalIncome = 0;

    for (var doc in snapshot.docs) {
      DateTime date = ((doc['date'] as Timestamp?)?.toDate() ?? DateTime.now());
      double amount = (doc['amount'] as num? ?? 0).toDouble();
      _totalIncome += amount;

      String key;
      if (widget.period == 'week') {
        key = "${date.day}.${date.month}";
      } else if (widget.period == 'month') {
        key = "${date.month}.${date.year}";
      } else {
        key = "${date.year}";
      }

      _incomeData[key] = (_incomeData[key] ?? 0) + amount;
    }

    // Sort keys
    _labels = _incomeData.keys.toList();
    if (widget.period == 'month') {
      _labels.sort((a, b) {
        int monthA = int.parse(a.split('.')[0]);
        int monthB = int.parse(b.split('.')[0]);
        return monthA.compareTo(monthB);
      });
    } else if (widget.period == 'year') {
      _labels.sort();
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Daromad hisoboti",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Jami: ${(_totalIncome / 1000000).toStringAsFixed(2)}M so'm",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            if (_isLoading)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_incomeData.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.attach_money, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text("To'lov ma'lumotlari mavjud emas"),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 300,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _incomeData.values.reduce((a, b) => a > b ? a : b) *
                        1.2,
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            if (value >= 1000000) {
                              return Text(
                                  "${(value / 1000000).toStringAsFixed(0)}M");
                            } else if (value >= 1000) {
                              return Text(
                                  "${(value / 1000).toStringAsFixed(0)}K");
                            }
                            return Text(value.toInt().toString());
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 &&
                                value.toInt() < _labels.length) {
                              return Text(
                                _labels[value.toInt()],
                                style: TextStyle(fontSize: 10),
                              );
                            }
                            return Text('');
                          },
                          reservedSize: 40,
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: _labels.asMap().entries.map((entry) {
                      int index = entry.key;
                      String label = entry.value;
                      double value = _incomeData[label] ?? 0;

                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: value,
                            color: Colors.blue,
                            width: 30,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }).toList(),
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                  ),
                ),
              ),

            SizedBox(height: 16),

            // Summary
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.blue.shade700),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getSummaryText(),
                      style:
                          TextStyle(fontSize: 12, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSummaryText() {
    if (_incomeData.isEmpty) return "Ma'lumotlar mavjud emas";

    double maxIncome = _incomeData.values.reduce((a, b) => a > b ? a : b);
    double avgIncome = _totalIncome / _incomeData.length;

    return "Eng yuqori daromad: ${(maxIncome / 1000000).toStringAsFixed(2)}M so'm | "
        "O'rtacha: ${(avgIncome / 1000000).toStringAsFixed(2)}M so'm";
  }
}
