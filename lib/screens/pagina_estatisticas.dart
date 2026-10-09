// lib/screens/pagina_estatisticas.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/diario_service.dart';
import '../services/relatorio_ia_service.dart';
import '../utils/humor_utils.dart';
import 'package:flutter/foundation.dart' show debugPrint;

// Cores do app (tema escuro, destaque roxo)
const _fundoCard = Color(0xFF1C1C1E);
const _roxo = Color(0xFF7C4DFF);
const _roxoEscuro = Color(0xFF2A1F5C);

// ---------------------------------------------------------------------------
// MODELOS SIMPLES DESTA TELA
// ---------------------------------------------------------------------------
class Humor {
  final String nome;
  final Color cor;
  final IconData icone;
  const Humor(this.nome, this.cor, this.icone);
}

// 5 níveis de humor, os mesmos do Diário e do Histórico
final humores = List<Humor>.generate(5, (i) {
  final valor = i / 4; // 0.0, 0.25, 0.5, 0.75, 1.0
  return Humor(rotuloHumor(valor), corDoHumor(valor), iconeHumor(valor));
});

int _indiceHumor(double humor) => (humor * 4).round().clamp(0, 4).toInt();

class RegistroResumo {
  final DateTime data;
  final int? humorIndex; // posição na lista [humores]
  final bool temFoto;
  const RegistroResumo({required this.data, this.humorIndex, this.temFoto = false});
}

DateTime _soDia(DateTime d) => DateTime(d.year, d.month, d.day);

// ---------------------------------------------------------------------------
// PÁGINA
// ---------------------------------------------------------------------------
class PaginaEstatisticas extends StatefulWidget {
  const PaginaEstatisticas({super.key});

  @override
  State<PaginaEstatisticas> createState() => _PaginaEstatisticasState();
}

class _PaginaEstatisticasState extends State<PaginaEstatisticas> {
  final DiarioService _diarioService = DiarioService();

  List<RegistroResumo> _registros = [];
  bool _carregando = true;
  DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<List<RegistroResumo>> _carregarRegistros() async {
    final entradas = await _diarioService.buscarTodasEntradas();
    return entradas
        .map((e) => RegistroResumo(
              data: e.data,
              humorIndex: _indiceHumor(e.humor),
              temFoto: e.imagemUrl != null,
            ))
        .toList();
  }

  Future<List<RegistroParaRelatorio>> _carregarRegistrosParaRelatorio(
      DateTime mes) async {
    final inicio = DateTime(mes.year, mes.month);
    final fim = DateTime(mes.year, mes.month + 1);
    final entradas = await _diarioService.buscarEntradasPeriodo(inicio, fim);

    return entradas.map((e) {
      final texto = e.titulo.isNotEmpty ? '${e.titulo}\n${e.texto}' : e.texto;
      return RegistroParaRelatorio(
        data: e.data,
        humor: rotuloHumor(e.humor),
        texto: texto,
        // Quando Foto e Voz estiverem prontas (Firebase Storage), baixe os
        // bytes aqui e preencha imagens/audios.
      );
    }).toList();
  }

