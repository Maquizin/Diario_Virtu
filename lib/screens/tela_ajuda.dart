// lib/screens/tela_ajuda.dart
//
// "Preciso de ajuda": telefones de apoio emocional e emergência.
// A ligação abre o discador; o usuário só precisa tocar em "chamar".

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TelaAjuda extends StatelessWidget {
  const TelaAjuda({super.key});

  Future<void> _ligar(BuildContext context, String numero) async {
    final ok = await launchUrl(Uri(scheme: 'tel', path: numero));
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não consegui abrir o discador. Ligue $numero.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preciso de ajuda')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Você não precisa passar por isso sozinho(a). '
            'Se estiver em sofrimento, fale com alguém agora.',
            style: TextStyle(fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 20),
          _Contato(
            titulo: 'CVV – Centro de Valorização da Vida',
            detalhe: 'Apoio emocional 24 h, gratuito e sigiloso',
            numero: '188',
            icone: Icons.favorite_rounded,
            aoTocar: () => _ligar(context, '188'),
          ),
          _Contato(
            titulo: 'SAMU',
            detalhe: 'Emergência médica',
            numero: '192',
            icone: Icons.local_hospital_rounded,
            aoTocar: () => _ligar(context, '192'),
          ),
          const SizedBox(height: 16),
          const Text(
            'O SERENIA não substitui acompanhamento com psicólogo ou psiquiatra '
            'e não faz diagnóstico. Em caso de risco, procure ajuda imediatamente.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _Contato extends StatelessWidget {
  final String titulo, detalhe, numero;
  final IconData icone;
  final VoidCallback aoTocar;
  const _Contato({
    required this.titulo,
    required this.detalhe,
    required this.numero,
    required this.icone,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icone, color: Colors.redAccent),
        title: Text(titulo),
        subtitle: Text(detalhe),
        trailing: FilledButton(onPressed: aoTocar, child: Text('Ligar $numero')),
        onTap: aoTocar,
      ),
    );
  }
}