import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:controle_financeiro/earning_category.dart';
import 'package:controle_financeiro/models/earning.dart';
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
  String? _editingEarningId;

  final Uuid uuid = const Uuid();

  void _clearFields() {
    setState(() {
      _amountController.clear();
      _selectedCategory = null;
      _editingEarningId = null;
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
      final earningData = {
        'amount': amount,
        'category': _selectedCategory,
        'date': Timestamp.now(),
      };

      if (_editingEarningId == null) {
        await FirebaseFirestore.instance.collection('earnings').add({
          ...earningData,
          'id': uuid.v4(),
        });
      } else {
        await FirebaseFirestore.instance
            .collection('earnings')
            .doc(_editingEarningId)
            .update(earningData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Ganho ${_editingEarningId == null ? 'registrado' : 'atualizado'} com sucesso!'),
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

  void _startEdit(
      String id, double currentAmount, String currentCategory) {
    setState(() {
      _editingEarningId = id;
      _amountController.text = currentAmount.toString();
      _selectedCategory = currentCategory;
    });
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
          ],
        ),
      ),
    );
  }

  Widget _buildAddEarningForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _editingEarningId == null
              ? 'Registrar Novo Ganho'
              : 'Editando Ganho',
          style: const TextStyle(fontSize: 24),
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

        final earnings = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: earnings.length,
          itemBuilder: (context, index) {
            final earning = earnings[index];
            final data = earning.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(
                    '${data['category']}: R\$ ${data['amount'].toStringAsFixed(2)}'),
                subtitle:
                    Text('${date.day}/${date.month}/${date.year}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _startEdit(
                        earning.id,
                        data['amount'],
                        data['category'],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteEarning(earning.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteEarning(String id) async {
    try {
      await FirebaseFirestore.instance.collection('earnings').doc(id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ganho excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir ganho: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}