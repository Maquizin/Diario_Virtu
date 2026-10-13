// lib/screens/tela_relatorio.dart
//
// Relatório de um mês em tela cheia: estatísticas + análise da IA.
// Ações: compartilhar (PDF), refazer com a IA e excluir.

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../services/gerador_relatorios.dart';
import '../services/relatorio_pdf.dart';
import '../services/relatorio_service.dart';
import '../theme/tema.dart';
import '../utils/humor_utils.dart';
import '../widgets/animacoes.dart';

/// Versão opaca da cor dos cartões (para janelas de confirmação).
Color _opaco(BuildContext c) =>
    Color.alphaBlend(c.cores.card, const Color(0xFF0B0B10));

class TelaRelatorio extends StatefulWidget {
  final RelatorioSalvo relatorio;
  const TelaRelatorio({super.key, required this.relatorio});

  @override
  State<TelaRelatorio> createState() => _TelaRelatorioState();
}

class _TelaRelatorioState extends State<TelaRelatorio> {
  late RelatorioSalvo _r = widget.relatorio;
  bool _ocupado = false;
  String _mensagemOcupado = '';
  bool _refazendo = false; // há um "refazer" rodando em segundo plano

  @override
  void initState() {
    super.initState();
    _refazendo = _emAndamento();
    geradorRelatorios.addListener(_aoMudarGerador);
  }

  @override
  void dispose() {
    geradorRelatorios.removeListener(_aoMudarGerador);
    super.dispose();
  }

  bool _emAndamento() {
    final t = geradorRelatorios.tarefa(_r.id);
    return t != null && t.estado != EstadoTarefa.falhou;
  }

  Future<void> _aoMudarGerador() async {
    final agora = _emAndamento();
    final terminou = _refazendo && geradorRelatorios.tarefa(_r.id) == null;
    if (mounted && agora != _refazendo) setState(() => _refazendo = agora);
    if (terminou) {
      // Terminou (ou foi cancelado): recarrega o relatório salvo.
      try {
        final novo = await RelatorioService().buscar(_r.mesData);
        if (novo != null && mounted) setState(() => _r = novo);
      } catch (_) {}
    }
  }

