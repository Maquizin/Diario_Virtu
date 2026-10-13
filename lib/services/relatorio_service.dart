// lib/services/relatorio_service.dart
//
// Relatórios salvos no Firestore: um documento por mês, em
//   usuarios/{uid}/relatorios/{AAAA-MM}
// Assim, "já existe relatório deste mês?" é só ler um documento.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/entrada_diario.dart';
import '../utils/humor_utils.dart';
import 'diario_service.dart';
import 'relatorio_ia_service.dart';

const _nomesMeses = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

String nomeDoMes(int mes) => _nomesMeses[mes - 1];

String dataHoraCurta(DateTime d) {
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${dois(d.day)}/${dois(d.month)}/${d.year} às ${dois(d.hour)}:${dois(d.minute)}';
}

// ---------------------------------------------------------------------------
// Estatísticas do mês (guardadas junto com o relatório)
// ---------------------------------------------------------------------------
class EstatisticasMes {
  final int totalRegistros;
  final int diasComRegistro;
  final int diasNoMes;
  final int maiorSequencia;
  final int fotos;
  final List<int> contagemHumores; // 5 níveis, do pior ao melhor
  final double humorMedio; // 0.0 a 1.0

  const EstatisticasMes({
    required this.totalRegistros,
    required this.diasComRegistro,
    required this.diasNoMes,
    required this.maiorSequencia,
    required this.fotos,
    required this.contagemHumores,
    required this.humorMedio,
  });

  factory EstatisticasMes.calcular(List<EntradaDiario> entradas, DateTime mes) {
    final dias = entradas
        .map((e) => DateTime(e.data.year, e.data.month, e.data.day))
        .toSet()
        .toList()
      ..sort();

    var maior = dias.isEmpty ? 0 : 1;
    var corrente = 1;
    for (var i = 1; i < dias.length; i++) {
      final anterior = dias[i - 1];
      final esperado = DateTime(anterior.year, anterior.month, anterior.day + 1);
      corrente = dias[i] == esperado ? corrente + 1 : 1;
      if (corrente > maior) maior = corrente;
    }

    final contagem = List<int>.filled(5, 0);
    var soma = 0.0;
    for (final e in entradas) {
      final idx = (e.humor * 4).round().clamp(0, 4).toInt();
      contagem[idx]++;
      soma += e.humor;
    }

    return EstatisticasMes(
      totalRegistros: entradas.length,
      diasComRegistro: dias.length,
      diasNoMes: DateTime(mes.year, mes.month + 1, 0).day,
      maiorSequencia: maior,
      fotos: entradas.where((e) => e.imagemUrl != null).length,
      contagemHumores: contagem,
      humorMedio: entradas.isEmpty ? 0.5 : soma / entradas.length,
    );
  }

  Map<String, dynamic> toMap() => {
        'totalRegistros': totalRegistros,
        'diasComRegistro': diasComRegistro,
        'diasNoMes': diasNoMes,
        'maiorSequencia': maiorSequencia,
        'fotos': fotos,
        'contagemHumores': contagemHumores,
        'humorMedio': humorMedio,
      };

