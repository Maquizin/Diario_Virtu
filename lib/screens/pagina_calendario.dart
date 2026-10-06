import 'package:flutter/material.dart';
import '../services/diario_service.dart';
import '../models/entrada_diario.dart';
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
const Color _corAccent = Colors.deepPurpleAccent;

class PaginaCalendario extends StatefulWidget {
  const PaginaCalendario({super.key});

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
    final inicioGrade = _mesAtual.subtract(Duration(days: _mesAtual.weekday % 7));
    final diasNoMes = DateTime(_mesAtual.year, _mesAtual.month + 1, 0).day;
    final totalCelulas = (((_mesAtual.weekday % 7) + diasNoMes) / 7).ceil() * 7;
    final diasGrade = List.generate(
      totalCelulas,
      (i) => inicioGrade.add(Duration(days: i)),
    );

    final inicioPeriodo = inicioGrade;
    final fimPeriodo = inicioGrade.add(Duration(days: totalCelulas));

    return SafeArea(
      child: StreamBuilder<List<EntradaDiario>>(
        stream: _service.streamEntradasPeriodo(inicioPeriodo, fimPeriodo),
        builder: (context, snapshot) {
          final entradas = snapshot.data ?? [];
          final entradasDoDiaSelecionado =
              entradas.where((e) => _mesmoDia(e.data, _diaSelecionado)).toList();

          Set<String> diasComEntrada = entradas
              .map((e) => '${e.data.year}-${e.data.month}-${e.data.day}')
              .toSet();

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_nomesMeses[_mesAtual.month - 1]} ${_mesAtual.year}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
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
                              child: Text(d, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
                        corFundo = _corAccent;
                        corIcone = Colors.white;
                        icone = Icons.add;
                      } else if (temEntrada) {
                        corFundo = _corAccent.withOpacity(0.25);
                        corIcone = _corAccent;
                        icone = Icons.check;
                      } else {
                        corFundo = const Color(0xFF1C1C1E);
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
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(color: corFundo, shape: BoxShape.circle),
                                  child: Icon(icone, size: 16, color: corIcone),
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
                Expanded(
                  child: SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_diaSelecionado.day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_nomesMeses[_diaSelecionado.month - 1].substring(0, 3)}. ${_diaSelecionado.year}',
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
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
                              const SizedBox(height: 12),
                              if (entradasDoDiaSelecionado.isEmpty)
                                _cardCriarRegistro()
                              else
                                _listaRegistrosDoDia(entradasDoDiaSelecionado),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cardCriarRegistro() {
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
        padding: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Text('Criar registro', style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 14),
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.add, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listaRegistrosDoDia(List<EntradaDiario> entradas) {
    return Column(
      children: [
        ...entradas.map((e) {
          final preview = e.texto.length > 50 ? '${e.texto.substring(0, 50)}...' : e.texto;
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(preview, style: const TextStyle(color: Colors.white, fontSize: 14)),
          );
        }),
        TextButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaginaDiario(dataSelecionada: _diaSelecionado),
              ),
            );
          },
          icon: const Icon(Icons.add, color: Colors.deepPurpleAccent),
          label: const Text('Adicionar outro registro', style: TextStyle(color: Colors.deepPurpleAccent)),
        ),
      ],
    );
  }
}