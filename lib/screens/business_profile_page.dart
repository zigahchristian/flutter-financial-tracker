import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/models.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';


class BusinessProfilePage extends StatefulWidget {
  @override
  _BusinessProfilePageState createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();

  BusinessOwner? _existingOwner;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinessOwner();
  }

  Future<void> _loadBusinessOwner() async {
    try {
      final dbHelper = DatabaseHelper();
      final owner = await dbHelper.getPrimaryBusinessOwner();
      
      setState(() {
        _existingOwner = owner;
        _isLoading = false;
      });

      if (owner != null) {
        _nameController.text = owner.name;
        _emailController.text = owner.email;
        _phoneController.text = owner.phone;
        _businessNameController.text = owner.businessName;
        _addressController.text = owner.address;
      }
    } catch (e) {
      print('Error loading business owner: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveBusinessOwner() async {
    int generateIntUuid() {
    final uuid = const Uuid().v4();
    final bytes = utf8.encode(uuid);
    final digest = sha1.convert(bytes).bytes;

    int result = 0;
    for (int i = 0; i < 8; i++) {
      result = (result << 8) | digest[i];
    }
    return result;
  }

    if (_formKey.currentState!.validate()) {
      try {
        final dbHelper = DatabaseHelper();
        
        if (_existingOwner == null) {
          // Create new business owner
          final businessOwner = BusinessOwner(
            id: generateIntUuid(),
            name: _nameController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            businessName: _businessNameController.text,
            address: _addressController.text,
            createdAt: DateTime.now(),
          );
          await dbHelper.insertBusinessOwner(businessOwner);
        } else {
          // Update existing business owner
          final businessOwner = BusinessOwner(
            id: _existingOwner!.id, // Use the existing IDz
            name: _nameController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            businessName: _businessNameController.text,
            address: _addressController.text,
            createdAt: _existingOwner!.createdAt,
          );
          await dbHelper.updateBusinessOwner(businessOwner);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Business profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload to get the updated owner with ID
        await _loadBusinessOwner();

      } catch (e) {
        print('Error saving business profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving business profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.business, size: 30, color: Colors.blue),
                        SizedBox(width: 10),
                        Text(
                          'Business Profile',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      _existingOwner == null 
                          ? 'Setup your business information to include it in reports.'
                          : 'Update your business information.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _businessNameController,
                      decoration: InputDecoration(
                        labelText: 'Business Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.store),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter business name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Owner Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter owner name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveBusinessOwner,
                      child: Text(
                        _existingOwner == null 
                            ? 'Save Business Profile' 
                            : 'Update Business Profile',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            if (_existingOwner != null)
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Business Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      SizedBox(height: 10),
                      _buildInfoRow('Business:', _existingOwner!.businessName),
                      _buildInfoRow('Owner:', _existingOwner!.name),
                      if (_existingOwner!.email.isNotEmpty)
                        _buildInfoRow('Email:', _existingOwner!.email),
                      if (_existingOwner!.phone.isNotEmpty)
                        _buildInfoRow('Phone:', _existingOwner!.phone),
                      if (_existingOwner!.address.isNotEmpty)
                        _buildInfoRow('Address:', _existingOwner!.address),
                      _buildInfoRow('Created:', 
                        '${_existingOwner!.createdAt.toString().split(' ')[0]}'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}