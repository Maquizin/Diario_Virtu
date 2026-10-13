// lib/screens/tela_relatorios.dart
//
// Lista dos relatórios salvos (acessada em Configurações).

import 'package:flutter/material.dart';

import '../services/gerador_relatorios.dart';
import '../services/relatorio_service.dart';
import '../theme/tema.dart';
import '../widgets/animacoes.dart';
import 'tela_relatorio.dart';

class TelaRelatorios extends StatefulWidget {
  const TelaRelatorios({super.key});

  @override
  State<TelaRelatorios> createState() => _TelaRelatoriosState();
}

class _TelaRelatoriosState extends State<TelaRelatorios> {
  late final Stream<List<RelatorioSalvo>> _stream = RelatorioService().listar();

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Scaffold(
      appBar: AppBar(title: const Text('Meus relatórios')),
      body: StreamBuilder<List<RelatorioSalvo>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Não foi possível carregar os relatórios.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cores.textoSecundario),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final lista = snapshot.data!;
          return ListenableBuilder(
            listenable: geradorRelatorios,
            builder: (context, _) => _conteudo(context, lista),
          );
        },
      ),
    );
  }

  Widget _conteudo(BuildContext context, List<RelatorioSalvo> lista) {
    final cores = context.cores;
    final tarefas = geradorRelatorios.tarefas;
    {
      {
          if (lista.isEmpty && tarefas.isEmpty) {
            return Center(
              child: EntradaSuave(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description_outlined,
                          size: 72, color: cores.destaque),
                      const SizedBox(height: 16),
                      const Text('Nenhum relatório ainda',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        'Na aba Estatísticas, toque em "Gerar relatório" para criar o do mês. Ele fica guardado aqui.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cores.textoSecundario),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: tarefas.length + lista.length,
            itemBuilder: (context, i) {
              if (i < tarefas.length) return _CartaoPendente(tarefas[i]);
              i -= tarefas.length;
              final r = lista[i];
              return EntradaSuave(
                delay: Duration(milliseconds: 70 * i),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TelaRelatorio(relatorio: r)),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cores.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cores.destaque.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.description_outlined,
                              color: cores.destaque),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.titulo,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 3),
                              Text(
                                '${r.stats.totalRegistros} registros  ·  gerado em ${dataHoraCurta(r.criadoEm)}',
                                style: TextStyle(
                                    color: cores.textoSecundario, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: cores.textoSecundario),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
      }
    }
  }
}

/// Cartão de um relatório que está sendo gerado (ou que falhou).
class _CartaoPendente extends StatelessWidget {
  final TarefaRelatorio t;
  const _CartaoPendente(this.t);

  String get _status {
    switch (t.estado) {
      case EstadoTarefa.tentando:
        return t.tentativas > 1
            ? 'Tentando de novo (tentativa ${t.tentativas})...'
            : 'A IA está lendo seus registros...';
      case EstadoTarefa.aguardando:
        return 'A IA está ocupada. Nova tentativa em instantes '
            '(tentativa ${t.tentativas}).';
      case EstadoTarefa.falhou:
        return 'Não foi possível gerar. Toque em "Tentar de novo".';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final falhou = t.estado == EstadoTarefa.falhou;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cores.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: (falhou ? Colors.redAccent : cores.destaque)
                .withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: falhou
                ? const Icon(Icons.error_outline, color: Colors.redAccent)
                : const CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${t.refazer ? 'Refazendo' : 'Gerando'} ${t.titulo}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(_status,
                    style:
                        TextStyle(color: cores.textoSecundario, fontSize: 12)),
              ],
            ),
          ),
          if (falhou)
            TextButton(
              onPressed: () =>
                  geradorRelatorios.solicitar(t.mes, refazer: t.refazer),
              child: const Text('Tentar de novo'),
            ),
          IconButton(
            tooltip: 'Cancelar',
            icon: Icon(Icons.close, color: cores.textoSecundario),
            onPressed: () => geradorRelatorios.cancelar(t.id),
          ),
        ],
      ),
    );
  }
}