  Future<void> _carregar() async {
    List<RegistroResumo> lista = [];
    try {
      lista = await _carregarRegistros();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _registros = lista;
      _carregando = false;
    });
  }

  // ----- cálculos -----
  Set<DateTime> get _dias => _registros.map((r) => _soDia(r.data)).toSet();

  ({int atual, int maior}) _sequencias() {
    final dias = _dias;
    if (dias.isEmpty) return (atual: 0, maior: 0);

    // maior sequência
    final ordenados = dias.toList()..sort();
    var maior = 1, corrente = 1;
    for (var i = 1; i < ordenados.length; i++) {
      final anterior = ordenados[i - 1];
      final esperado = DateTime(anterior.year, anterior.month, anterior.day + 1);
      corrente = ordenados[i] == esperado ? corrente + 1 : 1;
      if (corrente > maior) maior = corrente;
    }

    // sequência atual (termina hoje; se hoje ainda não tem registro, termina ontem)
    final hoje = _soDia(DateTime.now());
    var cursor = dias.contains(hoje)
        ? hoje
        : DateTime(hoje.year, hoje.month, hoje.day - 1);
    var atual = 0;
    while (dias.contains(cursor)) {
      atual++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return (atual: atual, maior: maior);
  }

  List<int> _contagemHumoresDoMes() {
    final contagem = List<int>.filled(humores.length, 0);
    for (final r in _registros) {
      if (r.data.year == _mes.year &&
          r.data.month == _mes.month &&
          r.humorIndex != null &&
          r.humorIndex! >= 0 &&
          r.humorIndex! < humores.length) {
        contagem[r.humorIndex!]++;
      }
    }
    return contagem;
  }

  void _mudarMes(int delta) {
    setState(() => _mes = DateTime(_mes.year, _mes.month + delta));
  }

  bool get _mesEhAtual {
    final agora = DateTime.now();
    return _mes.year == agora.year && _mes.month == agora.month;
  }

  // ----- relatório -----
  Future<void> _gerarRelatorio() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    RelatorioIA? analise;
    String? erro;
    try {
      final registros = await _carregarRegistrosParaRelatorio(_mes);
      debugPrint('RELATORIO IA: ${registros.length} registros enviados');
      analise = await RelatorioIAService().gerar(mes: _mes, registros: registros);
    } on StateError catch (e) {
      erro = e.message;
    } catch (e, stack) {
      erro = '${e.runtimeType}\n\n$e';
      debugPrint('RELATORIO IA ERRO: $e\n$stack');
    }

    if (!mounted) return;
    Navigator.of(context).pop(); // fecha o carregando

    if (erro != null) {
      _mostrarErro(erro);
      return;
    }

    _mostrarAnalise(analise!);
  }

  void _mostrarErro(String erro) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _fundoCard,
        title: const Text('Não foi possível gerar',
            style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: SelectableText(
            erro,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
  void _mostrarAnalise(RelatorioIA a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _fundoCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (context, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(24),
          children: [
            Text('Análise de ${_nomeMes(_mes)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _secao('Resumo geral', a.resumoGeral),
            _secaoLista('Temas recorrentes', a.temasRecorrentes),
            _secaoLista('Pontos de atenção', a.pontosDeAtencao),
            _secao('Variação do humor', a.variacaoDoHumor),
            _secao('Observações para o médico', a.observacoesParaOMedico),
            const Text(
              'Resumo gerado por IA a partir dos seus registros. Não é diagnóstico e não substitui avaliação profissional.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _secao(String titulo, String texto) {
    if (texto.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: const TextStyle(
                  color: _roxo, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(texto, style: const TextStyle(color: Colors.white, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _secaoLista(String titulo, List<String> itens) {
    if (itens.isEmpty) return const SizedBox.shrink();
    return _secao(titulo, itens.map((i) => '• $i').join('\n'));
  }

  // ----- UI -----
  @override
  Widget build(BuildContext context) {
    final seq = _sequencias();
    final contagem = _contagemHumoresDoMes();

    return SafeArea(
      child: _carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              children: [
                const Text('Estatísticas',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _CardResumo(
                  registros: _registros.length,
                  humores: _registros.where((r) => r.humorIndex != null).length,
                  fotos: _registros.where((r) => r.temFoto).length,
                ),
                const SizedBox(height: 16),
                _CardSequencia(
                  atual: seq.atual,
                  maior: seq.maior,
                  diasComRegistro: _dias,
                ),
                const SizedBox(height: 16),
                _CardHumoresMes(
                  mes: _mes,
                  contagem: contagem,
                  podeAvancar: !_mesEhAtual,
                  onAnterior: () => _mudarMes(-1),
                  onProximo: () => _mudarMes(1),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _roxo,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _gerarRelatorio,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text('Gerar relatório de ${_nomeMes(_mes)}'),
                  ),
                ),
              ],
            ),
    );
  }
}

const _meses = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

String _nomeMes(DateTime d) => '${_meses[d.month - 1]} ${d.year}';

// ---------------------------------------------------------------------------
// CARD 1: Registros / Humores / Fotos
// ---------------------------------------------------------------------------
class _CardResumo extends StatelessWidget {
  final int registros, humores, fotos;
  const _CardResumo(
      {required this.registros, required this.humores, required this.fotos});

  Widget _item(int n, String rotulo) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$n',
              style: const TextStyle(
                  color: Colors.white, fontSize: 40, fontWeight: FontWeight.w600)),
          Text(rotulo,
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF5B3FD9), Color(0xFF8E6BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _item(registros, 'Registros'),
          _item(humores, 'Humores'),
          _item(fotos, 'Fotos'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CARD 2: Sequência
// ---------------------------------------------------------------------------
class _CardSequencia extends StatelessWidget {
  final int atual, maior;
  final Set<DateTime> diasComRegistro;
  const _CardSequencia(
      {required this.atual, required this.maior, required this.diasComRegistro});

  static const _abrev = ['Seg.', 'Ter.', 'Qua.', 'Qui.', 'Sex.', 'Sáb.', 'Dom.'];

  @override
  Widget build(BuildContext context) {
    final hoje = _soDia(DateTime.now());
    final ultimos7 = List.generate(
        7, (i) => DateTime(hoje.year, hoje.month, hoje.day - (6 - i)));

    return Container(
      decoration: BoxDecoration(
          color: _fundoCard, borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.local_fire_department,
                        size: 96,
                        color: atual > 0 ? Colors.orange : _roxo),
                    Padding(
                      padding: const EdgeInsets.only(top: 22),
                      child: Text('$atual',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  atual == 0
                      ? 'Comece sua sequência hoje'
                      : (atual == 1 ? '1 dia seguido' : '$atual dias seguidos'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                if (atual == 0)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('Toda jornada começa com um único passo',
                        style: TextStyle(color: Colors.grey)),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF141416),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final dia in ultimos7)
                      _DiaDaSemana(
                        dia: dia,
                        rotulo: _abrev[dia.weekday - 1],
                        feito: diasComRegistro.contains(dia),
                        ehHoje: dia == hoje,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('Sequência mais longa: $maior 🔥',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaDaSemana extends StatelessWidget {
  final DateTime dia;
  final String rotulo;
  final bool feito, ehHoje;
  const _DiaDaSemana(
      {required this.dia,
      required this.rotulo,
      required this.feito,
      required this.ehHoje});

  @override
  Widget build(BuildContext context) {
    final Color fundo = feito
        ? _roxoEscuro
        : (ehHoje ? _roxo : const Color(0xFF232326));
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(shape: BoxShape.circle, color: fundo),
          child: Icon(feito ? Icons.check : Icons.add,
              size: 18, color: feito ? _roxo : Colors.white54),
        ),
        const SizedBox(height: 6),
        Text('${dia.day}',
            style: TextStyle(
                color: ehHoje ? _roxo : Colors.white,
                fontWeight: FontWeight.w600)),
        Text(rotulo,
            style: TextStyle(
                color: ehHoje ? _roxo : Colors.grey, fontSize: 11)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// CARD 3: Humores do mês
// ---------------------------------------------------------------------------
class _CardHumoresMes extends StatelessWidget {
  final DateTime mes;
  final List<int> contagem;
  final bool podeAvancar;
  final VoidCallback onAnterior, onProximo;

  const _CardHumoresMes({
    required this.mes,
    required this.contagem,
    required this.podeAvancar,
    required this.onAnterior,
    required this.onProximo,
  });

  @override
  Widget build(BuildContext context) {
    final total = contagem.fold<int>(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: _fundoCard, borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  onPressed: onAnterior,
                  icon: const Icon(Icons.chevron_left, color: Colors.white)),
              Text(_nomeMes(mes),
                  style: const TextStyle(color: _roxo, fontSize: 20)),
              IconButton(
                  onPressed: podeAvancar ? onProximo : null,
                  icon: Icon(Icons.chevron_right,
                      color: podeAvancar ? Colors.white : Colors.white24)),
            ],
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 2,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                      painter: _SemicirculoPainter(contagem: contagem, total: total)),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('$total',
                      style: const TextStyle(color: Colors.white, fontSize: 40)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < humores.length; i++)
                Column(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: humores[i].cor,
                      child: Icon(humores[i].icone, color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    Text('${contagem[i]}',
                        style: const TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SemicirculoPainter extends CustomPainter {
  final List<int> contagem;
  final int total;
  _SemicirculoPainter({required this.contagem, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final espessura = size.width * 0.13;
    final raio = size.width / 2 - espessura / 2;
    final centro = Offset(size.width / 2, size.height);
    final rect = Rect.fromCircle(center: centro, radius: raio);

    final pincel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = espessura
      ..strokeCap = StrokeCap.butt;

    if (total == 0) {
      pincel.color = const Color(0xFF2C2C2E);
      canvas.drawArc(rect, math.pi, math.pi, false, pincel);
      return;
    }

    var inicio = math.pi;
    for (var i = 0; i < contagem.length; i++) {
      if (contagem[i] == 0) continue;
      final varredura = math.pi * contagem[i] / total;
      pincel.color = humores[i].cor;
      canvas.drawArc(rect, inicio, varredura, false, pincel);
      inicio += varredura;
    }
  }

  @override
  bool shouldRepaint(covariant _SemicirculoPainter old) =>
      old.total != total || old.contagem != contagem;
}