  factory EstatisticasMes.fromMap(Map<String, dynamic> m) {
    int n(String k) => (m[k] as num?)?.toInt() ?? 0;
    return EstatisticasMes(
      totalRegistros: n('totalRegistros'),
      diasComRegistro: n('diasComRegistro'),
      diasNoMes: n('diasNoMes'),
      maiorSequencia: n('maiorSequencia'),
      fotos: n('fotos'),
      contagemHumores: (m['contagemHumores'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          List<int>.filled(5, 0),
      humorMedio: (m['humorMedio'] as num?)?.toDouble() ?? 0.5,
    );
  }
}

// ---------------------------------------------------------------------------
// Relatório salvo
// ---------------------------------------------------------------------------
class RelatorioSalvo {
  final String id; // 'AAAA-MM'
  final int ano;
  final int mes;
  final DateTime criadoEm;
  final RelatorioIA analise;
  final EstatisticasMes stats;

  const RelatorioSalvo({
    required this.id,
    required this.ano,
    required this.mes,
    required this.criadoEm,
    required this.analise,
    required this.stats,
  });

  DateTime get mesData => DateTime(ano, mes);
  String get titulo => '${nomeDoMes(mes)} $ano';

  Map<String, dynamic> toMap() => {
        'ano': ano,
        'mes': mes,
        'criadoEm': Timestamp.fromDate(criadoEm),
        // Mesmas chaves que RelatorioIA.fromJson lê.
        'analise': {
          'resumo_geral': analise.resumoGeral,
          'temas_recorrentes': analise.temasRecorrentes,
          'pontos_de_atencao': analise.pontosDeAtencao,
          'variacao_do_humor': analise.variacaoDoHumor,
          'observacoes_para_o_medico': analise.observacoesParaOMedico,
        },
        'stats': stats.toMap(),
      };

  factory RelatorioSalvo.fromMap(String id, Map<String, dynamic> m) {
    final ts = m['criadoEm'];
    return RelatorioSalvo(
      id: id,
      ano: (m['ano'] as num).toInt(),
      mes: (m['mes'] as num).toInt(),
      criadoEm: ts is Timestamp ? ts.toDate() : DateTime.now(),
      analise: RelatorioIA.fromJson(Map<String, dynamic>.from(m['analise'] as Map)),
      stats: EstatisticasMes.fromMap(Map<String, dynamic>.from(m['stats'] as Map)),
    );
  }
}

// ---------------------------------------------------------------------------
// Serviço
// ---------------------------------------------------------------------------
/// Não há nada para analisar neste mês (não adianta tentar de novo).
class SemRegistrosException implements Exception {
  final String mensagem;
  const SemRegistrosException([
    this.mensagem = 'Não há registros neste mês para gerar o relatório.',
  ]);
  @override
  String toString() => mensagem;
}

/// O usuário cancelou a geração enquanto a IA ainda trabalhava.
class GeracaoCancelada implements Exception {
  const GeracaoCancelada();
}

class RelatorioService {
  final DiarioService _diario = DiarioService();

  CollectionReference<Map<String, dynamic>> get _col {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Você precisa estar logado.');
    // Mesmo banco do diário (o DiarioService usa um banco com nome próprio,
    // não o "(default)"). Usar outro aqui causava "client is offline".
    return _diario.firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('relatorios');
  }

  static String idDoMes(DateTime mes) =>
      '${mes.year}-${mes.month.toString().padLeft(2, '0')}';

  /// Devolve o relatório salvo do mês, ou null se ainda não existir.
  ///
  /// Sem internet, usa a cópia guardada no aparelho (se houver). Se não
  /// houver cópia e não der para falar com o servidor, lança a exceção
  /// (assim não confundimos "sem internet" com "não existe relatório").
  /// Com [soServidor] = true nunca usa a cópia local.
  Future<RelatorioSalvo?> buscar(DateTime mes, {bool soServidor = false}) async {
    final ref = _col.doc(idDoMes(mes));
    DocumentSnapshot<Map<String, dynamic>> doc;
    try {
      doc = await ref.get();
    } on FirebaseException catch (e) {
      if (e.code != 'unavailable' || soServidor) rethrow;
      doc = await ref.get(const GetOptions(source: Source.cache));
    }
    if (!doc.exists || doc.data() == null) return null;
    return RelatorioSalvo.fromMap(doc.id, doc.data()!);
  }

  /// Todos os relatórios do usuário, do mais recente para o mais antigo.
  Stream<List<RelatorioSalvo>> listar() {
    // Sem orderBy no Firestore (exigiria um índice): ordena aqui mesmo.
    return _col.snapshots().map((snap) {
      final lista = snap.docs
          .map((d) => RelatorioSalvo.fromMap(d.id, d.data()))
          .toList()
        ..sort((a, b) => b.id.compareTo(a.id));
      return lista;
    });
  }

  /// Abre o relatório salvo; se não existir, gera com a IA e salva.
  Future<RelatorioSalvo> obterOuGerar(DateTime mes) async {
    final existente = await buscar(mes);
    if (existente != null) return existente;
    return gerarESalvar(mes);
  }

  /// Gera (ou refaz) o relatório do mês com a IA e salva por cima do anterior.
  Future<RelatorioSalvo> gerarESalvar(DateTime mes,
      {bool Function()? cancelado}) async {
    final inicio = DateTime(mes.year, mes.month);
    final fim = DateTime(mes.year, mes.month + 1);
    final entradas = await _diario.buscarEntradasPeriodo(inicio, fim);

    if (entradas.isEmpty) {
      throw const SemRegistrosException();
    }

    final registros = entradas.map((e) {
      final texto = e.titulo.isNotEmpty ? '${e.titulo}\n${e.texto}' : e.texto;
      return RegistroParaRelatorio(
        data: e.data,
        humor: rotuloHumor(e.humor),
        texto: texto,
        // Quando Foto e Voz estiverem prontas (Firebase Storage), baixe os
        // bytes aqui e preencha imagens/audios.
      );
    }).toList();

    final analise =
        await RelatorioIAService().gerar(mes: inicio, registros: registros);

    // Se o usuário cancelou enquanto a IA pensava, não salva nada.
    if (cancelado?.call() == true) throw const GeracaoCancelada();

    final salvo = RelatorioSalvo(
      id: idDoMes(inicio),
      ano: inicio.year,
      mes: inicio.month,
      criadoEm: DateTime.now(),
      analise: analise,
      stats: EstatisticasMes.calcular(entradas, inicio),
    );

    await _col.doc(salvo.id).set(salvo.toMap());
    return salvo;
  }

  Future<void> excluir(String id) => _col.doc(id).delete();
}