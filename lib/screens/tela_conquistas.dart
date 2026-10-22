// lib/screens/tela_conquistas.dart
//
// Conquistas: o usuário desbloqueia medalhas conforme usa o app.
// Tudo é calculado na hora a partir dos dados que já existem (registros,
// perfil, relatórios, preferências). Para criar uma conquista nova, acrescente
// um _Conquista(...) em _montar().

import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/entrada_diario.dart';
import '../services/bloqueio_biometrico.dart';
import '../services/perfil_service.dart';
import '../services/relatorio_service.dart';
import '../theme/tema.dart';
import '../widgets/animacoes.dart';
import '../services/diario_service.dart';

class _Conquista {
  final String titulo;
  final String descricao;
  final IconData icone;
  final Color cor;
  final int atual;
  final int meta;
  const _Conquista(this.titulo, this.descricao, this.icone, this.cor,
      {required this.atual, this.meta = 1});

  bool get ok => atual >= meta;
}

class _Grupo {
  final String nome;
  final List<_Conquista> itens;
  const _Grupo(this.nome, this.itens);
}

class TelaConquistas extends StatefulWidget {
  const TelaConquistas({super.key});

  @override
  State<TelaConquistas> createState() => _TelaConquistasState();
}

class _TelaConquistasState extends State<TelaConquistas> {
  List<_Grupo>? _grupos;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final entradas = await DiarioService().streamEntradas().first;

      SharedPreferences? prefs;
      try {
        prefs = await SharedPreferences.getInstance();
      } catch (_) {}

      Map<String, dynamic> perfil = {};
      try {
        perfil = await PerfilService.stream().first;
      } catch (_) {}

      int relatorios = 0;
      try {
        relatorios = (await RelatorioService().listar().first).length;
      } catch (_) {}

      final biometria = await BloqueioBiometrico.ativado();

