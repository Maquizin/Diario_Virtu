// lib/screens/acessibilidade_screen.dart
import 'package:flutter/material.dart';

class AcessibilidadeScreen extends StatefulWidget {
  const AcessibilidadeScreen({super.key});

  @override
  State<AcessibilidadeScreen> createState() => _AcessibilidadeScreenState();
}

class _AcessibilidadeScreenState extends State<AcessibilidadeScreen> {
  double tamanhoTexto = 16;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Acessibilidade', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tamanho do texto', style: TextStyle(color: Colors.white, fontSize: 16)),
            Slider(
              activeColor: Colors.blueAccent,
              value: tamanhoTexto,
              min: 12,
              max: 24,
              divisions: 6,
              label: tamanhoTexto.round().toString(),
              onChanged: (v) => setState(() => tamanhoTexto = v),
            ),
            Text(
              'Exemplo de texto com esse tamanho.',
              style: TextStyle(color: Colors.white, fontSize: tamanhoTexto),
            ),
          ],
        ),
      ),
    );
  }
}