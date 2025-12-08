import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:controle_financeiro/screens/new_earning.dart';
import 'package:controle_financeiro/screens/new_expense.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Índice da página atual

  // Lista de páginas
  final List<Widget> _pages = [Earning(), Expense()];

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
            _buildBalanceInAppBar(),
          ],
        ),
      ),
      body: _pages[_currentIndex], // Exibe a página atual
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Atualiza a página
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

  Widget _buildBalanceInAppBar() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('earnings').snapshots(),
      builder: (context, earningsSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
          builder: (context, expensesSnapshot) {
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

            // ✅ Correção: Pega os dados corretamente e valida
            final totalEarnings = (earningsSnapshot.data?.docs ?? [])
                .fold<double>(0, (sum, doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final value = data['value'];
                  if (value != null && value is num) {
                    return sum + value.toDouble();
                  }
                  return sum;
                });

            final totalExpenses = (expensesSnapshot.data?.docs ?? [])
                .fold<double>(0, (sum, doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final value = data['value'];
                  if (value != null && value is num) {
                    return sum + value.toDouble();
                  }
                  return sum;
                });

            final balance = totalEarnings - totalExpenses;

            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: balance >= 0
                    ? Colors.green[700]
                    : Colors.red[700], // ✅ Cor forte
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'R\$ ${balance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // ✅ Texto branco para contrastar
                ),
              ),
            );
          },
        );
      },
    );
  }
}
