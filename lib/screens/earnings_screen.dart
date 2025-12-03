import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:controle_financeiro/earning_category.dart';
import 'package:controle_financeiro/models/earning.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final TextEditingController _amountController = TextEditingController();
  String? _selectedCategory;
  Key _dropdownKey = UniqueKey();

  final Uuid uuid = const Uuid();

  void _clearFields() {
    setState(() {
      _amountController.clear();
      _selectedCategory = null;
      _dropdownKey = UniqueKey();
    });
  }

  Future<void> _saveEarning() async {
    if (_amountController.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Valor inválido.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('earnings').add({
        'id': uuid.v4(),
        'amount': amount,
        'category': _selectedCategory,
        'date': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ganho registrado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      _clearFields();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao registrar ganho: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAddEarningForm(),
            const SizedBox(height: 32),
            const Text(
              "Histórico de Ganhos",
              style: TextStyle(fontSize: 24),
            ),
            _buildEarningsList(),
            const SizedBox(height: 32),
            const Text(
              'Gráfico de Despesas',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(
              height: 300,
              child: _buildExpensesChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddEarningForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Registrar Novo Ganho',
          style: TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _amountController,
          decoration: const InputDecoration(
            labelText: 'Valor',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        DropdownMenu<String>(
          key: _dropdownKey,
          width: MediaQuery.of(context).size.width - 48,
          label: const Text('Categoria'),
          hintText: 'Escolha uma categoria',
          initialSelection: _selectedCategory,
          dropdownMenuEntries: EarningCategories.all.map((String cat) {
            return DropdownMenuEntry<String>(value: cat, label: cat);
          }).toList(),
          onSelected: (String? newValue) {
            setState(() {
              _selectedCategory = newValue;
            });
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: _saveEarning,
              icon: const Icon(Icons.save),
              label: const Text('Salvar Ganho'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEarningsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('earnings')
          .orderBy('date', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nenhum ganho registrado.'));
        }

        final earnings = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Earning(
            id: data.containsKey('id') ? data['id'] : '',
            amount: data['amount'],
            category: data['category'],
            date: (data['date'] as Timestamp).toDate(),
          );
        }).toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: earnings.length,
          itemBuilder: (context, index) {
            final earning = earnings[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(
                    '${earning.category}: R\$ ${earning.amount.toStringAsFixed(2)}'),
                subtitle:
                    Text('${earning.date.day}/${earning.date.month}/${earning.date.year}'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExpensesChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('Nenhuma despesa para exibir no gráfico.'));
        }

        Map<String, double> expenseByCategory = {};
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final category = data['category'] as String;
          final value = data['value'] as double;
          expenseByCategory.update(
              category, (existingValue) => existingValue + value,
              ifAbsent: () => value);
        }

        double totalExpense =
            expenseByCategory.values.fold(0, (sum, item) => sum + item);

        final List<Color> chartColors = [
          Colors.blue,
          Colors.red,
          Colors.yellow,
          Colors.purple,
          Colors.orange,
          Colors.teal,
          Colors.pink,
          Colors.amber,
        ];

        List<PieChartSectionData> sections =
            expenseByCategory.entries.map((entry) {
          final percentage = (entry.value / totalExpense) * 100;
          final colorIndex =
              expenseByCategory.keys.toList().indexOf(entry.key);
          return PieChartSectionData(
            value: percentage,
            title: '${percentage.toStringAsFixed(1)}%',
            color: chartColors[colorIndex % chartColors.length],
            radius: 80,
            titleStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList();

        return PieChart(
          PieChartData(
            sections: sections,
            sectionsSpace: 2,
            centerSpaceRadius: 40,
          ),
        );
      },
    );
  }
}