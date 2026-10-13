// lib/screens/tela_debug.dart
//
// Ferramentas de desenvolvedor. Só aparece em modo debug.
// Para adicionar uma ferramenta nova, acrescente um _acao(...) na lista.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/diario_service.dart';
import '../theme/tema.dart';

class TelaDebug extends StatelessWidget {
  const TelaDebug({super.key});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    void aviso(String msg) => ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));

    Widget acao({
      required IconData icone,
      required Color cor,
      required String titulo,
      required String subtitulo,
      required Future<void> Function() executar,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cores.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: ListTile(
          leading: Icon(icone, color: cor),
          title: Text(titulo, style: const TextStyle(color: Colors.white)),
          subtitle: Text(subtitulo,
              style: TextStyle(color: cores.textoSecundario)),
          onTap: () async {
            try {
              await executar();
            } catch (e) {
              aviso('Erro: $e');
            }
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Debug'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          acao(
            icone: Icons.science_outlined,
            cor: Colors.orangeAccent,
            titulo: 'Gerar dados de teste',
            subtitulo: 'Cria registros fictícios do mês passado',
            executar: () async {
              final agora = DateTime.now();
              await DiarioService()
                  .criarDadosDeTeste(DateTime(agora.year, agora.month - 1));
              aviso('Dados de teste criados (mês passado)');
            },
          ),
          acao(
            icone: Icons.delete_sweep_outlined,
            cor: Colors.grey,
            titulo: 'Apagar dados de teste',
            subtitulo: 'Remove só os registros de teste',
            executar: () async {
              await DiarioService().apagarDadosDeTeste();
              aviso('Dados de teste apagados');
            },
          ),
          acao(
            icone: Icons.copy_rounded,
            cor: Colors.cyanAccent,
            titulo: 'Copiar meu UID',
            subtitulo: FirebaseAuth.instance.currentUser?.uid ?? 'sem login',
            executar: () async {
              await Clipboard.setData(ClipboardData(
                  text: FirebaseAuth.instance.currentUser?.uid ?? ''));
              aviso('UID copiado');
            },
          ),
          // ↓ Acrescente novas ferramentas aqui.
        ],
      ),
    );
  }
}