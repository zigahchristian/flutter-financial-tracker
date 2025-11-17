import 'package:flutter/material.dart';
import 'package:faustina/services/database_helper.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({Key? key}) : super(key: key);

  @override
  _ExpensesPageState createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Supplies';

  final List<String> _expenseCategories = ['Supplies', 'Utilities', 'Rent', 'Salaries', 'Other'];
  List<Map<String, dynamic>> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final dbHelper = DatabaseHelper();
    List<Map<String, dynamic>> expenses = await dbHelper.getExpenses();
    
    setState(() {
      _expenses = expenses;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final dbHelper = DatabaseHelper();
      final expense = {
        'date': _selectedDate.toIso8601String(),
        'description': _descriptionController.text,
        'amount': double.parse(_amountController.text),
        'category': _selectedCategory,
      };

      try {
        await dbHelper.insertExpense(expense);

        // Clear form
        _descriptionController.clear();
        _amountController.clear();
        setState(() {
          _selectedDate = DateTime.now();
          _selectedCategory = 'Supplies';
        });

        // Reload expenses
        await _loadExpenses();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expense added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding expense'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      'Add Expense',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                        prefixText: '\¢',
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _expenseCategories
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Text('Date: ${_selectedDate.toString().split(' ')[0]}'),
                        Spacer(),
                        TextButton(
                          onPressed: () => _selectDate(context),
                          child: Text('Select Date'),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: Text('Add Expense'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: _expenses.isEmpty
                ? Center(
                    child: Text('No expenses recorded'),
                  )
                : ListView.builder(
                    itemCount: _expenses.length,
                    itemBuilder: (context, index) {
                      final expense = _expenses[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Icon(
                            Icons.trending_down,
                            color: Colors.red,
                          ),
                          title: Text(expense['description']),
                          subtitle: Text('${expense['category']} • ${expense['date'].toString().split(' ')[0]}'),
                          trailing: Text(
                            '\¢${expense['amount'].toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}