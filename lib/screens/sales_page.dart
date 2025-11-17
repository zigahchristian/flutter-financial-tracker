import 'package:flutter/material.dart';
import '../services/database_helper.dart'; // Fixed import path

class SalesPage extends StatefulWidget {
  const SalesPage({Key? key}) : super(key: key);

  @override
  _SalesPageState createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Product Sales';

  final List<String> _saleCategories = ['Product Sales', 'Service', 'Other'];
  List<Map<String, dynamic>> _sales = [];

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    try {
      final dbHelper = DatabaseHelper();
      List<Map<String, dynamic>> sales = await dbHelper.getSales();
      
      setState(() {
        _sales = sales;
      });
    } catch (e) {
      print('Error loading sales: $e');
    }
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
      try {
        final dbHelper = DatabaseHelper();
        final sale = {
          'date': _selectedDate.toIso8601String(),
          'description': _descriptionController.text,
          'amount': double.parse(_amountController.text),
          'category': _selectedCategory,
        };

        await dbHelper.insertSale(sale);

        // Clear form
        _descriptionController.clear();
        _amountController.clear();
        setState(() {
          _selectedDate = DateTime.now();
          _selectedCategory = 'Product Sales';
        });

        // Reload sales
        await _loadSales();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sale added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error adding sale: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding sale: $e'),
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
                      'Add Sale',
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
                      items: _saleCategories
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
                      child: Text('Add Sale'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: _sales.isEmpty
                ? Center(
                    child: Text('No sales recorded'),
                  )
                : ListView.builder(
                    itemCount: _sales.length,
                    itemBuilder: (context, index) {
                      final sale = _sales[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Icon(
                            Icons.trending_up,
                            color: Colors.green,
                          ),
                          title: Text(sale['description']),
                          subtitle: Text('${sale['category']} • ${sale['date'].toString().split(' ')[0]}'),
                          trailing: Text(
                            '\¢${sale['amount'].toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
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