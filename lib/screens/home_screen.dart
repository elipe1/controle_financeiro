import 'package:controle_financeiro/screens/earnings_screen.dart';
import 'package:controle_financeiro/screens/new_expense.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Controle Financeiro'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.payment), text: 'Despesas'),
              Tab(icon: Icon(Icons.attach_money), text: 'Ganhos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Expense(), // Tela de Despesas
            EarningsScreen(), // Tela de Ganhos
          ],
        ),
      ),
    );
  }
}