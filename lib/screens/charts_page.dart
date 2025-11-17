import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_helper.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class ChartsPage extends StatefulWidget {
  @override
  _ChartsPageState createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  DateTime _startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _endDate = DateTime.now();
  double _totalSales = 0.0;
  double _totalExpenses = 0.0;
  List<Map<String, dynamic>> _sales = [];
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = false;
  int _selectedChart = 0;

  final List<String> _chartTitles = [
    'Profit & Loss',
    'Sales vs Expenses',
    'Sales by Category',
    'Expenses by Category',
    'Monthly Trend'
  ];

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbHelper = DatabaseHelper();
      
      _sales = await dbHelper.getSalesByDateRange(_startDate, _endDate);
      _expenses = await dbHelper.getExpensesByDateRange(_startDate, _endDate);
      _totalSales = await dbHelper.getTotalSalesByDateRange(_startDate, _endDate);
      _totalExpenses = await dbHelper.getTotalExpensesByDateRange(_startDate, _endDate);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading chart data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, double> _getSalesByCategory() {
    Map<String, double> categoryData = {};
    for (var sale in _sales) {
      String category = sale['category'] ?? 'Uncategorized';
      double amount = (sale['amount'] as num?)?.toDouble() ?? 0.0;
      categoryData[category] = (categoryData[category] ?? 0) + amount;
    }
    return categoryData;
  }

  Map<String, double> _getExpensesByCategory() {
    Map<String, double> categoryData = {};
    for (var expense in _expenses) {
      String category = expense['category'] ?? 'Uncategorized';
      double amount = (expense['amount'] as num?)?.toDouble() ?? 0.0;
      categoryData[category] = (categoryData[category] ?? 0) + amount;
    }
    return categoryData;
  }

  Map<String, Map<String, double>> _getMonthlyTrend() {
    Map<String, Map<String, double>> monthlyData = {};
    
    for (var sale in _sales) {
      try {
        DateTime date = DateTime.parse(sale['date']);
        String monthKey = DateFormat('MMM yyyy').format(date);
        monthlyData.putIfAbsent(monthKey, () => {'sales': 0, 'expenses': 0});
        monthlyData[monthKey]!['sales'] = monthlyData[monthKey]!['sales']! + (sale['amount'] as num).toDouble();
      } catch (e) {
        print('Error parsing sale date: $e');
      }
    }
    
    for (var expense in _expenses) {
      try {
        DateTime date = DateTime.parse(expense['date']);
        String monthKey = DateFormat('MMM yyyy').format(date);
        monthlyData.putIfAbsent(monthKey, () => {'sales': 0, 'expenses': 0});
        monthlyData[monthKey]!['expenses'] = monthlyData[monthKey]!['expenses']! + (expense['amount'] as num).toDouble();
      } catch (e) {
        print('Error parsing expense date: $e');
      }
    }
    
    return monthlyData;
  }

  Widget _buildProfitLossChart(BuildContext context) {
    final netProfit = _totalSales - _totalExpenses;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
    // Ensure we have data to display
    if (_totalSales == 0 && _totalExpenses == 0) {
      return _buildEmptyChart('No financial data available');
    }

    return AspectRatio(
      aspectRatio: isSmallScreen ? 1.0 : 1.3,
      child: PieChart(
        PieChartData(
          sections: _showProfitLossSections(isSmallScreen),
          sectionsSpace: 2,
          centerSpaceRadius: isSmallScreen ? 30 : 40,
          centerSpaceColor: Colors.grey[100],
        ),
      ),
    );
  }

  List<PieChartSectionData> _showProfitLossSections(bool isSmallScreen) {
    // ignore: unused_local_variable
    final netProfit = _totalSales - _totalExpenses;
    
    // Handle case where all values are zero
    if (_totalSales == 0 && _totalExpenses == 0) {
      return [
        PieChartSectionData(
          value: 1,
          color: Colors.grey,
          title: 'No Data',
          radius: isSmallScreen ? 40 : 60,
          titleStyle: TextStyle(
            fontSize: isSmallScreen ? 10 : 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ];
    }

    List<PieChartSectionData> sections = [];

    if (_totalSales > 0) {
      sections.add(
        PieChartSectionData(
          value: _totalSales,
          color: Colors.green,
          title: isSmallScreen ? 
            'Sales\n\¢${(_totalSales / 1000).toStringAsFixed(_totalSales >= 1000 ? 0 : 1)}${_totalSales >= 1000 ? 'K' : ''}' :
            'Sales\n\¢${_totalSales.toStringAsFixed(0)}',
          radius: isSmallScreen ? 40 : 60,
          titleStyle: TextStyle(
            fontSize: isSmallScreen ? 10 : 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (_totalExpenses > 0) {
      sections.add(
        PieChartSectionData(
          value: _totalExpenses,
          color: Colors.red,
          title: isSmallScreen ?
            'Expenses\n\¢${(_totalExpenses / 1000).toStringAsFixed(_totalExpenses >= 1000 ? 0 : 1)}${_totalExpenses >= 1000 ? 'K' : ''}' :
            'Expenses\n\¢${_totalExpenses.toStringAsFixed(0)}',
          radius: isSmallScreen ? 40 : 60,
          titleStyle: TextStyle(
            fontSize: isSmallScreen ? 10 : 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return sections;
  }

  Widget _buildSalesVsExpensesChart(BuildContext context) {
    final netProfit = _totalSales - _totalExpenses;
    final maxValue = max(_totalSales, _totalExpenses) * 1.2;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
    if (maxValue == 0) {
      return _buildEmptyChart('No comparison data available');
    }

    return AspectRatio(
      aspectRatio: isSmallScreen ? 1.0 : 1.3,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue,
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: _totalSales,
                  color: Colors.green,
                  width: isSmallScreen ? 16 : 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: _totalExpenses,
                  color: Colors.red,
                  width: isSmallScreen ? 16 : 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(
                  toY: netProfit.abs(),
                  color: netProfit >= 0 ? Colors.blue : Colors.orange,
                  width: isSmallScreen ? 16 : 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  List<String> titles = ['Sales', 'Expenses', 'Profit'];
                  if (value.toInt() < titles.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        titles[value.toInt()],
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }
                  return Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatAmountForDisplay(value, isSmallScreen),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 8 : 10,
                      color: Colors.black54,
                    ),
                  );
                },
                reservedSize: isSmallScreen ? 30 : 40,
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300],
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey[400]!, width: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildSalesByCategoryChart(BuildContext context) {
    final categoryData = _getSalesByCategory();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
    if (categoryData.isEmpty) {
      return _buildEmptyChart('No sales data available');
    }

    return AspectRatio(
      aspectRatio: isSmallScreen ? 1.0 : 1.3,
      child: PieChart(
        PieChartData(
          sections: _getCategorySections(categoryData, true, isSmallScreen),
          sectionsSpace: 2,
          centerSpaceRadius: isSmallScreen ? 20 : 30,
        ),
      ),
    );
  }

  Widget _buildExpensesByCategoryChart(BuildContext context) {
    final categoryData = _getExpensesByCategory();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
    if (categoryData.isEmpty) {
      return _buildEmptyChart('No expenses data available');
    }

    return AspectRatio(
      aspectRatio: isSmallScreen ? 1.0 : 1.3,
      child: PieChart(
        PieChartData(
          sections: _getCategorySections(categoryData, false, isSmallScreen),
          sectionsSpace: 2,
          centerSpaceRadius: isSmallScreen ? 20 : 30,
        ),
      ),
    );
  }

  List<PieChartSectionData> _getCategorySections(
    Map<String, double> categoryData, 
    bool isSales, 
    bool isSmallScreen
  ) {
    final total = categoryData.values.fold(0.0, (sum, value) => sum + value);
    final colors = _getCategoryColors(categoryData.length);

    return categoryData.entries.map((entry) {
      final percentage = (entry.value / total * 100).toStringAsFixed(1);
      final color = colors[categoryData.keys.toList().indexOf(entry.key) % colors.length];
      
      return PieChartSectionData(
        value: entry.value,
        color: color,
        title: isSmallScreen ? 
          '${_abbreviateCategory(entry.key)}\n$percentage%' :
          '${entry.key}\n$percentage%',
        radius: isSmallScreen ? 30 : 40,
        titleStyle: TextStyle(
          fontSize: isSmallScreen ? 8 : 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildMonthlyTrendChart(BuildContext context) {
    final monthlyData = _getMonthlyTrend();
    final months = monthlyData.keys.toList();
    months.sort();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
    if (months.isEmpty) {
      return _buildEmptyChart('No data available for trend analysis');
    }

    // Find max value for Y axis
    double maxValue = 0;
    monthlyData.forEach((month, data) {
      maxValue = max(maxValue, max(data['sales']!, data['expenses']!));
    });
    maxValue = maxValue * 1.2;

    return AspectRatio(
      aspectRatio: isSmallScreen ? 1.0 : 1.3,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: months.asMap().entries.map((entry) {
                int index = entry.key;
                String month = entry.value;
                return FlSpot(index.toDouble(), monthlyData[month]!['sales']!);
              }).toList(),
              isCurved: true,
              color: Colors.green,
              barWidth: isSmallScreen ? 3 : 4,
              belowBarData: BarAreaData(show: false),
              dotData: FlDotData(show: true),
            ),
            LineChartBarData(
              spots: months.asMap().entries.map((entry) {
                int index = entry.key;
                String month = entry.value;
                return FlSpot(index.toDouble(), monthlyData[month]!['expenses']!);
              }).toList(),
              isCurved: true,
              color: Colors.red,
              barWidth: isSmallScreen ? 3 : 4,
              belowBarData: BarAreaData(show: false),
              dotData: FlDotData(show: true),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < months.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _abbreviateMonth(months[value.toInt()], isSmallScreen),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 8 : 10,
                          color: Colors.black54,
                        ),
                      ),
                    );
                  }
                  return Text('');
                },
                reservedSize: isSmallScreen ? 25 : 32,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatAmountForDisplay(value, isSmallScreen),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 8 : 10,
                      color: Colors.black54,
                    ),
                  );
                },
                reservedSize: isSmallScreen ? 30 : 40,
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300],
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey[400]!, width: 1),
          ),
          minY: 0,
          maxY: maxValue,
        ),
      ),
    );
  }

  String _formatAmountForDisplay(double value, bool isSmallScreen) {
    if (value >= 1000) {
      return '\¢${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}K';
    }
    return '\¢${value.toInt()}';
  }

  String _abbreviateCategory(String category) {
    if (category.length <= 8) return category;
    
    final words = category.split(' ');
    if (words.length > 1) {
      return words.map((word) => word[0]).join('').toUpperCase();
    }
    
    return category.substring(0, 6) + '..';
  }

  String _abbreviateMonth(String month, bool isSmallScreen) {
    if (isSmallScreen) {
      // Use only month abbreviation for small screens
      return month.split(' ')[0];
    }
    return month;
  }

  List<Color> _getCategoryColors(int count) {
    final baseColors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];
    
    if (count <= baseColors.length) {
      return baseColors.sublist(0, count);
    }
    
    // Generate additional colors if needed
    List<Color> colors = List.from(baseColors);
    for (int i = baseColors.length; i < count; i++) {
      colors.add(Color.fromARGB(
        255,
        Random().nextInt(200),
        Random().nextInt(200),
        Random().nextInt(200),
      ));
    }
    return colors;
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(Widget chart, String title, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            chart,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final netProfit = _totalSales - _totalExpenses;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isLargeScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Financial Analytics'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
          child: Column(
            children: [
              // Summary Cards - Responsive layout
              if (isLargeScreen)
                // Horizontal layout for large screens
                Row(
                  children: [
                    Expanded(child: _buildSummaryCard('Total Sales', _totalSales, Colors.green, isSmallScreen)),
                    SizedBox(width: 8),
                    Expanded(child: _buildSummaryCard('Total Expenses', _totalExpenses, Colors.red, isSmallScreen)),
                    SizedBox(width: 8),
                    Expanded(child: _buildSummaryCard(
                      'Net Profit', 
                      netProfit, 
                      netProfit >= 0 ? Colors.blue : Colors.orange,
                      isSmallScreen
                    )),
                  ],
                )
              else
                // Vertical layout for small/medium screens
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildSummaryCard('Total Sales', _totalSales, Colors.green, isSmallScreen)),
                        SizedBox(width: 8),
                        Expanded(child: _buildSummaryCard('Total Expenses', _totalExpenses, Colors.red, isSmallScreen)),
                      ],
                    ),
                    SizedBox(height: 8),
                    _buildSummaryCard(
                      'Net Profit', 
                      netProfit, 
                      netProfit >= 0 ? Colors.blue : Colors.orange,
                      isSmallScreen
                    ),
                  ],
                ),
              
              SizedBox(height: isSmallScreen ? 12 : 16),
              
              // Chart Selection - Scrollable for small screens
              Container(
                height: isSmallScreen ? 40 : 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _chartTitles.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          _chartTitles[index],
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 14,
                          ),
                        ),
                        selected: _selectedChart == index,
                        onSelected: (selected) {
                          setState(() {
                            _selectedChart = index;
                          });
                        },
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 12,
                          vertical: isSmallScreen ? 4 : 8,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              SizedBox(height: isSmallScreen ? 12 : 16),
              
              // Chart Display
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Loading Charts...',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildSelectedChart(context),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadChartData,
        child: Icon(Icons.refresh),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        tooltip: 'Refresh Charts',
        mini: isSmallScreen,
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, bool isSmallScreen) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 2 : 4),
            Text(
              '\¢${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedChart(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 0 : 8.0),
        child: _buildChartCard(
          _getCurrentChart(context),
          _chartTitles[_selectedChart],
          context,
        ),
      ),
    );
  }

  Widget _getCurrentChart(BuildContext context) {
    switch (_selectedChart) {
      case 0:
        return _buildProfitLossChart(context);
      case 1:
        return _buildSalesVsExpensesChart(context);
      case 2:
        return _buildSalesByCategoryChart(context);
      case 3:
        return _buildExpensesByCategoryChart(context);
      case 4:
        return _buildMonthlyTrendChart(context);
      default:
        return _buildProfitLossChart(context);
    }
  }
}