// lib/screens/pagina_historico.dart
//
// Histórico: registros agrupados por mês, cada cartão com a cor do humor,
// busca por texto, filtro por humor e por favoritos, favoritar e excluir.

import 'package:flutter/material.dart';

import '../models/entrada_diario.dart';
import '../theme/tema.dart';
import '../utils/humor_utils.dart';
import '../widgets/animacoes.dart';
import '../services/diario_service.dart';
import 'pagina_diario.dart';

const List<String> _meses = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
];
const List<String> _diasAbrev = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

int _nivel(double humor) => (humor * 4).round().clamp(0, 4).toInt();

bool _ehFavorito(EntradaDiario e) {
  try {
    return (e as dynamic).favorito == true;
  } catch (_) {
    return false;
  }
}

class PaginaHistorico extends StatefulWidget {
  const PaginaHistorico({super.key});

  @override
  State<PaginaHistorico> createState() => _PaginaHistoricoState();
}

class _PaginaHistoricoState extends State<PaginaHistorico> {
  late final Stream<List<EntradaDiario>> _stream =
      DiarioService().streamEntradas();
  final _busca = TextEditingController();

  String _consulta = '';
  int? _filtroHumor; // 0..4
  bool _soFavoritos = false;
  final Set<String> _fechados = {}; // meses recolhidos ("2026-10")

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- dados
  List<EntradaDiario> _filtrar(List<EntradaDiario> todas) {
    final q = _consulta.trim().toLowerCase();
    final lista = todas.where((e) {
      if (_soFavoritos && !_ehFavorito(e)) return false;
      if (_filtroHumor != null && _nivel(e.humor) != _filtroHumor) return false;
      if (q.isNotEmpty &&
          !('${e.titulo} ${e.texto}'.toLowerCase().contains(q))) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.data.compareTo(a.data));
    return lista;
  }

  String _chaveMes(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------- ações
  Future<bool> _confirmarExclusao() async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir este registro?'),
        content: const Text('Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    return r == true;
  }

  void _abrir(EntradaDiario e) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaginaDiario(entradaExistente: e)),
    );
  }

  // ---------------------------------------------------------------- tela
  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return SafeArea(
      child: StreamBuilder<List<EntradaDiario>>(
        stream: _stream,
        builder: (context, snap) {
          final todas = snap.data ?? const <EntradaDiario>[];
          final lista = _filtrar(todas);
          final carregando =
              snap.connectionState == ConnectionState.waiting && !snap.hasData;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Histórico',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        '${todas.length} ${todas.length == 1 ? 'registro' : 'registros'}',
                        style: TextStyle(
                            color: cores.textoSecundario, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _campoBusca(cores),
              const SizedBox(height: 10),
              _filtros(cores),
              const SizedBox(height: 6),
              Expanded(
                child: carregando
                    ? const Center(child: CircularProgressIndicator())
                    : lista.isEmpty
                        ? _vazio(cores, temRegistros: todas.isNotEmpty)
                        : _listaAgrupada(lista, cores),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _campoBusca(dynamic cores) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _busca,
        onChanged: (v) => setState(() => _consulta = v),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Buscar nos registros',
          hintStyle: TextStyle(color: cores.textoSecundario),
          prefixIcon: Icon(Icons.search, color: cores.textoSecundario),
          suffixIcon: _consulta.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _busca.clear();
                    setState(() => _consulta = '');
                  },
                ),
          filled: true,
          fillColor: cores.card,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _filtros(dynamic cores) {
    Widget chip({
      required bool ativo,
      required VoidCallback aoTocar,
      required Widget filho,
      Color? cor,
    }) {
      final c = cor ?? context.cores.destaque;
      return GestureDetector(
        onTap: aoTocar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: ativo ? c.withValues(alpha: 0.25) : cores.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ativo ? c : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: filho,
        ),
      );
    }

    final nenhum = _filtroHumor == null && !_soFavoritos;

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          chip(
            ativo: nenhum,
            aoTocar: () => setState(() {
              _filtroHumor = null;
              _soFavoritos = false;
            }),
            filho: const Text('Todos',
                style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
          chip(
            ativo: _soFavoritos,
            cor: Colors.amber,
            aoTocar: () => setState(() => _soFavoritos = !_soFavoritos),
            filho: Row(
              children: [
                Icon(_soFavoritos ? Icons.star : Icons.star_border,
                    size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                const Text('Favoritos',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
          for (var i = 0; i < 5; i++)
            chip(
              ativo: _filtroHumor == i,
              cor: corDoHumor(i / 4),
              aoTocar: () =>
                  setState(() => _filtroHumor = _filtroHumor == i ? null : i),
              filho: Row(
                children: [
                  Icon(iconeHumor(i / 4), size: 16, color: corDoHumor(i / 4)),
                  const SizedBox(width: 4),
                  Text(rotuloHumor(i / 4),
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _vazio(dynamic cores, {required bool temRegistros}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(temRegistros ? Icons.search_off : Icons.auto_stories,
                size: 54, color: cores.textoSecundario),
            const SizedBox(height: 14),
            Text(
              temRegistros
                  ? 'Nenhum registro com esses filtros.'
                  : 'Você ainda não tem registros.\nToque no + para começar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cores.textoSecundario, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- lista
  Widget _listaAgrupada(List<EntradaDiario> lista, dynamic cores) {
    // Agrupa por mês, na ordem (já vem do mais novo para o mais antigo).
    final grupos = <String, List<EntradaDiario>>{};
    for (final e in lista) {
      grupos.putIfAbsent(_chaveMes(e.data), () => []).add(e);
    }

    final itens = <Widget>[];
    var indice = 0;
    grupos.forEach((chave, entradas) {
      final fechado = _fechados.contains(chave);
      itens.add(_cabecalhoMes(chave, entradas, fechado, cores));
      if (!fechado) {
        for (final e in entradas) {
          itens.add(EntradaSuave(
            delay: Duration(milliseconds: 40 * (indice < 8 ? indice : 8)),
            child: _cartao(e, cores),
          ));
          indice++;
        }
      }
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: itens,
    );
  }

  Widget _cabecalhoMes(String chave, List<EntradaDiario> entradas,
      bool fechado, dynamic cores) {
    final partes = chave.split('-');
    final ano = partes[0];
    final mes = int.parse(partes[1]);

    final contagem = List<int>.filled(5, 0);
    var soma = 0.0;
    for (final e in entradas) {
      contagem[_nivel(e.humor)]++;
      soma += e.humor;
    }
    final media = soma / entradas.length;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() {
        if (!_fechados.remove(chave)) _fechados.add(chave);
      }),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 14, 2, 10),
        child: Row(
          children: [
            AnimatedRotation(
              turns: fechado ? -0.25 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.expand_more, color: cores.textoSecundario),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_meses[mes - 1]} $ano',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  // Faixa com a proporção de cada humor no mês.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 6,
                      child: Row(
                        children: [
                          for (var i = 0; i < 5; i++)
                            if (contagem[i] > 0)
                              Expanded(
                                flex: contagem[i],
                                child: Container(color: corDoHumor(i / 4)),
                              ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(iconeHumor(media), color: corDoHumor(media), size: 22),
                Text(
                  '${entradas.length} ${entradas.length == 1 ? 'registro' : 'registros'}',
                  style:
                      TextStyle(color: cores.textoSecundario, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartao(EntradaDiario e, dynamic cores) {
    final cor = corDoHumor(e.humor);
    final fav = _ehFavorito(e);
    final titulo = e.titulo.trim().isEmpty ? 'Sem título' : e.titulo.trim();
    final hora =
        '${e.data.hour.toString().padLeft(2, '0')}:${e.data.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: ValueKey(e.id ?? '${e.data.microsecondsSinceEpoch}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmarExclusao(),
      onDismissed: (_) {
        final id = e.id;
        if (id != null) DiarioService().deletarEntrada(id);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      child: GestureDetector(
        onTap: () => _abrir(e),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [cor.withValues(alpha: 0.28), cores.card],
            ),
            border: Border.all(color: cor.withValues(alpha: 0.35)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 5, color: cor),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                    child: SizedBox(
                      width: 44,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${e.data.day}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                          Text(_diasAbrev[e.data.weekday % 7],
                              style: TextStyle(
                                  color: cores.textoSecundario, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(iconeHumor(e.humor), color: cor, size: 16),
                              const SizedBox(width: 5),
                              Text('${rotuloHumor(e.humor)} · $hora',
                                  style: TextStyle(color: cor, fontSize: 11.5)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(titulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Text(e.texto.trim(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: cores.textoSecundario,
                                  fontSize: 13,
                                  height: 1.3)),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: fav ? 'Remover dos favoritos' : 'Favoritar',
                    onPressed: () {
                      final id = e.id;
                      if (id != null) {
                        DiarioService().alternarFavorito(id, fav);
                      }
                    },
                    icon: Icon(fav ? Icons.star : Icons.star_border,
                        color: fav ? Colors.amber : Colors.white38),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}