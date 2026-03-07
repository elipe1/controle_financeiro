import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:controle_financeiro/screens/new_earning.dart';
import 'package:controle_financeiro/screens/new_expense.dart';
import 'package:controle_financeiro/services/currency_service.dart';
import 'package:flutter/material.dart';
import 'dart:developer';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _displayCurrency = 'BRL';

  final List<Widget> _pages = [Earning(), Expense()];
  final List<String> _currencies = ['BRL', 'USD', 'EUR', 'GBP', 'JPY'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Controle Financeiro',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildBalanceInAppBar(),
                _buildCurrencyDropdown(),
              ],
            ),
          ],
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Ganhos'),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Despesas',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyDropdown() {
    return DropdownButton<String>(
      value: _displayCurrency,
      dropdownColor: Colors.green,
      style: TextStyle(color: Colors.white),
      icon: Icon(Icons.arrow_drop_down, color: Colors.white),
      underline: Container(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _displayCurrency = newValue;
          });
        }
      },
      items: _currencies.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  String _getCurrencyName(String code) {
    final names = {
      'BRL': 'Real Brasileiro',
      'USD': 'Dólar Americano',
      'EUR': 'Euro',
      'GBP': 'Libra Esterlina',
      'JPY': 'Iene Japonês',
    };
    return names[code] ?? '';
  }

  Widget _buildBalanceInAppBar() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('earnings').snapshots(),
      builder: (context, earningsSnapshot) {
        if (earningsSnapshot.hasError) {
          log('Error fetching earnings: ${earningsSnapshot.error}', stackTrace: earningsSnapshot.stackTrace);
        }
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
          builder: (context, expensesSnapshot) {
            if (expensesSnapshot.hasError) {
              log('Error fetching expenses: ${expensesSnapshot.error}', stackTrace: expensesSnapshot.stackTrace);
            }
            if (earningsSnapshot.connectionState == ConnectionState.waiting ||
                expensesSnapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              );
            }

            final totalEarnings = (earningsSnapshot.data?.docs ?? [])
                .fold<double>(0, (sum, doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  log('Earning doc: ${doc.data()}');
                  final value = data['value'];
                  if (value != null && value is num) {
                    return sum + value.toDouble();
                  }
                  return sum;
                });

            final totalExpenses = (expensesSnapshot.data?.docs ?? [])
                .fold<double>(0, (sum, doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  log('Expense doc: ${doc.data()}');
                  final value = data['value'];
                  if (value != null && value is num) {
                    return sum + value.toDouble();
                  }
                  return sum;
                });

            final balance = totalEarnings - totalExpenses;

            return FutureBuilder<double>(
              future: _displayCurrency == 'BRL'
                  ? Future.value(balance)
                  : CurrencyService.convertCurrency('BRL', _displayCurrency, balance),
              builder: (context, snapshot) {
                final displayBalance = snapshot.data ?? balance;

                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: displayBalance >= 0
                        ? Colors.green[700]
                        : Colors.red[700],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_displayCurrency ${displayBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
