// lib/screens/tela_sobre_mim.dart
//
// "Sobre mim": perfil editável + controle dos dados (LGPD).
// Tudo fica em usuarios/{uid}. O usuário decide se essas informações entram
// no relatório da IA (opção "Usar no relatório", desligada por padrão).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/perfil_service.dart';
import '../theme/tema.dart';
import '../widgets/animacoes.dart';
import '../services/diario_service.dart';
import 'login_screen.dart';
import 'tela_recortar.dart';

const _nomesHumor = ['Muito mal', 'Mal', 'Neutro', 'Bem', 'Muito bem'];
const _opcoesSexo = ['Feminino', 'Masculino', 'Outro', 'Prefiro não informar'];

class TelaSobreMim extends StatefulWidget {
  const TelaSobreMim({super.key});

  @override
  State<TelaSobreMim> createState() => _TelaSobreMimState();
}

class _TelaSobreMimState extends State<TelaSobreMim> {
  final _db = DiarioService().firestore;
  final _user = FirebaseAuth.instance.currentUser!;

  final _nome = TextEditingController();
  final _descricao = TextEditingController();
  final _objetivo = TextEditingController();
  final _profissional = TextEditingController();

  DateTime? _nascimento;
  String? _sexo;
  List<String> _gostos = [];
  List<String> _bem = [];
  List<String> _mal = [];
  bool _usarNoRelatorio = false;

  bool _carregando = true;
  bool _ocupado = false;
  bool _alterado = false;

