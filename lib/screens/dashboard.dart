import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:controle_financeiro/services/currency_service.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatelessWidget {
  final String displayCurrency;
  final Map<String, String> symbolToCode;

  const Dashboard({
    super.key,
    required this.displayCurrency,
    required this.symbolToCode,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('earnings').snapshots(),
      builder: (context, earningsSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance.collection('expenses').snapshots(),
          builder: (context, expensesSnapshot) {
            if (earningsSnapshot.connectionState == ConnectionState.waiting ||
                expensesSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final earningsDocs = earningsSnapshot.data?.docs ?? [];
            final expensesDocs = expensesSnapshot.data?.docs ?? [];

            final totalEarnings = earningsDocs.fold<double>(0, (sum, doc) {
              final data = doc.data() as Map<String, dynamic>;
              final value = data['value'];
              return value != null && value is num
                  ? sum + value.toDouble()
                  : sum;
            });

            final totalExpenses = expensesDocs.fold<double>(0, (sum, doc) {
              final data = doc.data() as Map<String, dynamic>;
              final value = data['value'];
              return value != null && value is num
                  ? sum + value.toDouble()
                  : sum;
            });

            final balance = totalEarnings - totalExpenses;

            return SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBalanceCard(balance),
                  SizedBox(height: 16),
                  _buildSummaryCards(totalEarnings, totalExpenses),
                  SizedBox(height: 24),
                  _buildCurrencyQuotes(context),
                  SizedBox(height: 24),
                  _buildRecentTransactions(earningsDocs, expensesDocs),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: balance >= 0 ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Saldo Atual',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            SizedBox(height: 8),
            FutureBuilder<double>(
              future: displayCurrency == 'R\$'
                  ? Future.value(balance)
                  : CurrencyService.convertCurrency(
                      'BRL',
                      symbolToCode[displayCurrency] ?? 'BRL',
                      balance,
                    ),
              builder: (context, snapshot) {
                final displayBalance = snapshot.data ?? balance;
                return Text(
                  '$displayCurrency ${displayBalance.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: displayBalance >= 0
                        ? Colors.green[700]
                        : Colors.red[700],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(double totalEarnings, double totalExpenses) {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.arrow_upward, color: Colors.green[700], size: 28),
                  SizedBox(height: 8),
                  Text(
                    'Ganhos',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'R\$ ${totalEarnings.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.arrow_downward, color: Colors.red[700], size: 28),
                  SizedBox(height: 8),
                  Text(
                    'Despesas',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'R\$ ${totalExpenses.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyQuotes(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cotações Atuais',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        FutureBuilder<Map<String, double>>(
          future: _fetchQuotes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            final quotes = snapshot.data ?? {};
            if (quotes.isEmpty) {
              return Text('Não foi possível carregar as cotações.');
            }
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  children: quotes.entries.map((entry) {
                    return ListTile(
                      leading: Icon(Icons.monetization_on,
                          color: Colors.green[700]),
                      title: Text(entry.key),
                      trailing: Text(
                        'R\$ ${entry.value.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<Map<String, double>> _fetchQuotes() async {
    final currencies = {
      'USD': 1.0,
      'EUR': 1.0,
      'GBP': 1.0,
      'JPY': 1.0,
    };

    final result = <String, double>{};
    for (final code in currencies.keys) {
      try {
        final value =
            await CurrencyService.convertCurrency(code, 'BRL', 1.0);
        result[code] = value;
      } catch (e) {
        // skip if conversion fails
      }
    }
    return result;
  }

  Widget _buildRecentTransactions(
    List<QueryDocumentSnapshot> earnings,
    List<QueryDocumentSnapshot> expenses,
  ) {
    final allTransactions = <Map<String, dynamic>>[];

    for (final doc in earnings) {
      final data = doc.data() as Map<String, dynamic>;
      allTransactions.add({
        'type': 'earning',
        'description': data['description'] ?? '',
        'value': (data['value'] as num?)?.toDouble() ?? 0,
        'originalValue':
            data.containsKey('originalValue')
                ? (data['originalValue'] as num).toDouble()
                : (data['value'] as num?)?.toDouble() ?? 0,
        'currency': data['currency'] ?? 'BRL',
        'category': data['category'] ?? '',
        'date': data['date'] as Timestamp?,
      });
    }

    for (final doc in expenses) {
      final data = doc.data() as Map<String, dynamic>;
      allTransactions.add({
        'type': 'expense',
        'description': data['description'] ?? '',
        'value': (data['value'] as num?)?.toDouble() ?? 0,
        'originalValue':
            data.containsKey('originalValue')
                ? (data['originalValue'] as num).toDouble()
                : (data['value'] as num?)?.toDouble() ?? 0,
        'currency': data['currency'] ?? 'BRL',
        'category': data['category'] ?? '',
        'date': data['date'] as Timestamp?,
      });
    }

    allTransactions.sort((a, b) {
      final dateA = a['date'] as Timestamp?;
      final dateB = b['date'] as Timestamp?;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    final recent = allTransactions.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Últimas Transações',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        if (recent.isEmpty)
          Center(child: Text('Nenhuma transação registrada.'))
        else
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: recent.map((transaction) {
                final isEarning = transaction['type'] == 'earning';
                final date = (transaction['date'] as Timestamp?)?.toDate();
                final currencyCode =
                    (transaction['currency'] as String).split(' ').first;
                final originalValue =
                    transaction['originalValue'] as double;

                return ListTile(
                  leading: Icon(
                    isEarning ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isEarning ? Colors.green[700] : Colors.red[700],
                  ),
                  title: Text(
                    (transaction['description'] as String).toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    date != null
                        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                        : '',
                  ),
                  trailing: Text(
                    '${isEarning ? '+' : '-'} $currencyCode ${originalValue.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isEarning ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