      final grupos = _montar(
        entradas: entradas,
        prefs: prefs,
        perfil: perfil,
        relatorios: relatorios,
        biometria: biometria,
      );
      if (mounted) setState(() => _grupos = grupos);
    } catch (e) {
      if (mounted) setState(() => _erro = '$e');
    }
  }

  // ---------------------------------------------------------------- regras
  bool _favorita(EntradaDiario e) {
    try {
      return (e as dynamic).favorito == true;
    } catch (_) {
      return false;
    }
  }

  int _maiorSequencia(List<EntradaDiario> entradas) {
    final dias = entradas
        .map((e) => DateTime(e.data.year, e.data.month, e.data.day))
        .toSet()
        .toList()
      ..sort();
    var maior = 0, atual = 0;
    DateTime? anterior;
    for (final d in dias) {
      if (anterior != null && d.difference(anterior).inDays == 1) {
        atual++;
      } else {
        atual = 1;
      }
      maior = math.max(maior, atual);
      anterior = d;
    }
    return maior;
  }

  int _palavras(String t) {
    final s = t.trim();
    return s.isEmpty ? 0 : s.split(RegExp(r'\s+')).length;
  }

  List<_Grupo> _montar({
    required List<EntradaDiario> entradas,
    required SharedPreferences? prefs,
    required Map<String, dynamic> perfil,
    required int relatorios,
    required bool biometria,
  }) {
    final total = entradas.length;
    final sequencia = _maiorSequencia(entradas);
    final favoritos = entradas.where(_favorita).length;
    final maiorTexto =
        entradas.fold<int>(0, (m, e) => math.max(m, _palavras(e.texto)));

    final criada = FirebaseAuth.instance.currentUser?.metadata.creationTime;
    final dias = criada == null ? 0 : DateTime.now().difference(criada).inDays;

    bool tem(String chave) => prefs?.containsKey(chave) ?? false;
    final temFoto = (perfil['foto'] as String?)?.isNotEmpty ?? false;
    final temBanner = (perfil['banner'] as String?)?.isNotEmpty ?? false;

    return [
      _Grupo('Constância', [
        _Conquista('Três em sequência', 'Registre 3 dias seguidos',
            Icons.local_fire_department, Colors.orangeAccent,
            atual: sequencia, meta: 3),
        _Conquista('Uma semana inteira', 'Registre 7 dias seguidos',
            Icons.local_fire_department, Colors.deepOrangeAccent,
            atual: sequencia, meta: 7),
        _Conquista('Duas semanas', 'Registre 14 dias seguidos',
            Icons.whatshot, Colors.redAccent,
            atual: sequencia, meta: 14),
        _Conquista('Hábito criado', 'Registre 30 dias seguidos',
            Icons.emoji_events, Colors.amber,
            atual: sequencia, meta: 30),
      ]),
      _Grupo('Registros', [
        _Conquista('Primeiro passo', 'Faça o seu primeiro registro',
            Icons.edit_note, Colors.lightBlueAccent,
            atual: total, meta: 1),
        _Conquista('Pegando o jeito', 'Chegue a 10 registros',
            Icons.menu_book, Colors.cyanAccent,
            atual: total, meta: 10),
        _Conquista('Diário em dia', 'Chegue a 50 registros',
            Icons.auto_stories, Colors.tealAccent,
            atual: total, meta: 50),
        _Conquista('Centenário', 'Chegue a 100 registros',
            Icons.workspace_premium, Colors.greenAccent,
            atual: total, meta: 100),
        _Conquista('Desabafo', 'Escreva um registro com 100 palavras',
            Icons.notes, Colors.indigoAccent,
            atual: maiorTexto, meta: 100),
      ]),
      _Grupo('Favoritos', [
        _Conquista('Guardado com carinho', 'Favorite um registro',
            Icons.star, Colors.amber,
            atual: favoritos, meta: 1),
        _Conquista('Coleção de momentos', 'Favorite 5 registros',
            Icons.stars, Colors.amberAccent,
            atual: favoritos, meta: 5),
      ]),
      _Grupo('Do seu jeito', [
        _Conquista('Fundo personalizado', 'Troque o fundo do diário',
            Icons.layers, Colors.purpleAccent,
            atual: tem('diario_fundo') ? 1 : 0),
        _Conquista('Letra sob medida', 'Ajuste o tamanho da letra',
            Icons.text_fields, Colors.blueAccent,
            atual: tem('diario_fonte') ? 1 : 0),
        _Conquista('Com a sua cara', 'Escolha uma foto de perfil',
            Icons.account_circle, Colors.pinkAccent,
            atual: temFoto ? 1 : 0),
        _Conquista('Capa própria', 'Escolha um banner',
            Icons.panorama, Colors.pink,
            atual: temBanner ? 1 : 0),
      ]),
      _Grupo('Segurança', [
        _Conquista('Confidencial', 'Ative o bloqueio por biometria',
            Icons.fingerprint, Colors.greenAccent,
            atual: biometria ? 1 : 0),
        _Conquista('Cópia de segurança', 'Exporte os seus dados',
            Icons.cloud_download, Colors.lightGreenAccent,
            atual: tem('conquista_exportou') ? 1 : 0),
      ]),
      _Grupo('Relatórios', [
        _Conquista('Olhar para trás', 'Gere o seu primeiro relatório mensal',
            Icons.insights, Colors.tealAccent,
            atual: relatorios, meta: 1),
      ]),
      _Grupo('Tempo de SERENIA', [
        _Conquista('Um mês de casa', 'Use o app por 1 mês',
            Icons.calendar_month, Colors.lightBlueAccent,
            atual: dias, meta: 30),
        _Conquista('Três meses', 'Use o app por 3 meses',
            Icons.calendar_month, Colors.blueAccent,
            atual: dias, meta: 90),
        _Conquista('Meio ano', 'Use o app por 6 meses',
            Icons.event_available, Colors.indigoAccent,
            atual: dias, meta: 180),
        _Conquista('Um ano', 'Use o app por 1 ano',
            Icons.cake, Colors.amber,
            atual: dias, meta: 365),
      ]),
    ];
  }

  // ---------------------------------------------------------------- tela
  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Conquistas'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _erro != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Não consegui carregar: $_erro',
                    textAlign: TextAlign.center),
              ),
            )
          : _grupos == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    children: [
                      _resumo(cores),
                      for (final g in _grupos!) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 18, bottom: 10),
                          child: Text(g.nome,
                              style: TextStyle(
                                  color: cores.textoSecundario,
                                  fontSize: 13,
                                  letterSpacing: 0.6,
                                  fontWeight: FontWeight.w600)),
                        ),
                        for (var i = 0; i < g.itens.length; i++)
                          EntradaSuave(
                            delay: Duration(milliseconds: 60 * i),
                            child: _cartao(g.itens[i], cores),
                          ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _resumo(dynamic cores) {
    final todas = _grupos!.expand((g) => g.itens).toList();
    final feitas = todas.where((c) => c.ok).length;
    final fracao = todas.isEmpty ? 0.0 : feitas / todas.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cores.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 44),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$feitas de ${todas.length} conquistas',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: fracao,
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartao(_Conquista c, dynamic cores) {
    final ok = c.ok;
    final cor = ok ? c.cor : Colors.white30;
    final mostrarProgresso = !ok && c.meta > 1;
    final fracao = (c.atual / c.meta).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cores.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ok
              ? c.cor.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.06),
        ),
        boxShadow: ok
            ? [BoxShadow(color: c.cor.withValues(alpha: 0.18), blurRadius: 14)]
            : const [],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cor.withValues(alpha: 0.16),
            ),
            child: Icon(ok ? c.icone : Icons.lock_outline,
                color: cor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.titulo,
                    style: TextStyle(
                        color: ok ? Colors.white : Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(c.descricao,
                    style: TextStyle(
                        color: cores.textoSecundario, fontSize: 12)),
                if (mostrarProgresso) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: fracao,
                            minHeight: 6,
                            backgroundColor: Colors.white12,
                            color: c.cor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${c.atual}/${c.meta}',
                          style: TextStyle(
                              color: cores.textoSecundario, fontSize: 11)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (ok) Icon(Icons.check_circle, color: c.cor),
        ],
      ),
    );
  }
}