  void _aviso(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> _confirmar({
    required String titulo,
    required String texto,
    required String botao,
    bool perigoso = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _opaco(ctx),
        title: Text(titulo, style: const TextStyle(color: Colors.white)),
        content: Text(texto, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(botao,
                style: TextStyle(color: perigoso ? Colors.redAccent : null)),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _compartilhar() async {
    setState(() {
      _ocupado = true;
      _mensagemOcupado = 'Preparando o PDF...';
    });
    try {
      final bytes = await gerarPdfRelatorio(_r);
      await Printing.sharePdf(bytes: bytes, filename: 'relatorio-${_r.id}.pdf');
    } catch (e) {
      if (mounted) _aviso('Não foi possível criar o PDF: $e');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _refazer() async {
    final ok = await _confirmar(
      titulo: 'Refazer o relatório?',
      texto:
          'A IA vai ler os registros de ${_r.titulo} novamente. O relatório atual continua disponível até o novo ficar pronto, e então será substituído.',
      botao: 'Refazer',
    );
    if (!ok || !mounted) return;

    // Em segundo plano: o relatório atual continua aqui até o novo ficar pronto.
    geradorRelatorios.solicitar(_r.mesData, refazer: true);
    _aviso('Refazendo em segundo plano. Se a IA estiver ocupada, o app '
        'tenta de novo sozinho.');
  }

  Future<void> _excluir() async {
    final ok = await _confirmar(
      titulo: 'Excluir o relatório?',
      texto:
          'O relatório de ${_r.titulo} será apagado. Seus registros do diário não são afetados, e você pode gerar outro depois.',
      botao: 'Excluir',
      perigoso: true,
    );
    if (!ok || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      geradorRelatorios.cancelar(_r.id);
      await RelatorioService().excluir(_r.id);
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
          const SnackBar(content: Text('Relatório excluído.')));
    } catch (e) {
      if (mounted) _aviso('Não foi possível excluir: $e');
    }
  }

  // ----- UI -----
  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final a = _r.analise;

    return Scaffold(
      appBar: AppBar(
        title: Text('Relatório de ${_r.titulo}'),
        actions: [
          IconButton(
            tooltip: 'Compartilhar PDF',
            onPressed: _ocupado ? null : _compartilhar,
            icon: const Icon(Icons.ios_share),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                'Gerado em ${dataHoraCurta(_r.criadoEm)}',
                style: TextStyle(color: cores.textoSecundario, fontSize: 13),
              ),
              const SizedBox(height: 20),

              _titulo('Estatísticas do mês'),
              EntradaSuave(child: _blocoEstatisticas()),
              const SizedBox(height: 14),
              EntradaSuave(
                delay: const Duration(milliseconds: 120),
                child: _blocoHumores(),
              ),
              const SizedBox(height: 28),

              _titulo('Análise da IA'),
              _cartaoTexto('Resumo geral', a.resumoGeral),
              _cartaoTemas('Temas recorrentes', a.temasRecorrentes),
              _cartaoLista('Pontos de atenção', a.pontosDeAtencao),
              _cartaoTexto('Variação do humor', a.variacaoDoHumor),
              _cartaoTexto('Observações para o médico', a.observacoesParaOMedico),

              const SizedBox(height: 4),
              Text(
                'Texto gerado por IA a partir dos seus registros. Não é diagnóstico e não substitui avaliação profissional.',
                style: TextStyle(color: cores.textoSecundario, fontSize: 12),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _ocupado ? null : _compartilhar,
                  style: FilledButton.styleFrom(
                    backgroundColor: cores.destaque,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Compartilhar em PDF'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: (_ocupado || _refazendo) ? null : _refazer,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: _refazendo
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome),
                  label: Text(_refazendo ? 'Refazendo...' : 'Refazer com a IA'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _ocupado ? null : _excluir,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                label: const Text('Excluir relatório',
                    style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),

          // Camada de "carregando" enquanto gera PDF ou refaz com a IA.
          if (_ocupado)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(_mensagemOcupado,
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _titulo(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(t,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      );

  BoxDecoration _decoracaoCartao() => BoxDecoration(
        color: context.cores.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      );

  // ----- estatísticas -----
  Widget _blocoEstatisticas() {
    final s = _r.stats;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _mini('Registros',
                  NumeroAnimado(valor: s.totalRegistros, estilo: _numeroEstilo)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _mini(
                  'Dias com registro',
                  Text('${s.diasComRegistro}/${s.diasNoMes}',
                      style: _numeroEstilo)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _mini('Maior sequência',
                  NumeroAnimado(valor: s.maiorSequencia, estilo: _numeroEstilo)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _mini(
                  'Humor médio',
                  Row(
                    children: [
                      Icon(iconeHumor(s.humorMedio),
                          color: corDoHumor(s.humorMedio), size: 26),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(rotuloHumor(s.humorMedio),
                            style: _numeroEstilo.copyWith(fontSize: 18),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  )),
            ),
          ],
        ),
      ],
    );
  }

  static const _numeroEstilo = TextStyle(
      color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold);

  Widget _mini(String rotulo, Widget valor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _decoracaoCartao(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          valor,
          const SizedBox(height: 4),
          Text(rotulo,
              style: TextStyle(
                  color: context.cores.textoSecundario, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _blocoHumores() {
    final s = _r.stats;
    final total = s.totalRegistros == 0 ? 1 : s.totalRegistros;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _decoracaoCartao(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Humor ao longo do mês',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          for (var i = 4; i >= 0; i--)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: corDoHumor(i / 4),
                    child: Icon(iconeHumor(i / 4),
                        size: 16, color: Colors.black87),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 78,
                    child: Text(rotuloHumor(i / 4),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                            begin: 0, end: s.contagemHumores[i] / total),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => LinearProgressIndicator(
                          value: v,
                          minHeight: 10,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor:
                              AlwaysStoppedAnimation(corDoHumor(i / 4)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 24,
                    child: Text('${s.contagemHumores[i]}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ----- análise da IA -----
  Widget _cartao(String titulo, Widget conteudo) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _decoracaoCartao(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: TextStyle(
                  color: context.cores.destaque,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          conteudo,
        ],
      ),
    );
  }

  Widget _cartaoTexto(String titulo, String texto) {
    if (texto.trim().isEmpty) return const SizedBox.shrink();
    return _cartao(
      titulo,
      Text(texto,
          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
    );
  }

  Widget _cartaoLista(String titulo, List<String> itens) {
    if (itens.isEmpty) return const SizedBox.shrink();
    return _cartao(
      titulo,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in itens)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: 10),
                    child: Icon(Icons.circle,
                        size: 6, color: context.cores.destaque),
                  ),
                  Expanded(
                    child: Text(item,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15, height: 1.4)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cartaoTemas(String titulo, List<String> temas) {
    if (temas.isEmpty) return const SizedBox.shrink();
    final d = context.cores.destaque;
    return _cartao(
      titulo,
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final t in temas)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: d.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(t,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}