import 'package:flutter/material.dart';
import '../services/diario_service.dart';
import '../models/entrada_diario.dart';
import '../theme/tema.dart';
import '../widgets/animacoes.dart';
import 'pagina_diario.dart';

const List<String> _nomesMeses = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
];
const List<String> _nomesDiasSemana = [
  'Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira',
  'Quinta-feira', 'Sexta-feira', 'Sábado'
];
const List<String> _abrevDiasSemana = ['Dom.', 'Seg.', 'Ter.', 'Qua.', 'Qui.', 'Sex.', 'Sáb.'];

class PaginaCalendario extends StatefulWidget {
  /// true = usado dentro de outra tela que já rola (a tela de início):
  /// não ocupa a tela toda nem cria rolagem própria.
  final bool embutido;
  const PaginaCalendario({super.key, this.embutido = false});

  @override
  State<PaginaCalendario> createState() => _PaginaCalendarioState();
}

class _PaginaCalendarioState extends State<PaginaCalendario> {
  final DiarioService _service = DiarioService();
  late DateTime _mesAtual;
  late DateTime _diaSelecionado;

  @override
  void initState() {
    super.initState();
    final hoje = DateTime.now();
    _mesAtual = DateTime(hoje.year, hoje.month);
    _diaSelecionado = DateTime(hoje.year, hoje.month, hoje.day);
  }

  bool _mesmoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _mudarMes(int delta) {
    setState(() {
      _mesAtual = DateTime(_mesAtual.year, _mesAtual.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final accent = cores.destaque;

    final inicioGrade = _mesAtual.subtract(Duration(days: _mesAtual.weekday % 7));
    final diasNoMes = DateTime(_mesAtual.year, _mesAtual.month + 1, 0).day;
    final totalCelulas = (((_mesAtual.weekday % 7) + diasNoMes) / 7).ceil() * 7;
    final diasGrade = List.generate(
      totalCelulas,
      (i) => inicioGrade.add(Duration(days: i)),
    );

    final inicioPeriodo = inicioGrade;
    final fimPeriodo = inicioGrade.add(Duration(days: totalCelulas));

    final corpo = StreamBuilder<List<EntradaDiario>>(
        stream: _service.streamEntradasPeriodo(inicioPeriodo, fimPeriodo),
        builder: (context, snapshot) {
          final entradas = snapshot.data ?? [];
          final entradasDoDiaSelecionado =
              entradas.where((e) => _mesmoDia(e.data, _diaSelecionado)).toList();

          Set<String> diasComEntrada = entradas
              .map((e) => '${e.data.year}-${e.data.month}-${e.data.day}')
              .toSet();

          return Padding(
            padding: EdgeInsets.fromLTRB(
                widget.embutido ? 0 : 20, widget.embutido ? 0 : 20, widget.embutido ? 0 : 20, widget.embutido ? 8 : 0),
            child: Column(
              mainAxisSize: widget.embutido ? MainAxisSize.min : MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // O título troca com um fade ao mudar de mês.
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        '${_nomesMeses[_mesAtual.month - 1]} ${_mesAtual.year}',
                        key: ValueKey(_mesAtual),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _mudarMes(-1),
                          icon: const Icon(Icons.chevron_left, color: Colors.white),
                        ),
                        IconButton(
                          onPressed: () => _mudarMes(1),
                          icon: const Icon(Icons.chevron_right, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: _abrevDiasSemana
                      .map((d) => Expanded(
                            child: Center(
                              child: Text(d,
                                  style: TextStyle(
                                      color: cores.textoSecundario,
                                      fontSize: 12)),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                ...List.generate(diasGrade.length ~/ 7, (linha) {
                  return Row(
                    children: List.generate(7, (coluna) {
                      final dia = diasGrade[linha * 7 + coluna];
                      final doMesAtual = dia.month == _mesAtual.month;
                      final selecionado = _mesmoDia(dia, _diaSelecionado);
                      final temEntrada =
                          diasComEntrada.contains('${dia.year}-${dia.month}-${dia.day}');

                      Color corFundo;
                      Color corIcone;
                      IconData icone;

                      if (selecionado) {
                        corFundo = accent;
                        corIcone = Colors.white;
                        icone = Icons.add;
                      } else if (temEntrada) {
                        corFundo = accent.withValues(alpha: 0.25);
                        corIcone = accent;
                        icone = Icons.check;
                      } else {
                        corFundo = cores.card;
                        corIcone = doMesAtual ? Colors.white54 : Colors.white24;
                        icone = Icons.add;
                      }

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _diaSelecionado = dia),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              children: [
                                AnimatedScale(
                                  scale: selecionado ? 1.12 : 1.0,
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutBack,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: corFundo,
                                      shape: BoxShape.circle,
                                      boxShadow: selecionado
                                          ? [
                                              BoxShadow(
                                                color: accent.withValues(alpha: 0.5),
                                                blurRadius: 12,
                                              ),
                                            ]
                                          : const [],
                                    ),
                                    child: Icon(icone, size: 16, color: corIcone),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${dia.day}',
                                  style: TextStyle(
                                    color: doMesAtual ? Colors.white : Colors.white30,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                }),
                const SizedBox(height: 24),
                _areaDoDia(
                  EntradaSuave(
                      key: ValueKey(_diaSelecionado),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Cabeçalho do dia: 12 · Out. 2026 · Segunda-feira
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${_diaSelecionado.day}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _nomesDiasSemana[_diaSelecionado.weekday % 7],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    Text(
                                      '${_nomesMeses[_diaSelecionado.month - 1].substring(0, 3)}. ${_diaSelecionado.year}',
                                      style: TextStyle(
                                          color: cores.textoSecundario,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Ocupa a largura toda, de borda a borda.
                          if (entradasDoDiaSelecionado.isEmpty)
                            _cardCriarRegistro()
                          else
                            _listaRegistrosDoDia(entradasDoDiaSelecionado),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
    );
    return widget.embutido ? corpo : SafeArea(child: corpo);
  }

  /// Fora da tela de início, a área do dia rola sozinha; dentro dela, não.
  Widget _areaDoDia(Widget conteudo) {
    if (widget.embutido) return conteudo;
    return Expanded(child: SingleChildScrollView(child: conteudo));
  }

  Widget _cardCriarRegistro() {
    final cores = context.cores;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaginaDiario(dataSelecionada: _diaSelecionado),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          color: cores.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            const Text('Criar registro',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 14),
            Pulsar(
              intensidade: 0.07,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: cores.destaque,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: cores.destaque.withValues(alpha: 0.45),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listaRegistrosDoDia(List<EntradaDiario> entradas) {
    final cores = context.cores;

    return Column(
      children: [
        for (var i = 0; i < entradas.length; i++)
          EntradaSuave(
            delay: Duration(milliseconds: 80 * i),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cores.card,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Text(
                entradas[i].texto.length > 50
                    ? '${entradas[i].texto.substring(0, 50)}...'
                    : entradas[i].texto,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        TextButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaginaDiario(dataSelecionada: _diaSelecionado),
              ),
            );
          },
          icon: Icon(Icons.add, color: cores.destaque),
          label: Text('Adicionar outro registro',
              style: TextStyle(color: cores.destaque)),
        ),
      ],
    );
  }
}