// lib/services/gerador_relatorios.dart
//
// Gera relatórios em SEGUNDO PLANO e insiste até conseguir.
//
// - O usuário pede o relatório e pode sair da tela: a geração continua.
// - Se a IA estiver sobrecarregada (erro 503/429) ou sem internet, tenta de
//   novo sozinho, esperando cada vez um pouco mais (5s, 15s, 30s, 1min, 2min, 5min).
// - A fila fica salva no aparelho: se o app for fechado, retoma ao abrir.
// - Quando termina, aparece um aviso com o botão "Abrir".
//
// Limite: tudo isso roda DENTRO do app. Com o app totalmente fechado nada
// roda (isso exigiria uma Cloud Function, que precisa do plano Blaze).

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/tela_relatorio.dart';
import 'notificacoes.dart';
import 'relatorio_service.dart';

/// Chaves globais (ligadas no MaterialApp, em main.dart) para mostrar avisos
/// e abrir telas de qualquer lugar.
final navigatorKey = GlobalKey<NavigatorState>();
final mensagensKey = GlobalKey<ScaffoldMessengerState>();

enum EstadoTarefa { tentando, aguardando, falhou }

class TarefaRelatorio {
  final DateTime mes;

  /// true = "Refazer": ignora o relatório salvo e gera outro por cima.
  final bool refazer;

  EstadoTarefa estado = EstadoTarefa.tentando;
  int tentativas = 0;
  String? ultimoErro;
  DateTime? proximaTentativa;
  bool cancelada = false;

  TarefaRelatorio(this.mes, {this.refazer = false});

  String get id => RelatorioService.idDoMes(mes);
  String get titulo => '${nomeDoMes(mes.month)} ${mes.year}';
}

class GeradorRelatorios extends ChangeNotifier {
  static const _atrasosSeg = [5, 15, 30, 60, 120, 300];
  static const _maxTentativas = 12; // ~40 min de insistência

  final _servico = RelatorioService();
  final _tarefas = <String, TarefaRelatorio>{};
  StreamSubscription<User?>? _sub;
  String? _uid;

  List<TarefaRelatorio> get tarefas =>
      (_tarefas.values.toList()..sort((a, b) => b.id.compareTo(a.id)));

  TarefaRelatorio? tarefa(String id) => _tarefas[id];

  /// Já há uma geração em curso (ou esperando para tentar de novo) deste mês?
  bool emAndamento(DateTime mes) {
    final t = _tarefas[RelatorioService.idDoMes(mes)];
    return t != null && t.estado != EstadoTarefa.falhou;
  }

