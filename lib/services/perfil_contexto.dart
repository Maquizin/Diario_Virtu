// lib/services/perfil_contexto.dart
//
// Texto com o contexto que o PRÓPRIO usuário informou em "Sobre mim", para
// ser anexado ao pedido do relatório. Só devolve algo se o usuário ligou a
// opção "Usar no relatório"; caso contrário devolve null.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'diario_service.dart';

class PerfilContexto {
  PerfilContexto._();

  static Future<String?> texto() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc =
        await DiarioService().firestore.collection('usuarios').doc(uid).get();
    final d = doc.data();
    if (d == null || d['usarNoRelatorio'] != true) return null;

    List<String> lista(String campo) =>
        ((d[campo] as List?) ?? const []).map((e) => '$e').toList();

    final linhas = <String>[];

    final nasc = d['nascimento'];
    if (nasc is Timestamp) {
      final n = nasc.toDate();
      final hoje = DateTime.now();
      var idade = hoje.year - n.year;
      if (hoje.month < n.month ||
          (hoje.month == n.month && hoje.day < n.day)) {
        idade--;
      }
      linhas.add('Idade: $idade anos');
    }
    final sexo = d['sexo'] as String?;
    if (sexo != null && sexo.isNotEmpty && sexo != 'Prefiro não informar') {
      linhas.add('Sexo: $sexo');
    }
    final sobre = (d['descricao'] as String?)?.trim() ?? '';
    if (sobre.isNotEmpty) linhas.add('Como a pessoa se descreve: $sobre');
    if (lista('gostos').isNotEmpty) {
      linhas.add('Coisas de que gosta: ${lista('gostos').join(', ')}');
    }
    if (lista('bem').isNotEmpty) {
      linhas.add('O que costuma lhe fazer bem: ${lista('bem').join(', ')}');
    }
    if (lista('mal').isNotEmpty) {
      linhas.add('O que costuma lhe deixar mal: ${lista('mal').join(', ')}');
    }
    final objetivo = (d['objetivo'] as String?)?.trim() ?? '';
    if (objetivo.isNotEmpty) {
      linhas.add('Objetivo com o diário: $objetivo');
    }

    if (linhas.isEmpty) return null;
    return 'Contexto informado pela própria pessoa (não é diagnóstico):\n'
        '${linhas.join('\n')}';
  }
}