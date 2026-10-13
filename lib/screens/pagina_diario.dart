// lib/screens/pagina_diario.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/entrada_diario.dart';
import '../services/diario_service.dart';
import '../theme/tema.dart';
import '../utils/humor_utils.dart';
import '../widgets/animacoes.dart';

const List<String> _mesesAbrev = [
  'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
  'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
];
const List<String> _diasSemana = [
  'Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira',
  'Quinta-feira', 'Sexta-feira', 'Sábado'
];

/// Cores de fundo opcionais. null = usa o fundo do tema do app.
const List<Color?> _coresFundo = [
  null,
  Color(0xFF000000),
  Color(0xFF1A1A2E),
  Color(0xFF2E1A3E),
  Color(0xFF1A2E2E),
  Color(0xFF2E1A1A),
];

/// Perguntas para quem não sabe por onde começar.
const List<String> _inspiracoes = [
  'Como foi o meu dia?',
  'O que me fez bem hoje?',
  'O que me preocupou?',
  'Pelo que sou grato hoje?',
  'Como estou dormindo e me alimentando?',
  'O que eu gostaria de fazer diferente amanhã?',
];

class PaginaDiario extends StatefulWidget {
  final DateTime? dataSelecionada;
  final EntradaDiario? entradaExistente;

  /// Humor já escolhido (0.0 a 1.0), por exemplo vindo da tela de início.
  final double? humorInicial;

  const PaginaDiario({
    super.key,
    this.dataSelecionada,
    this.entradaExistente,
    this.humorInicial,
  });

  @override
  State<PaginaDiario> createState() => _PaginaDiarioState();
}

class _PaginaDiarioState extends State<PaginaDiario> {
  final tituloController = TextEditingController();
  final controller = TextEditingController();
  final _foco = FocusNode();

  late DateTime data;
  double humor = 0.5;
  bool favorito = false;
  double tamanhoFonte = 16;
  Color? corFundo;

  bool _salvando = false;
  bool _salvo = false;

  // Para saber se o usuário mexeu em alguma coisa (aviso ao sair).
  late final String _tituloInicial;
  late final String _textoInicial;
  late final double _humorInicial;
  late final bool _favoritoInicial;
  late final DateTime _dataInicial;

  EntradaDiario? get _existente => widget.entradaExistente;

  /// Lê o campo "favorito" do registro sem depender de como o modelo o chama.
  bool _lerFavorito(EntradaDiario e) {
    try {
      return (e as dynamic).favorito == true;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    final ex = _existente;
    if (ex != null) {
      tituloController.text = ex.titulo;
      controller.text = ex.texto;
      humor = _arredondar(ex.humor);
      data = ex.data;
      favorito = _lerFavorito(ex);
    } else {
      data = widget.dataSelecionada ?? DateTime.now();
      if (widget.humorInicial != null) humor = _arredondar(widget.humorInicial!);
    }
    _tituloInicial = tituloController.text;
    _textoInicial = controller.text;
    _humorInicial = humor;
    _favoritoInicial = favorito;
    _dataInicial = data;

    tituloController.addListener(_atualizar);
    controller.addListener(_atualizar);
    _carregarPreferencias();
  }

  @override
  void dispose() {
    tituloController.dispose();
    controller.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  double _arredondar(double v) => ((v * 4).round().clamp(0, 4)) / 4;

  bool get _alterado =>
      !_salvo &&
      (tituloController.text != _tituloInicial ||
          controller.text != _textoInicial ||
          humor != _humorInicial ||
          favorito != _favoritoInicial ||
          data != _dataInicial);

  int get _palavras {
    final t = controller.text.trim();
    return t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length;
  }

  // ------------------------------------------------------------ preferências
  Future<void> _carregarPreferencias() async {
    try {
      final p = await SharedPreferences.getInstance();
      final fonte = p.getDouble('diario_fonte');
      final fundo = p.getInt('diario_fundo');
      if (!mounted) return;
      setState(() {
        if (fonte != null) tamanhoFonte = fonte;
        if (fundo != null) corFundo = Color(fundo);
      });
    } catch (_) {}
  }

  Future<void> _guardarPreferencias() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setDouble('diario_fonte', tamanhoFonte);
      if (corFundo == null) {
        await p.remove('diario_fundo');
      } else {
        await p.setInt('diario_fundo', corFundo!.toARGB32());
      }
    } catch (_) {}
  }