  // ---------------------------------------------------------------- início
  /// Chame uma vez no main(), depois do Firebase.initializeApp().
  void iniciar() {
    // Notificações do sistema; tocar em uma abre o relatório.
    notificacoes.aoTocar = _abrirDaNotificacao;
    notificacoes.iniciar();

    _sub?.cancel();
    _sub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      for (final t in _tarefas.values) {
        t.cancelada = true;
      }
      _tarefas.clear();
      _uid = user?.uid;
      notifyListeners();
      if (user == null) return;

      // Retoma o que ficou pendente na última vez que o app foi usado.
      try {
        final prefs = await SharedPreferences.getInstance();
        if (_uid != user.uid) return;
        for (final item in prefs.getStringList(_chave(user.uid)) ?? const []) {
          final partes = item.split('|');
          final ym = partes[0].split('-');
          if (ym.length != 2) continue;
          final ano = int.tryParse(ym[0]);
          final mes = int.tryParse(ym[1]);
          if (ano == null || mes == null) continue;
          _iniciar(TarefaRelatorio(
            DateTime(ano, mes),
            refazer: partes.length > 1 && partes[1] == 'r',
          ));
        }
      } catch (e) {
        debugPrint('GERADOR: não consegui ler a fila salva: $e');
      }
    });
  }

  // ---------------------------------------------------------------- pedidos
  /// Pede a geração do relatório do mês (ou refazer). Volta na hora.
  void solicitar(DateTime mes, {bool refazer = false}) {
    notificacoes.pedirPermissao(); // só pergunta na primeira vez
    final id = RelatorioService.idDoMes(mes);
    final atual = _tarefas[id];
    if (atual != null && atual.estado != EstadoTarefa.falhou) return;
    atual?.cancelada = true;
    _iniciar(TarefaRelatorio(DateTime(mes.year, mes.month), refazer: refazer));
  }

  void cancelar(String id) {
    final t = _tarefas.remove(id);
    if (t == null) return;
    t.cancelada = true;
    _salvarFila();
    notifyListeners();
  }

  void _iniciar(TarefaRelatorio t) {
    _tarefas[t.id] = t;
    _salvarFila();
    notifyListeners();
    _rodar(t);
  }

  // ---------------------------------------------------------------- laço
  Future<void> _rodar(TarefaRelatorio t) async {
    while (!t.cancelada) {
      t.estado = EstadoTarefa.tentando;
      t.proximaTentativa = null;
      t.tentativas++;
      notifyListeners();

      try {
        RelatorioSalvo? pronto;
        if (!t.refazer) {
          // Pode já ter sido gerado (ex.: em outra tentativa ou aparelho).
          pronto = await _servico.buscar(t.mes, soServidor: true);
        }
        // Se a IA "travar", em 3 minutos a tentativa é abandonada e refeita.
        pronto ??= await _servico
            .gerarESalvar(t.mes, cancelado: () => t.cancelada)
            .timeout(const Duration(minutes: 3));

        if (t.cancelada) return;
        _finalizar(t);
        _avisarPronto(pronto);
        return;
      } on SemRegistrosException catch (e) {
        if (t.cancelada) return;
        _finalizar(t);
        _avisar(e.mensagem);
        return;
      } catch (e, stack) {
        debugPrint('GERADOR (${t.id}, tentativa ${t.tentativas}): $e\n$stack');
        if (t.cancelada) return;
        t.ultimoErro = '$e';

        if (_permanente(e) || t.tentativas >= _maxTentativas) {
          t.estado = EstadoTarefa.falhou;
          _salvarFila();
          notifyListeners();
          _avisar('Não consegui gerar o relatório de ${t.titulo}. '
              'Veja em Configurações › Meus relatórios.');
          return;
        }

        final seg = _atrasosSeg[(t.tentativas - 1).clamp(0, _atrasosSeg.length - 1)];
        t.estado = EstadoTarefa.aguardando;
        t.proximaTentativa = DateTime.now().add(Duration(seconds: seg));
        notifyListeners();
        await Future.delayed(Duration(seconds: seg));
      }
    }
  }

  /// Erros em que insistir não adianta (chave inválida, modelo removido,
  /// sem permissão no Firestore).
  bool _permanente(Object e) {
    if (e is FirebaseException) return e.code == 'permission-denied';
    final s = '$e'.toLowerCase();
    return s.contains('api key') ||
        s.contains('api_key') ||
        RegExp(r'\b(401|403|404)\b').hasMatch(s);
  }

  void _finalizar(TarefaRelatorio t) {
    if (identical(_tarefas[t.id], t)) _tarefas.remove(t.id);
    _salvarFila();
    notifyListeners();
  }

  // ---------------------------------------------------------------- fila salva
  String _chave(String uid) => 'relatorios_pendentes_$uid';

  Future<void> _salvarFila() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _chave(uid),
        _tarefas.values
            .where((t) => t.estado != EstadoTarefa.falhou)
            .map((t) => '${t.id}|${t.refazer ? 'r' : 'n'}')
            .toList(),
      );
    } catch (_) {}
  }

  // ---------------------------------------------------------------- avisos
  void _avisar(String msg) {
    mensagensKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _avisarPronto(RelatorioSalvo r) {
    final emSegundoPlano = WidgetsBinding.instance.lifecycleState !=
        AppLifecycleState.resumed;
    if (emSegundoPlano) {
      notificacoes.relatorioPronto(titulo: r.titulo, payload: r.id);
    }
    mensagensKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Relatório de ${r.titulo} pronto!'),
          duration: const Duration(seconds: 12),
          action: SnackBarAction(
            label: 'Abrir',
            onPressed: () => _abrir(r),
          ),
        ),
      );
  }

  void _abrir(RelatorioSalvo r) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => TelaRelatorio(relatorio: r)),
    );
  }

  Future<void> _abrirDaNotificacao(String id) async {
    final p = id.split('-');
    if (p.length != 2) return;
    final ano = int.tryParse(p[0]), mes = int.tryParse(p[1]);
    if (ano == null || mes == null) return;
    try {
      final r = await _servico.buscar(DateTime(ano, mes));
      if (r != null) _abrir(r);
    } catch (_) {}
  }
}

final geradorRelatorios = GeradorRelatorios();