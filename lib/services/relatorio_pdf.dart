// lib/services/relatorio_pdf.dart
//
// Monta o PDF do relatório a partir dos dados salvos.
// O PDF não fica guardado como arquivo: é gerado na hora de compartilhar.

import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../utils/humor_utils.dart';
import 'relatorio_service.dart';

Future<Uint8List> gerarPdfRelatorio(RelatorioSalvo r) async {
  // Fonte com acentos e símbolos. Se não conseguir baixar, usa a padrão.
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

  final usuario = FirebaseAuth.instance.currentUser;
  final nome = usuario?.displayName ?? usuario?.email ?? '';
  final s = r.stats;
  final a = r.analise;
  const roxo = PdfColor.fromInt(0xFF5B3FD9);
  const cinza = PdfColors.grey700;

  pw.Widget titulo(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 18, bottom: 6),
        child: pw.Text(t,
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold, color: roxo)),
      );

  pw.Widget caixa(String rotulo, String valor) => pw.Container(
        width: 118,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(valor,
                style: pw.TextStyle(
                    fontSize: 17, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text(rotulo, style: const pw.TextStyle(fontSize: 9, color: cinza)),
          ],
        ),
      );

  pw.Widget secaoTexto(String t, String texto) {
    if (texto.trim().isEmpty) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [titulo(t), pw.Text(texto, style: const pw.TextStyle(fontSize: 11))],
    );
  }

  pw.Widget secaoLista(String t, List<String> itens) {
    if (itens.isEmpty) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        titulo(t),
        for (final item in itens)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 4,
                  height: 4,
                  margin: const pw.EdgeInsets.only(top: 5, right: 8),
                  decoration: const pw.BoxDecoration(
                      color: cinza, shape: pw.BoxShape.circle),
                ),
                pw.Expanded(
                    child: pw.Text(item, style: const pw.TextStyle(fontSize: 11))),
              ],
            ),
          ),
      ],
    );
  }

  final total = s.totalRegistros == 0 ? 1 : s.totalRegistros;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: cinza)),
      ),
      build: (ctx) => [
        pw.Text('Relatório do diário',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 2),
        pw.Text(r.titulo, style: const pw.TextStyle(fontSize: 15, color: cinza)),
        pw.SizedBox(height: 4),
        pw.Text(
          [
            if (nome.isNotEmpty) 'Paciente: $nome',
            'Gerado em ${dataHoraCurta(r.criadoEm)}',
          ].join('   |   '),
          style: const pw.TextStyle(fontSize: 9, color: cinza),
        ),
        pw.Divider(color: PdfColors.grey400),

        titulo('Resumo numérico do mês'),
        pw.Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            caixa('Registros', '${s.totalRegistros}'),
            caixa('Dias com registro', '${s.diasComRegistro} de ${s.diasNoMes}'),
            caixa('Maior sequência', '${s.maiorSequencia} dia(s)'),
            caixa('Humor médio', rotuloHumor(s.humorMedio)),
            caixa('Fotos', '${s.fotos}'),
          ],
        ),

        titulo('Humor ao longo do mês'),
        for (var i = 0; i < 5; i++)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 70,
                  child: pw.Text(rotuloHumor(i / 4),
                      style: const pw.TextStyle(fontSize: 10)),
                ),
                if (s.contagemHumores[i] > 0)
                  pw.Container(
                    width: 280 * (s.contagemHumores[i] / total),
                    height: 10,
                    color: PdfColor.fromInt(corDoHumor(i / 4).toARGB32()),
                  ),
                pw.SizedBox(width: 8),
                pw.Text('${s.contagemHumores[i]}',
                    style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),

        secaoTexto('Resumo geral', a.resumoGeral),
        secaoLista('Temas recorrentes', a.temasRecorrentes),
        secaoLista('Pontos de atenção', a.pontosDeAtencao),
        secaoTexto('Variação do humor', a.variacaoDoHumor),
        secaoTexto('Observações para o médico', a.observacoesParaOMedico),

        pw.SizedBox(height: 22),
        pw.Text(
          'Texto gerado por inteligência artificial a partir dos registros do próprio usuário. '
          'Não é diagnóstico e não substitui a avaliação de um profissional de saúde.',
          style: const pw.TextStyle(fontSize: 8.5, color: cinza),
        ),
      ],
    ),
  );

  return doc.save();
}