  // ------------------------------------------------------------ ações
  void _aviso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> _confirmar(String titulo, String texto, String botao) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Voltar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(botao,
                  style: const TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    return r == true;
  }

  Future<void> _fechar() async {
    if (!_alterado) {
      Navigator.pop(context);
      return;
    }
    if (await _confirmar('Descartar alterações?',
        'O que você escreveu ainda não foi salvo.', 'Descartar')) {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _salvar() async {
    final texto = controller.text.trim();
    if (texto.isEmpty) {
      _aviso('Escreva algo antes de salvar.');
      return;
    }
    setState(() => _salvando = true);
    try {
      final servico = DiarioService();
      final ex = _existente;
      if (ex != null) {
        await servico.atualizarEntrada(
          ex.id!,
          titulo: tituloController.text.trim(),
          texto: texto,
          humor: humor,
          data: data,
        );
        if (favorito != _favoritoInicial) {
          await servico.alternarFavorito(ex.id!, _favoritoInicial);
        }
      } else {
        await servico.salvarEntrada(
          texto,
          titulo: tituloController.text.trim(),
          humor: humor,
          data: data,
          favorito: favorito,
        );
      }
      HapticFeedback.lightImpact();
      _salvo = true;
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _aviso('Não consegui salvar: $e');
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _excluir() async {
    final ex = _existente;
    if (ex == null) return;
    if (!await _confirmar('Excluir este registro?',
        'Essa ação não pode ser desfeita.', 'Excluir')) {
      return;
    }
    try {
      await DiarioService().deletarEntrada(ex.id!);
      _salvo = true;
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _aviso('Não consegui excluir: $e');
    }
  }

  Future<void> _escolherData() async {
    final nova = await showDatePicker(
      context: context,
      initialDate: data,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (nova != null) {
      setState(() => data = DateTime(nova.year, nova.month, nova.day,
          data.hour, data.minute));
    }
  }

  void _usarInspiracao(String pergunta) {
    final atual = controller.text;
    final novo = atual.trim().isEmpty ? '$pergunta\n\n' : '$atual\n\n$pergunta\n';
    controller.value = TextEditingValue(
      text: novo,
      selection: TextSelection.collapsed(offset: novo.length),
    );
    _foco.requestFocus();
  }

  String _rotuloData() {
    final hoje = DateTime.now();
    final h = DateTime(hoje.year, hoje.month, hoje.day);
    final d = DateTime(data.year, data.month, data.day);
    final dif = h.difference(d).inDays;
    if (dif == 0) return 'Hoje';
    if (dif == 1) return 'Ontem';
    return _diasSemana[data.weekday % 7];
  }

  // ------------------------------------------------------------ folhas
  void _abrirSeletorFundo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cor de fundo',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _coresFundo.map((cor) {
                final escolhida = corFundo == cor;
                return GestureDetector(
                  onTap: () {
                    setState(() => corFundo = cor);
                    _guardarPreferencias();
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cor ?? Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: escolhida ? Colors.white : Colors.white24,
                        width: escolhida ? 2.5 : 1,
                      ),
                    ),
                    child: cor == null
                        ? const Icon(Icons.auto_awesome,
                            size: 18, color: Colors.white70)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            const Text('A primeira opção usa o fundo do tema do app.',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _abrirSeletorFonte() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tamanho da letra: ${tamanhoFonte.round()}',
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
              Slider(
                activeColor: context.cores.destaque,
                value: tamanhoFonte,
                min: 12,
                max: 28,
                divisions: 16,
                onChanged: (v) {
                  setModal(() => tamanhoFonte = v);
                  setState(() => tamanhoFonte = v);
                },
                onChangeEnd: (_) => _guardarPreferencias(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirInspiracoes() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sem ideias? Comece por aqui',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in _inspiracoes)
                    ActionChip(
                      label: Text(p),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _usarInspiracao(p);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ tela
  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final corHumor = corDoHumor(humor);
    final podeSalvar = controller.text.trim().isNotEmpty && !_salvando;

    return PopScope(
      canPop: !_alterado,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _fechar();
      },
      child: Scaffold(
        backgroundColor: corFundo ?? Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- topo
                Row(
                  children: [
                    IconButton(
                      onPressed: _fechar,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    const Spacer(),
                    if (_existente != null)
                      IconButton(
                        tooltip: 'Excluir',
                        onPressed: _excluir,
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.white70),
                      ),
                    IconButton(
                      tooltip: 'Favoritar',
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() => favorito = !favorito);
                      },
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (c, a) =>
                            ScaleTransition(scale: a, child: c),
                        child: Icon(
                          favorito ? Icons.star : Icons.star_border,
                          key: ValueKey(favorito),
                          color: favorito ? Colors.amber : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    FilledButton(
                      onPressed: podeSalvar ? _salvar : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: cores.destaque,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: _salvando
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Salvar'),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ---- data
                GestureDetector(
                  onTap: _escolherData,
                  child: Row(
                    children: [
                      Text('${data.day}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_rotuloData(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic)),
                          Text('${_mesesAbrev[data.month - 1]}. ${data.year}',
                              style: TextStyle(
                                  color: cores.textoSecundario, fontSize: 13)),
                        ],
                      ),
                      Icon(Icons.keyboard_arrow_down,
                          color: cores.textoSecundario),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ---- humor
                EntradaSuave(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                      color: cores.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: corHumor.withValues(alpha: 0.45)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (var i = 0; i < 5; i++) _botaoHumor(i / 4),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            'Me sinto: ${rotuloHumor(humor)}',
                            key: ValueKey(humor),
                            style: TextStyle(
                                color: corHumor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ---- título
                TextField(
                  controller: tituloController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [LengthLimitingTextInputFormatter(80)],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Dê um título (opcional)',
                    hintStyle: TextStyle(color: Colors.white38),
                  ),
                ),

                // ---- corpo
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: _foco,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: tamanhoFonte,
                        height: 1.45),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Escreva seu registro aqui...',
                      hintStyle: TextStyle(color: Colors.white38),
                    ),
                  ),
                ),

                // ---- contador
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 2),
                  child: Text(
                    '$_palavras ${_palavras == 1 ? 'palavra' : 'palavras'}',
                    style:
                        TextStyle(color: cores.textoSecundario, fontSize: 12),
                  ),
                ),

                // ---- barra de ferramentas
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: cores.card,
                    borderRadius: BorderRadius.circular(30),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ferramenta(Icons.lightbulb_outline, 'Ideias',
                          _abrirInspiracoes),
                      _ferramenta(Icons.layers_outlined, 'Fundo',
                          _abrirSeletorFundo),
                      _ferramenta(
                          Icons.text_fields, 'Letra', _abrirSeletorFonte),
                      _ferramenta(Icons.image_outlined, 'Foto',
                          () => _aviso('Fotos chegam na próxima versão.'),
                          apagado: true),
                      _ferramenta(Icons.mic_none, 'Voz',
                          () => _aviso('Áudios chegam na próxima versão.'),
                          apagado: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _botaoHumor(double valor) {
    final selecionado = humor == valor;
    final cor = corDoHumor(valor);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => humor = valor);
      },
      child: AnimatedScale(
        scale: selecionado ? 1.18 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: cor.withValues(alpha: selecionado ? 0.3 : 0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: selecionado ? cor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Icon(iconeHumor(valor),
              color: selecionado ? cor : cor.withValues(alpha: 0.6),
              size: 30),
        ),
      ),
    );
  }

  Widget _ferramenta(IconData icone, String rotulo, VoidCallback aoTocar,
      {bool apagado = false}) {
    final cor = apagado ? Colors.white38 : Colors.white;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: aoTocar,
      child: Column(
        children: [
          Icon(icone, color: cor, size: 22),
          const SizedBox(height: 4),
          Text(rotulo,
              style: TextStyle(
                  color: apagado ? Colors.white30 : Colors.white70,
                  fontSize: 11)),
        ],
      ),
    );
  }
}