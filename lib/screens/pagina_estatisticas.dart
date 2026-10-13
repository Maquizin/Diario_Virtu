// lib/screens/pagina_estatisticas.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/diario_service.dart';
import '../services/gerador_relatorios.dart';
import '../services/relatorio_service.dart';
import '../utils/humor_utils.dart';
import '../theme/tema.dart';
import '../widgets/animacoes.dart';
import 'tela_relatorio.dart';
import 'package:flutter/foundation.dart' show debugPrint;

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

/// Versão opaca da cor dos cartões (para janelas e folhas deslizantes).

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
    final servico = RelatorioService();

    // 1) Já existe relatório salvo deste mês? Então só abre.
    RelatorioSalvo? existente;
    try {
      existente = await servico.buscar(_mes);
    } catch (e) {
      // Sem conexão e sem cópia no aparelho: segue para a geração em
      // segundo plano, que confere de novo quando a internet voltar.
      debugPrint('RELATORIO buscar: $e');
    }
    if (!mounted) return;
    if (existente != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TelaRelatorio(relatorio: existente!)),
      );
      return;
    }

    // 2) Não existe: precisa ter registros no mês.
    final temRegistros = _registros
        .any((r) => r.data.year == _mes.year && r.data.month == _mes.month);
    if (!temRegistros) {
      _aviso('Não há registros em ${_nomeMes(_mes)} para gerar o relatório.');
      return;
    }

    // 3) Gera em segundo plano (insiste até conseguir).
    geradorRelatorios.solicitar(_mes);
    _aviso('Gerando o relatório de ${_nomeMes(_mes)}... Pode continuar usando '
        'o app: avisamos quando ficar pronto.');
  }

  void _aviso(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ----- UI -----
  @override
  Widget build(BuildContext context) {
    final seq = _sequencias();
    final contagem = _contagemHumoresDoMes();
    final cores = context.cores;

    return SafeArea(
      child: _carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                const Text('Estatísticas',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                EntradaSuave(
                  child: _CardResumo(
                    registros: _registros.length,
                    humores: _registros.where((r) => r.humorIndex != null).length,
                    fotos: _registros.where((r) => r.temFoto).length,
                  ),
                ),
                const SizedBox(height: 16),
                EntradaSuave(
                  delay: const Duration(milliseconds: 120),
                  child: _CardSequencia(
                    atual: seq.atual,
                    maior: seq.maior,
                    diasComRegistro: _dias,
                  ),
                ),
                const SizedBox(height: 16),
                EntradaSuave(
                  delay: const Duration(milliseconds: 240),
                  child: _CardHumoresMes(
                    mes: _mes,
                    contagem: contagem,
                    podeAvancar: !_mesEhAtual,
                    onAnterior: () => _mudarMes(-1),
                    onProximo: () => _mudarMes(1),
                  ),
                ),
                const SizedBox(height: 20),
                EntradaSuave(
                  delay: const Duration(milliseconds: 360),
                  child: ListenableBuilder(
                    listenable: geradorRelatorios,
                    builder: (context, _) {
                      final gerando = geradorRelatorios.emAndamento(_mes);
                      final t = geradorRelatorios
                          .tarefa(RelatorioService.idDoMes(_mes));
                      final tentando = t != null && t.tentativas > 1;
                      return SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: cores.destaque,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: gerando
                              ? () {
                                  geradorRelatorios.cancelar(
                                      RelatorioService.idDoMes(_mes));
                                  _aviso('Geração cancelada.');
                                }
                              : _gerarRelatorio,
                          icon: gerando
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(gerando
                              ? (tentando
                                  ? 'Tentando de novo... (toque p/ cancelar)'
                                  : 'Gerando... (toque p/ cancelar)')
                              : 'Gerar relatório de ${_nomeMes(_mes)}'),
                        ),
                      );
                    },
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
          NumeroAnimado(
            valor: n,
            estilo: const TextStyle(
                color: Colors.white, fontSize: 40, fontWeight: FontWeight.w600),
          ),
          Text(rotulo,
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final d = context.cores.destaque;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        // Gradiente feito a partir da cor de destaque do usuário.
        gradient: LinearGradient(
          colors: [Color.lerp(d, Colors.black, 0.4)!, d],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: d.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 8)),
        ],
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
    final cores = context.cores;
    final hoje = _soDia(DateTime.now());
    final ultimos7 = List.generate(
        7, (i) => DateTime(hoje.year, hoje.month, hoje.day - (6 - i)));

    final chama = Icon(Icons.local_fire_department,
        size: 96, color: atual > 0 ? Colors.orange : cores.destaque);

    return Container(
      decoration: BoxDecoration(
        color: cores.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // A chama "respira" quando há sequência ativa.
                    atual > 0 ? Pulsar(child: chama) : chama,
                    Padding(
                      padding: const EdgeInsets.only(top: 22),
                      child: NumeroAnimado(
                        valor: atual,
                        estilo: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold),
                      ),
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
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Toda jornada começa com um único passo',
                        style: TextStyle(color: cores.textoSecundario)),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(28)),
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
                    style: TextStyle(color: cores.textoSecundario)),
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
    final cores = context.cores;
    final Color fundo = feito
        ? cores.destaque.withValues(alpha: 0.25)
        : (ehHoje ? cores.destaque : Colors.white.withValues(alpha: 0.08));

    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(shape: BoxShape.circle, color: fundo),
          child: Icon(feito ? Icons.check : Icons.add,
              size: 18,
              color: feito
                  ? cores.destaque
                  : (ehHoje ? Colors.white : Colors.white54)),
        ),
        const SizedBox(height: 6),
        Text('${dia.day}',
            style: TextStyle(
                color: ehHoje ? cores.destaque : Colors.white,
                fontWeight: FontWeight.w600)),
        Text(rotulo,
            style: TextStyle(
                color: ehHoje ? cores.destaque : cores.textoSecundario,
                fontSize: 11)),
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
    final cores = context.cores;
    final total = contagem.fold<int>(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cores.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  onPressed: onAnterior,
                  icon: const Icon(Icons.chevron_left, color: Colors.white)),
              Text(_nomeMes(mes),
                  style: TextStyle(color: cores.destaque, fontSize: 20)),
              IconButton(
                  onPressed: podeAvancar ? onProximo : null,
                  icon: Icon(Icons.chevron_right,
                      color: podeAvancar ? Colors.white : Colors.white24)),
            ],
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 2,
            // O semicírculo "desenha" de 0 a 100% quando aparece ou o mês muda.
            child: TweenAnimationBuilder<double>(
              key: ValueKey('${mes.year}-${mes.month}'),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, progresso, __) => Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _SemicirculoPainter(
                        contagem: contagem,
                        total: total,
                        progresso: progresso,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: NumeroAnimado(
                      valor: total,
                      estilo: const TextStyle(color: Colors.white, fontSize: 40),
                    ),
                  ),
                ],
              ),
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
                    NumeroAnimado(
                      valor: contagem[i],
                      estilo: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
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
  final double progresso; // 0 a 1, para animar o desenho

  _SemicirculoPainter({
    required this.contagem,
    required this.total,
    required this.progresso,
  });

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
      pincel.color = Colors.white.withValues(alpha: 0.1);
      canvas.drawArc(rect, math.pi, math.pi, false, pincel);
      return;
    }

    var inicio = math.pi;
    for (var i = 0; i < contagem.length; i++) {
      if (contagem[i] == 0) continue;
      final varredura = math.pi * contagem[i] / total * progresso;
      pincel.color = humores[i].cor;
      canvas.drawArc(rect, inicio, varredura, false, pincel);
      inicio += varredura;
    }
  }

  @override
  bool shouldRepaint(covariant _SemicirculoPainter old) =>
      old.total != total || old.contagem != contagem || old.progresso != progresso;
}