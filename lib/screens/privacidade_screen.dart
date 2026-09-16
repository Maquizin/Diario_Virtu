// lib/screens/privacidade_screen.dart
import 'package:flutter/material.dart';

class PrivacidadeScreen extends StatefulWidget {
  const PrivacidadeScreen({super.key});

  @override
  State<PrivacidadeScreen> createState() => _PrivacidadeScreenState();
}

class _PrivacidadeScreenState extends State<PrivacidadeScreen> {
  bool compartilharTextos = false;
  bool compartilharHumor = false;
  bool compartilharAudios = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Privacidade', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escolha o que um psicólogo autorizado poderá visualizar, caso você compartilhe seu diário.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              activeColor: Colors.purpleAccent,
              title: const Text('Textos das entradas', style: TextStyle(color: Colors.white)),
              value: compartilharTextos,
              onChanged: (v) => setState(() => compartilharTextos = v),
            ),
            SwitchListTile(
              activeColor: Colors.purpleAccent,
              title: const Text('Registros de humor', style: TextStyle(color: Colors.white)),
              value: compartilharHumor,
              onChanged: (v) => setState(() => compartilharHumor = v),
            ),
            SwitchListTile(
              activeColor: Colors.purpleAccent,
              title: const Text('Áudios', style: TextStyle(color: Colors.white)),
              value: compartilharAudios,
              onChanged: (v) => setState(() => compartilharAudios = v),
            ),
          ],
        ),
      ),
    );
  }
}