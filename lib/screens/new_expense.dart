// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Expense extends StatefulWidget {
  const Expense({super.key});

  @override
  State<Expense> createState() => _ExpenseState();
}

class _ExpenseState extends State<Expense> {
  final TextEditingController description = TextEditingController();
  final TextEditingController value = TextEditingController();
  DateTime? date;
  String? category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar novo gasto'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text ("Digite os dados do novo gasto:", 
                style: TextStyle(
                  fontSize: 24,
                ),
              ),

              const SizedBox(height: 16),
              TextField(
                controller: description,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),
              TextField(
                controller: value,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor (R\$)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),
                Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text ("Data do gasto:",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                  ),
                  ElevatedButton(
                  onPressed: () async {
                    final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Colors.green,
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green,
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    },
                    );
                    if (selectedDate != null) {
                    setState(() {
                      date = selectedDate;
                    });
                    }
                  },
                  child: Text(date == null
                    ? 'Selecionar Data'
                    : 'Data: ${date!.day}/${date!.month}/${date!.year}'),
                  ),
                ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
