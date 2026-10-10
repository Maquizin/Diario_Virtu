// lib/screens/botao_teste_ia.dart
//
// Botão TEMPORÁRIO para testar a conexão com a IA.
// Depois que funcionar, apague este arquivo e as 2 linhas na página.

import 'package:flutter/material.dart';

import '../services/relatorio_ia_service.dart';

class BotaoTesteIa extends StatefulWidget {
  const BotaoTesteIa({super.key});

  @override
  State<BotaoTesteIa> createState() => _BotaoTesteIaState();
}

class _BotaoTesteIaState extends State<BotaoTesteIa> {
  bool _carregando = false;
  String _resultado = '';

  Future<void> _testar() async {
    setState(() {
      _carregando = true;
      _resultado = '';
    });

    try {
      final texto = await RelatorioIAService().testarConexao();
      setState(() => _resultado = 'FUNCIONOU:\n$texto');
    } catch (e) {
      setState(() => _resultado = 'ERRO (${e.runtimeType}):\n$e');
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: _carregando ? null : _testar,
          child: Text(_carregando ? 'Testando...' : 'Testar IA'),
        ),
        if (_resultado.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SelectableText(
              _resultado,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
      ],
    );
  }
}