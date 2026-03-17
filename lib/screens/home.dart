import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:controle_financeiro/screens/dashboard.dart';
import 'package:controle_financeiro/screens/new_earning.dart';
import 'package:controle_financeiro/screens/new_expense.dart';
import 'package:controle_financeiro/screens/login.dart';
import 'package:controle_financeiro/services/auth_service.dart';
import 'package:controle_financeiro/services/currency_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _displayCurrency = 'R\$';
  final AuthService _authService = AuthService();
  User? _user;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _pages = [
      Dashboard(displayCurrency: _displayCurrency, symbolToCode: _symbolToCode),
      Earning(),
      Expense(),
    ];
  }

  final List<String> _currencies = ['R\$', 'US\$', '€', '£', '¥'];

  final Map<String, String> _currencyNames = {
    'R\$': 'R\$ - Reais',
    'US\$': 'US\$ - Dólar',
    '€': '€ - Euro',
    '£': '£ - Libra',
    '¥': '¥ - Iene',
  };

  final Map<String, String> _symbolToCode = {
    'R\$': 'BRL',
    'US\$': 'USD',
    '€': 'EUR',
    '£': 'GBP',
    '¥': 'JPY',
  };

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
                SizedBox(width: 16),
                _buildCurrencyDropdown(),
                SizedBox(width: 8),
                _buildAuthActions(),
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Ganhos'),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Despesas',
          ),
        ],
      ),
    );
  }

  Widget _buildAuthActions() {
    if (_user == null) {
      return IconButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoginScreen(),
            ),
          );
        },
        icon: Icon(Icons.person, color: Colors.white),
        tooltip: 'Login / Registro',
      );
    } else {
      return PopupMenuButton<String>(
        onSelected: (value) async {
          if (value == 'logout') {
            await _authService.signOut();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => LoginScreen()),
              (Route<dynamic> route) => false,
            );
          }
        },
        itemBuilder: (BuildContext context) {
          return [
            PopupMenuItem<String>(
              value: 'user_info',
              enabled: false,
              child: Text(
                _user!.email ?? 'Usuário',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            PopupMenuItem<String>(
              value: 'logout',
              child: Text('Sair'),
            ),
          ];
        },
        icon: Icon(Icons.person, color: Colors.white),
      );
    }
  }

  Widget _buildCurrencyDropdown() {
    return DropdownButton<String>(
      value: _displayCurrency,
      dropdownColor: Colors.green,
      style: TextStyle(
        color: Colors.white,
      ),
      icon: Icon(Icons.arrow_drop_down, color: Colors.white),
      underline: Container(),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _displayCurrency = newValue;
            _pages[0] = Dashboard(
                displayCurrency: _displayCurrency, symbolToCode: _symbolToCode);
          });
        }
      },
      selectedItemBuilder: (BuildContext context) {
        return _currencies.map<Widget>((String value) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(color: Colors.white)),
          );
        }).toList();
      },
      items: _currencies.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(_currencyNames[value] ?? value),
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
    if (_user == null) {
      return Container(); // ou um widget de placeholder
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('earnings')
          .snapshots(),
      builder: (context, earningsSnapshot) {
        if (earningsSnapshot.hasError) {
          log(
            'Error fetching earnings: ${earningsSnapshot.error}',
            stackTrace: earningsSnapshot.stackTrace,
          );
        }
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .collection('expenses')
              .snapshots(),
          builder: (context, expensesSnapshot) {
            if (expensesSnapshot.hasError) {
              log(
                'Error fetching expenses: ${expensesSnapshot.error}',
                stackTrace: expensesSnapshot.stackTrace,
              );
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
              future: _displayCurrency == 'R\$'
                  ? Future.value(balance)
                  : CurrencyService.convertCurrency(
                      'BRL',
                      _symbolToCode[_displayCurrency] ?? 'BRL',
                      balance,
                    ),
              builder: (context, snapshot) {
                final displayBalance = snapshot.data ?? balance;

                return Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: displayBalance >= 0
                        ? Colors.green[700]
                        : Colors.red[700],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_displayCurrency ${displayBalance.toStringAsFixed(2).replaceAll('.', ',')}',
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
