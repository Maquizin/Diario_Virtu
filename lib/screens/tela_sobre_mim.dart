// lib/screens/tela_sobre_mim.dart
//
// "Sobre mim": dados simples do usuário + controle dos dados (LGPD):
// exportar tudo em PDF e excluir tudo (registros, relatórios, perfil e conta).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../services/diario_service.dart';
import '../theme/tema.dart';
import 'login_screen.dart';

const _nomesHumor = ['Muito mal', 'Mal', 'Neutro', 'Bem', 'Muito bem'];

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

  bool _carregando = true;
  bool _ocupado = false;

  DocumentReference<Map<String, dynamic>> get _perfil => _db.collection('usuarios').doc(_user.uid);

  @override
  void initState() {
    super.initState();
    _nome.text = _user.displayName ?? '';
    _carregar();
  }

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final doc = await _perfil.get();
      _descricao.text = (doc.data()?['descricao'] as String?) ?? '';
    } catch (_) {}
    if (mounted) setState(() => _carregando = false);
  }

  void _aviso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
        'descricao': _descricao.text.trim(),
        'nome': nome,
      }, SetOptions(merge: true));
      _aviso('Informações salvas');
    } catch (e) {
      _aviso('Não foi possível salvar: $e');
    }
    if (mounted) setState(() => _ocupado = false);
  }

  // ---------------------------------------------------------------- exportar
  Future<void> _exportar() async {
    setState(() => _ocupado = true);
    try {
      final entradas = await _db
          .collection('usuarios')
          .doc(_user.uid)
          .collection('entradas')
          .get();
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

      String fmt(DateTime d) =>
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => [
          pw.Text('SERENIA – Meus dados',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('Exportado em ${fmt(DateTime.now())}'),
          pw.SizedBox(height: 14),
          pw.Text('Nome: ${_nome.text.trim().isEmpty ? '-' : _nome.text.trim()}'),
          pw.Text('E-mail: ${_user.email ?? '-'}'),
          if (_descricao.text.trim().isNotEmpty)
            pw.Text('Sobre mim: ${_descricao.text.trim()}'),
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
                    '${fmt((e['data'] as Timestamp).toDate())}  •  '
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
    } catch (e) {
      _aviso('Não consegui exportar: $e');
    }
    if (mounted) setState(() => _ocupado = false);
  }

  // ---------------------------------------------------------------- excluir
  Future<void> _apagarColecao(String nome) async {
    final col = _db.collection('usuarios').doc(_user.uid).collection(nome);
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

  // ---------------------------------------------------------------- tela
  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Sobre mim'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : AbsorbPointer(
              absorbing: _ocupado,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextField(
                    controller: _nome,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _descricao,
                    maxLines: 4,
                    maxLength: 400,
                    decoration: const InputDecoration(
                      labelText: 'Como você se descreve?',
                      helperText: 'Opcional. Fica só na sua conta.',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('E-mail: ${_user.email ?? '-'}',
                      style: TextStyle(color: cores.textoSecundario)),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _salvar,
                    child: _ocupado
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Salvar'),
                  ),
                  const SizedBox(height: 32),
                  const Text('Meus dados (LGPD)',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    'Você pode levar uma cópia de tudo o que registrou ou '
                    'apagar tudo do SERENIA.',
                    style: TextStyle(color: cores.textoSecundario),
                  ),
                  const SizedBox(height: 14),
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
                ],
              ),
            ),
    );
  }
}