  DocumentReference<Map<String, dynamic>> get _perfil =>
      _db.collection('usuarios').doc(_user.uid);

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    _objetivo.dispose();
    _profissional.dispose();
    super.dispose();
  }

  List<String> _lista(Object? v) =>
      ((v as List?) ?? const []).map((e) => '$e').toList();

  Future<void> _carregar() async {
    Map<String, dynamic> d = {};
    try {
      d = (await _perfil.get()).data() ?? {};
    } catch (_) {}

    _nome.text = (d['nome'] as String?) ?? _user.displayName ?? '';
    _descricao.text = (d['descricao'] as String?) ?? '';
    _objetivo.text = (d['objetivo'] as String?) ?? '';
    _profissional.text = (d['profissional'] as String?) ?? '';
    final n = d['nascimento'];
    _nascimento = n is Timestamp ? n.toDate() : null;
    _sexo = d['sexo'] as String?;
    _gostos = _lista(d['gostos']);
    _bem = _lista(d['bem']);
    _mal = _lista(d['mal']);
    _usarNoRelatorio = d['usarNoRelatorio'] == true;

    // Só começa a marcar "alterado" depois de carregar.
    for (final c in [_nome, _descricao, _objetivo, _profissional]) {
      c.addListener(_marcar);
    }
    if (mounted) setState(() => _carregando = false);
  }

  void _marcar() {
    if (!_alterado && mounted) setState(() => _alterado = true);
  }

  void _aviso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  int? _idade() {
    final n = _nascimento;
    if (n == null) return null;
    final hoje = DateTime.now();
    var idade = hoje.year - n.year;
    if (hoje.month < n.month || (hoje.month == n.month && hoje.day < n.day)) {
      idade--;
    }
    return idade;
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// 0.0 a 1.0: quanto do perfil já foi preenchido.
  double _completude() {
    final itens = [
      _nome.text.trim().isNotEmpty,
      _nascimento != null,
      _sexo != null,
      _descricao.text.trim().isNotEmpty,
      _gostos.isNotEmpty,
      _bem.isNotEmpty,
      _mal.isNotEmpty,
      _objetivo.text.trim().isNotEmpty,
    ];
    return itens.where((e) => e).length / itens.length;
  }

  // ---------------------------------------------------------------- salvar
  Future<void> _salvar() async {
    setState(() => _ocupado = true);
    try {
      final nome = _nome.text.trim();
      if (nome.isNotEmpty && nome != _user.displayName) {
        await _user.updateDisplayName(nome);
      }
      await _perfil.set({
        'nome': nome,
        'descricao': _descricao.text.trim(),
        'objetivo': _objetivo.text.trim(),
        'profissional': _profissional.text.trim(),
        'nascimento': _nascimento == null
            ? FieldValue.delete()
            : Timestamp.fromDate(_nascimento!),
        'sexo': _sexo ?? FieldValue.delete(),
        'gostos': _gostos,
        'bem': _bem,
        'mal': _mal,
        'usarNoRelatorio': _usarNoRelatorio,
      }, SetOptions(merge: true));
      if (mounted) setState(() => _alterado = false);
      _aviso('Informações salvas');
    } catch (e) {
      _aviso('Não foi possível salvar: $e');
    }
    if (mounted) setState(() => _ocupado = false);
  }

  Future<void> _escolherNascimento() async {
    final agora = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _nascimento ?? DateTime(agora.year - 18, 1, 1),
      firstDate: DateTime(1900),
      lastDate: agora,
      helpText: 'Data de nascimento',
    );
    if (d != null) {
      setState(() => _nascimento = d);
      _marcar();
    }
  }

  // ---------------------------------------------------------------- exportar
  Future<void> _exportar() async {
    setState(() => _ocupado = true);
    try {
      final entradas =
          await _perfil.collection('entradas').get();
      final lista = entradas.docs.map((d) => d.data()).toList()
        ..sort((a, b) =>
            (b['data'] as Timestamp).compareTo(a['data'] as Timestamp));

      pw.Font? normal, negrito;
      try {
        normal = await PdfGoogleFonts.nunitoRegular();
        negrito = await PdfGoogleFonts.nunitoBold();
      } catch (_) {}

      final doc = pw.Document(
        theme: (normal != null && negrito != null)
            ? pw.ThemeData.withFont(base: normal, bold: negrito)
            : null,
      );

      String linha(String rotulo, String? valor) =>
          (valor == null || valor.trim().isEmpty) ? '' : '$rotulo: $valor';

      final perfilLinhas = <String>[
        linha('Nome', _nome.text),
        linha('E-mail', _user.email),
        linha('Nascimento',
            _nascimento == null ? null : '${_fmt(_nascimento!)} (${_idade()} anos)'),
        linha('Sexo', _sexo),
        linha('Sobre mim', _descricao.text),
        linha('Coisas de que gosto', _gostos.join(', ')),
        linha('O que me faz bem', _bem.join(', ')),
        linha('O que me deixa mal', _mal.join(', ')),
        linha('Objetivo com o diário', _objetivo.text),
        linha('Profissional que me acompanha', _profissional.text),
      ].where((e) => e.isNotEmpty).toList();

      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => [
          pw.Text('SERENIA – Meus dados',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('Exportado em ${_fmt(DateTime.now())}'),
          pw.SizedBox(height: 14),
          for (final l in perfilLinhas) pw.Text(l),
          pw.SizedBox(height: 16),
          pw.Text('Registros (${lista.length})',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Divider(),
          for (final e in lista)
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${_fmt((e['data'] as Timestamp).toDate())}  •  '
                    '${_nomesHumor[(((e['humor'] as num?) ?? 0.5) * 4).round().clamp(0, 4)]}'
                    '${(e['titulo'] ?? '').toString().isEmpty ? '' : '  •  ${e['titulo']}'}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text((e['texto'] ?? '').toString()),
                ],
              ),
            ),
        ],
      ));

      await Printing.sharePdf(
          bytes: await doc.save(), filename: 'serenia-meus-dados.pdf');
      try {
        (await SharedPreferences.getInstance())
            .setBool('conquista_exportou', true);
      } catch (_) {}
    } catch (e) {
      _aviso('Não consegui exportar: $e');
    }
    if (mounted) setState(() => _ocupado = false);
  }

  // ---------------------------------------------------------------- excluir
  Future<void> _apagarColecao(String nome) async {
    final col = _perfil.collection(nome);
    while (true) {
      final snap = await col.limit(400).get();
      if (snap.docs.isEmpty) break;
      final lote = _db.batch();
      for (final d in snap.docs) {
        lote.delete(d.reference);
      }
      await lote.commit();
    }
  }

  Future<void> _excluirTudo() async {
    final controlador = TextEditingController();
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir todos os meus dados?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Isso apaga para sempre seus registros, relatórios, '
              'informações pessoais e a sua conta. Não dá para desfazer.\n\n'
              'Se quiser guardar uma cópia, exporte antes.\n\n'
              'Digite EXCLUIR para confirmar:',
            ),
            const SizedBox(height: 8),
            TextField(controller: controlador, autofocus: true),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(
                ctx, controlador.text.trim().toUpperCase() == 'EXCLUIR'),
            child: const Text('Excluir',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmou != true) return;

    setState(() => _ocupado = true);
    try {
      await _apagarColecao('entradas');
      await _apagarColecao('relatorios');
      await _perfil.delete();

      try {
        await _user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code != 'requires-recent-login') rethrow;
        _aviso('Seus dados foram apagados. Para remover também o login, '
            'entre de novo e repita a exclusão.');
      }

      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      _aviso('Não consegui excluir: $e');
      if (mounted) setState(() => _ocupado = false);
    }
  }

  // ---------------------------------------------------------------- visual
  InputDecoration _dec(String rotulo, {String? dica, IconData? icone}) {
    final cores = context.cores;
    return InputDecoration(
      labelText: rotulo,
      hintText: dica,
      prefixIcon: icone == null ? null : Icon(icone, size: 20),
      filled: true,
      fillColor: cores.cardSuave,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _secao(IconData icone, Color cor, String titulo, String? subtitulo,
      List<Widget> filhos,
      {int ordem = 0}) {
    final cores = context.cores;
    return EntradaSuave(
      delay: Duration(milliseconds: 80 * ordem),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cores.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icone, color: cor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      if (subtitulo != null)
                        Text(subtitulo,
                            style: TextStyle(
                                color: cores.textoSecundario, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...filhos,
          ],
        ),
      ),
    );
  }

  Widget _cabecalho() {
    final cores = context.cores;
    final nome = _nome.text.trim().isEmpty ? 'Seu nome' : _nome.text.trim();
    final idade = _idade();
    final fracao = _completude();

    return EntradaSuave(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cores.destaque.withValues(alpha: 0.55),
              cores.card,
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                StreamBuilder<Map<String, dynamic>>(
                  stream: PerfilService.stream(),
                  builder: (context, snap) {
                    final foto = PerfilService.imagem(snap.data, 'foto');
                    final ajuste = PerfilService.ajuste(snap.data, 'foto');
                    return Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                      child: ClipOval(
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: foto != null
                              ? ImagemAjustada(bytes: foto, ajuste: ajuste)
                              : (_user.photoURL != null
                                  ? Image.network(_user.photoURL!,
                                      fit: BoxFit.cover)
                                  : Container(
                                      color: cores.cardSuave,
                                      child: Icon(Icons.person,
                                          size: 40,
                                          color: cores.textoSecundario),
                                    )),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (idade != null) '$idade anos',
                          if (_sexo != null && _sexo != 'Prefiro não informar')
                            _sexo!,
                        ].join(' · '),
                        style: TextStyle(
                            color: cores.textoSecundario, fontSize: 13),
                      ),
                      Text(_user.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: cores.textoSecundario, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: fracao,
                      minHeight: 8,
                      backgroundColor: Colors.white12,
                      color: cores.destaque,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Perfil ${(fracao * 100).round()}% completo',
                    style:
                        TextStyle(color: cores.textoSecundario, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final idade = _idade();

    return PopScope(
      canPop: !_alterado,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final sair = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Descartar alterações?'),
            content: const Text('Você mudou algumas informações e não salvou.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Continuar editando')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Descartar',
                      style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        );
        if (sair == true && mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Sobre mim'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        bottomNavigationBar: _alterado
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: FilledButton(
                    onPressed: _ocupado ? null : _salvar,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: cores.destaque,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _ocupado
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Salvar alterações'),
                  ),
                ),
              )
            : null,
        body: _carregando
            ? const Center(child: CircularProgressIndicator())
            : AbsorbPointer(
                absorbing: _ocupado,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  children: [
                    _cabecalho(),

                    _secao(Icons.badge_outlined, Colors.pinkAccent,
                        'Quem sou eu', null, [
                      TextField(
                        controller: _nome,
                        textCapitalization: TextCapitalization.words,
                        decoration: _dec('Nome', icone: Icons.person_outline),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _escolherNascimento,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 16),
                          decoration: BoxDecoration(
                            color: cores.cardSuave,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.cake_outlined,
                                  size: 20, color: cores.textoSecundario),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _nascimento == null
                                      ? 'Data de nascimento'
                                      : '${_fmt(_nascimento!)}  ·  $idade anos',
                                  style: TextStyle(
                                      color: _nascimento == null
                                          ? cores.textoSecundario
                                          : Colors.white),
                                ),
                              ),
                              Icon(Icons.edit_calendar_outlined,
                                  size: 18, color: cores.textoSecundario),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text('Sexo',
                          style: TextStyle(
                              color: cores.textoSecundario, fontSize: 12)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final o in _opcoesSexo)
                            ChoiceChip(
                              label: Text(o),
                              selected: _sexo == o,
                              onSelected: (v) {
                                setState(() => _sexo = v ? o : null);
                                _marcar();
                              },
                            ),
                        ],
                      ),
                    ], ordem: 1),

                    _secao(Icons.edit_note, Colors.lightBlueAccent,
                        'Sobre mim', 'Como você se descreve, com suas palavras', [
                      TextField(
                        controller: _descricao,
                        maxLines: 4,
                        maxLength: 400,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _dec('Sobre mim',
                            dica: 'Ex.: sou estudante, gosto de silêncio...'),
                      ),
                    ], ordem: 2),

                    _secao(Icons.favorite_border, Colors.redAccent,
                        'Meu jeito',
                        'Ajuda a entender o que pesa e o que alivia', [
                      _EditorChips(
                        titulo: 'Coisas de que eu gosto',
                        dica: 'Ex.: música, jogos, desenhar',
                        cor: Colors.amber,
                        itens: _gostos,
                        aoMudar: (l) {
                          setState(() => _gostos = l);
                          _marcar();
                        },
                      ),
                      const SizedBox(height: 14),
                      _EditorChips(
                        titulo: 'O que me faz bem',
                        dica: 'Ex.: caminhar, conversar com amigos',
                        cor: Colors.greenAccent,
                        itens: _bem,
                        aoMudar: (l) {
                          setState(() => _bem = l);
                          _marcar();
                        },
                      ),
                      const SizedBox(height: 14),
                      _EditorChips(
                        titulo: 'O que me deixa mal',
                        dica: 'Ex.: prazos, dormir pouco',
                        cor: Colors.orangeAccent,
                        itens: _mal,
                        aoMudar: (l) {
                          setState(() => _mal = l);
                          _marcar();
                        },
                      ),
                    ], ordem: 3),

                    _secao(Icons.track_changes, Colors.tealAccent,
                        'Meu acompanhamento', 'Opcional', [
                      TextField(
                        controller: _objetivo,
                        maxLines: 3,
                        maxLength: 300,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _dec('O que busco com o diário',
                            dica: 'Ex.: entender melhor minha ansiedade'),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _profissional,
                        textCapitalization: TextCapitalization.words,
                        decoration: _dec('Profissional que me acompanha',
                            icone: Icons.medical_services_outlined),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Usar no relatório',
                            style: TextStyle(color: Colors.white)),
                        subtitle: Text(
                          'Deixa a IA considerar estas informações (idade, '
                          'sexo, gostos, o que faz bem e mal, objetivo). '
                          'Elas serão enviadas ao serviço de IA. '
                          'Desligado por padrão.',
                          style: TextStyle(
                              color: cores.textoSecundario, fontSize: 12),
                        ),
                        value: _usarNoRelatorio,
                        onChanged: (v) {
                          setState(() => _usarNoRelatorio = v);
                          _marcar();
                        },
                      ),
                    ], ordem: 4),

                    _secao(Icons.shield_outlined, Colors.purpleAccent,
                        'Meus dados (LGPD)',
                        'Leve uma cópia de tudo ou apague tudo', [
                      OutlinedButton.icon(
                        onPressed: _exportar,
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Exportar meus dados (PDF)'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _excluirTudo,
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent),
                        icon: const Icon(Icons.delete_forever_rounded),
                        label: const Text('Excluir todos os meus dados'),
                      ),
                    ], ordem: 5),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Campo para montar uma lista de palavras (chips): digita, toca em + e pronto.
class _EditorChips extends StatefulWidget {
  final String titulo;
  final String dica;
  final Color cor;
  final List<String> itens;
  final ValueChanged<List<String>> aoMudar;

  const _EditorChips({
    required this.titulo,
    required this.dica,
    required this.cor,
    required this.itens,
    required this.aoMudar,
  });

  @override
  State<_EditorChips> createState() => _EditorChipsState();
}

class _EditorChipsState extends State<_EditorChips> {
  final _campo = TextEditingController();

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  void _adicionar() {
    final t = _campo.text.trim();
    if (t.isEmpty || widget.itens.contains(t) || widget.itens.length >= 20) {
      return;
    }
    widget.aoMudar([...widget.itens, t]);
    _campo.clear();
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.titulo,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: _campo,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _adicionar(),
          decoration: InputDecoration(
            hintText: widget.dica,
            filled: true,
            fillColor: cores.cardSuave,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.add_circle, color: widget.cor),
              onPressed: _adicionar,
            ),
          ),
        ),
        if (widget.itens.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final i in widget.itens)
                Chip(
                  label: Text(i),
                  backgroundColor: widget.cor.withValues(alpha: 0.18),
                  side: BorderSide(color: widget.cor.withValues(alpha: 0.5)),
                  deleteIconColor: widget.cor,
                  onDeleted: () => widget
                      .aoMudar(widget.itens.where((e) => e != i).toList()),
                ),
            ],
          ),
        ],
      ],
    );
  }
}