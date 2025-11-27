import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // 1. Garante que o Flutter esteja pronto antes de carregar plugins
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Inicializa o Firebase usando a configuração gerada
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Gastos',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            "Firebase Conectado com Sucesso!", 
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}