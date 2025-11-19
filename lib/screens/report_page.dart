import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../services/database_helper.dart';
import '../services/pdf_service.dart';
import '../models/models.dart';
import 'package:intl/intl.dart';

class ReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  DateTime _startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _endDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  double _totalSales = 0.0;
  double _totalExpenses = 0.0;
  List<Map<String, dynamic>> _sales = [];
  List<Map<String, dynamic>> _expenses = [];
  BusinessOwner? _businessOwner;
  bool _isLoading = false;
  bool _isSingleDateMode = false; // false = range mode, true = single date mode

  @override
  void initState() {
    super.initState();
    _loadReport();
    _loadBusinessOwner();
  }

  Future<void> _loadBusinessOwner() async {
    try {
      final dbHelper = DatabaseHelper();
      final owner = await dbHelper.getPrimaryBusinessOwner();
      setState(() {
        _businessOwner = owner;
      });
    } catch (e) {
      print('Error loading business owner: $e');
    }
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbHelper = DatabaseHelper();
      
      if (_isSingleDateMode) {
        // Single date mode - get data for the selected single date
        final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        final endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);
        
        _sales = await dbHelper.getSalesByDateRange(startOfDay, endOfDay);
        _expenses = await dbHelper.getExpensesByDateRange(startOfDay, endOfDay);
        _totalSales = await dbHelper.getTotalSalesByDateRange(startOfDay, endOfDay);
        _totalExpenses = await dbHelper.getTotalExpensesByDateRange(startOfDay, endOfDay);
      } else {
        // Range mode - get data for the selected date range
        _sales = await dbHelper.getSalesByDateRange(_startDate, _endDate);
        _expenses = await dbHelper.getExpensesByDateRange(_startDate, _endDate);
        _totalSales = await dbHelper.getTotalSalesByDateRange(_startDate, _endDate);
        _totalExpenses = await dbHelper.getTotalExpensesByDateRange(_startDate, _endDate);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading report: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onDateRangeChanged(DateRangePickerSelectionChangedArgs args) {
    if (_isSingleDateMode) {
      if (args.value is DateTime) {
        final selectedDate = args.value as DateTime;
        setState(() {
          _selectedDate = selectedDate;
        });
        _loadReport();
      }
    } else {
      if (args.value is PickerDateRange) {
        final range = args.value as PickerDateRange;
        if (range.startDate != null && range.endDate != null) {
          setState(() {
            _startDate = range.startDate!;
            _endDate = range.endDate!;
          });
          _loadReport();
        }
      }
    }
  }

  void _selectToday() {
    setState(() {
      _selectedDate = DateTime.now();
      if (!_isSingleDateMode) {
        _startDate = DateTime.now();
        _endDate = DateTime.now();
      }
    });
    _loadReport();
  }

  void _selectYesterday() {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    setState(() {
      _selectedDate = yesterday;
      if (!_isSingleDateMode) {
        _startDate = yesterday;
        _endDate = yesterday;
      }
    });
    _loadReport();
  }

  void _selectLast7Days() {
    if (!_isSingleDateMode) {
      setState(() {
        _endDate = DateTime.now();
        _startDate = DateTime.now().subtract(Duration(days: 6));
      });
      _loadReport();
    }
  }

  void _selectLast30Days() {
    if (!_isSingleDateMode) {
      setState(() {
        _endDate = DateTime.now();
        _startDate = DateTime.now().subtract(Duration(days: 29));
      });
      _loadReport();
    }
  }

  void _toggleDateMode() {
    setState(() {
      _isSingleDateMode = !_isSingleDateMode;
      // Set sensible defaults when switching modes
      if (_isSingleDateMode) {
        _selectedDate = _endDate; // Use the end date as the single date
      } else {
        // When switching to range mode, set a default range
        _startDate = DateTime.now().subtract(Duration(days: 30));
        _endDate = DateTime.now();
      }
    });
    _loadReport();
  }

  Future<void> _generatePdfReport() async {
    DateTime startDate, endDate;
    
    if (_isSingleDateMode) {
      startDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      endDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);
    } else {
      startDate = _startDate;
      endDate = _endDate;
    }
    
    try {
      await PdfService.generateReport(
  sales: _sales,
  expenses: _expenses,
  startDate: startDate,
  endDate: endDate,
  totalSales: _totalSales,
  totalExpenses: _totalExpenses,

);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF report generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error generating PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getDateRangeText() {
    if (_isSingleDateMode) {
      return DateFormat('MMMM dd, yyyy').format(_selectedDate);
    } else {
      if (_startDate.year == _endDate.year && _startDate.month == _endDate.month && _startDate.day == _endDate.day) {
        return DateFormat('MMMM dd, yyyy').format(_startDate);
      } else {
        return '${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final netProfit = _totalSales - _totalExpenses;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
          child: Column(
            children: [
              // Date Selection Card
              Card(
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                  child: Column(
                    children: [
                      // Mode Toggle and Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isSingleDateMode ? 'Select Date' : 'Select Date Range',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Single',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  color: _isSingleDateMode ? Colors.blue : Colors.grey,
                                ),
                              ),
                              Switch(
                                value: _isSingleDateMode,
                                onChanged: (value) => _toggleDateMode(),
                                activeColor: Colors.blue,
                              ),
                              Text(
                                'Range',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  color: !_isSingleDateMode ? Colors.blue : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      
                      // Quick selection buttons
                      _buildQuickSelectionButtons(isSmallScreen),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      
                      // Selected date/range display
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isSingleDateMode ? Icons.calendar_today : Icons.date_range,
                              color: Colors.blue, 
                              size: isSmallScreen ? 16 : 18
                            ),
                            SizedBox(width: 8),
                            Text(
                              _getDateRangeText(),
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      
                      // Date Picker
                      Container(
                        height: isSmallScreen ? 200 : 250,
                        child: SfDateRangePicker(
                          onSelectionChanged: _onDateRangeChanged,
                          selectionMode: _isSingleDateMode 
                              ? DateRangePickerSelectionMode.single
                              : DateRangePickerSelectionMode.range,
                          initialSelectedDate: _selectedDate,
                          initialSelectedRange: _isSingleDateMode 
                              ? null 
                              : PickerDateRange(_startDate, _endDate),
                          showActionButtons: true,
                          showNavigationArrow: true,
                          monthViewSettings: DateRangePickerMonthViewSettings(
                            enableSwipeSelection: false,
                          ),
                          selectionColor: Colors.blue,
                          todayHighlightColor: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              
              if (_isLoading)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading Report...',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      // Business Owner Info
                      if (_businessOwner != null)
                        SliverToBoxAdapter(
                          child: _buildBusinessOwnerCard(isSmallScreen),
                        ),
                      
                      // Summary Section
                      SliverToBoxAdapter(
                        child: _buildSummarySection(isLargeScreen, isSmallScreen, netProfit),
                      ),
                      
                      // Generate PDF Button
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                          child: _buildPdfButton(isSmallScreen),
                        ),
                      ),
                      
                      // Transactions Tabs
                      SliverToBoxAdapter(
                        child: _buildTransactionsSection(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSelectionButtons(bool isSmallScreen) {
    return Column(
      children: [
        if (_isSingleDateMode) 
          // Single date quick selections
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _selectYesterday,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _selectedDate.day == DateTime.now().subtract(Duration(days: 1)).day ? 
                        Colors.blue : Colors.grey,
                    side: BorderSide(
                      color: _selectedDate.day == DateTime.now().subtract(Duration(days: 1)).day ? 
                          Colors.blue : Colors.grey,
                    ),
                  ),
                  child: Text(
                    'Yesterday',
                    style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _selectToday,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _selectedDate.day == DateTime.now().day ? 
                        Colors.blue : Colors.grey,
                    side: BorderSide(
                      color: _selectedDate.day == DateTime.now().day ? 
                          Colors.blue : Colors.grey,
                    ),
                  ),
                  child: Text(
                    'Today',
                    style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                  ),
                ),
              ),
            ],
          )
        else
          // Range quick selections
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _selectLast7Days,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _endDate.difference(_startDate).inDays == 6 ? 
                        Colors.blue : Colors.grey,
                    side: BorderSide(
                      color: _endDate.difference(_startDate).inDays == 6 ? 
                          Colors.blue : Colors.grey,
                    ),
                  ),
                  child: Text(
                    'Last 7 Days',
                    style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _selectLast30Days,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _endDate.difference(_startDate).inDays == 29 ? 
                        Colors.blue : Colors.grey,
                    side: BorderSide(
                      color: _endDate.difference(_startDate).inDays == 29 ? 
                          Colors.blue : Colors.grey,
                    ),
                  ),
                  child: Text(
                    'Last 30 Days',
                    style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildBusinessOwnerCard(bool isSmallScreen) {
    return Card(
      color: Colors.blue[50],
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, 
                  color: Colors.blue, 
                  size: isSmallScreen ? 20 : 24
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Business Profile (Included in PDF)',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              _businessOwner!.businessName,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_businessOwner!.name.isNotEmpty) 
              _buildInfoRow('Owner:', _businessOwner!.name, isSmallScreen),
            if (_businessOwner!.phone.isNotEmpty)
              _buildInfoRow('Phone:', _businessOwner!.phone, isSmallScreen),
            if (_businessOwner!.email.isNotEmpty)
              _buildInfoRow('Email:', _businessOwner!.email, isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(bool isLargeScreen, bool isSmallScreen, double netProfit) {
    return Card(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          children: [
            Text(
              _isSingleDateMode ? 'Daily Financial Summary' : 'Financial Summary',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              _getDateRangeText(),
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            
            if (isLargeScreen)
              // Horizontal layout for large screens
              Row(
                children: [
                  Expanded(child: _buildSummaryCard('Total Sales', _totalSales, Colors.green, Icons.trending_up, isSmallScreen)),
                  SizedBox(width: 8),
                  Expanded(child: _buildSummaryCard('Total Expenses', _totalExpenses, Colors.red, Icons.trending_down, isSmallScreen)),
                  SizedBox(width: 8),
                  Expanded(child: _buildSummaryCard(
                    'Net Profit', 
                    netProfit, 
                    netProfit >= 0 ? Colors.blue : Colors.orange,
                    netProfit >= 0 ? Icons.wallet : Icons.wallet,
                    isSmallScreen
                  )),
                ],
              )
            else
              // Vertical layout for small screens
              Column(
                children: [
                  _buildSummaryCard('Total Sales', _totalSales, Colors.green, Icons.trending_up, isSmallScreen),
                  SizedBox(height: 8),
                  _buildSummaryCard('Total Expenses', _totalExpenses, Colors.red, Icons.trending_down, isSmallScreen),
                  SizedBox(height: 8),
                  _buildSummaryCard(
                    'Net Profit', 
                    netProfit, 
                    netProfit >= 0 ? Colors.blue : Colors.orange,
                    netProfit >= 0 ? Icons.attach_money : Icons.money_off,
                    isSmallScreen
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon, bool isSmallScreen) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, 
              color: color, 
              size: isSmallScreen ? 24 : 30
            ),
            SizedBox(height: isSmallScreen ? 4 : 8),
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 2 : 4),
            Text(
              '\¢${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 18,
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

  Widget _buildPdfButton(bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _generatePdfReport,
        icon: Icon(Icons.picture_as_pdf, 
          size: isSmallScreen ? 20 : 24
        ),
        label: Text(
          _isSingleDateMode ? 'Generate Daily PDF Report' : 'Generate PDF Report',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, isSmallScreen ? 45 : 50),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 24,
            vertical: isSmallScreen ? 12 : 16,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsSection() {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  _isSingleDateMode ? 'Daily Transaction Details' : 'Transaction Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _getDateRangeText(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TabBar(
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.trending_up, size: 16),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Sales (${_sales.length})',
                                style: TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.trending_down, size: 16),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Expenses (${_expenses.length})',
                                style: TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 300,
                  child: TabBarView(
                    children: [
                      _buildTransactionList(_sales, true),
                      _buildTransactionList(_expenses, false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<Map<String, dynamic>> transactions, bool isSales) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSales ? Icons.trending_up : Icons.trending_down,
              size: 48,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No ${isSales ? 'sales' : 'expenses'} recorded\nfor ${_isSingleDateMode ? 'this day' : 'this period'}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final transactionDate = DateTime.parse(transaction['date']);
        
        return Card(
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          elevation: 1,
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSales ? Colors.green[50] : Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSales ? Icons.trending_up : Icons.trending_down,
                color: isSales ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
            title: Text(
              transaction['description'],
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['category'],
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  _isSingleDateMode 
                      ? DateFormat('h:mm a').format(transactionDate)
                      : DateFormat('MMM dd, yyyy').format(transactionDate),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\¢${transaction['amount'].toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSales ? Colors.green : Colors.red,
                    fontSize: 14,
                  ),
                ),
                Text(
                  isSales ? 'Sale' : 'Expense',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
        );
      },
    );
  }
}