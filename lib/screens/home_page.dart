import 'package:flutter/material.dart';
import 'package:faustina/screens/sales_page.dart';
import 'package:faustina/screens/expenses_page.dart';
import 'package:faustina/screens/business_profile_page.dart';
import 'package:faustina/screens/charts_page.dart';
import 'package:faustina/screens/cloud_sync_page.dart';


import 'report_page.dart';



class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    SalesPage(),
    ExpensesPage(),
    ReportPage(),
    ChartsPage(),
    SimpleCloudSyncPage(), // Use simple cloud sync
    BusinessProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Finance Tracker'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Sales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_down),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.picture_as_pdf),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud),
            label: 'Sync',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}