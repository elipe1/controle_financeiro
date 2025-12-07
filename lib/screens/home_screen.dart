import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:controle_financeiro/screens/earnings_screen.dart';
import 'package:controle_financeiro/screens/expenses_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Controle Financeiro'),
              _buildBalanceInAppBar(),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.payment), text: 'Despesas'),
              Tab(icon: Icon(Icons.attach_money), text: 'Ganhos'),
            ],
          ),
        ),
        body: const Expanded(
          child: TabBarView(
            children: [
              ExpensesScreen(), // Tela de Despesas
              EarningsScreen(), // Tela de Ganhos
            ],
          ),
        ),
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
                padding: const EdgeInsets.all(8),
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            final totalEarnings =
                (earningsSnapshot.data?.docs ?? []).fold<double>(
              0,
              (sum, doc) => sum + (doc['amount'] as num),
            );
            final totalExpenses =
                (expensesSnapshot.data?.docs ?? []).fold<double>(
              0,
              (sum, doc) => sum + (doc['value'] as num),
            );

            final balance = totalEarnings - totalExpenses;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: balance >= 0 
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'R\$${balance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: balance >= 0 ? Colors.green[800] : Colors.red[800],
                ),
              ),
            );
          },
        );
      },
    );
  }
}