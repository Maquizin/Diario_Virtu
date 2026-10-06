// lib/servicos/relatorio_ia_service.dart
//
// Serviço que envia os registros de um mês para o Gemini (via Firebase AI Logic)
// e devolve uma análise estruturada para ser colocada no PDF do médico.
//
// Ele NÃO depende das suas classes: você converte seus registros para
// [RegistroParaRelatorio] antes de chamar o serviço.

import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_ai/firebase_ai.dart';

/// Arquivo anexado a um registro (foto ou áudio) já baixado em memória.
class Anexo {
  final Uint8List bytes;

  /// Ex.: 'image/jpeg', 'image/png', 'audio/mp4' (m4a), 'audio/mpeg' (mp3), 'audio/wav'
  final String mimeType;

  const Anexo(this.bytes, this.mimeType);
}

/// Um registro do diário, no formato que a IA precisa.
class RegistroParaRelatorio {
  final DateTime data;
  final String? humor; // nome do humor, ex.: "Feliz", "Triste"
  final String? texto;
  final List<Anexo> imagens;
  final List<Anexo> audios;

  const RegistroParaRelatorio({
    required this.data,
    this.humor,
    this.texto,
    this.imagens = const [],
    this.audios = const [],
  });
}

/// Resultado da análise da IA.
class RelatorioIA {
  final String resumoGeral;
  final List<String> temasRecorrentes;
  final List<String> pontosDeAtencao;
  final String variacaoDoHumor;
  final String observacoesParaOMedico;

  const RelatorioIA({
    required this.resumoGeral,
    required this.temasRecorrentes,
    required this.pontosDeAtencao,
    required this.variacaoDoHumor,
    required this.observacoesParaOMedico,
  });

  factory RelatorioIA.fromJson(Map<String, dynamic> json) {
    List<String> lista(dynamic v) =>
        (v as List? ?? const []).map((e) => e.toString()).toList();

    return RelatorioIA(
      resumoGeral: (json['resumo_geral'] ?? '').toString(),
      temasRecorrentes: lista(json['temas_recorrentes']),
      pontosDeAtencao: lista(json['pontos_de_atencao']),
      variacaoDoHumor: (json['variacao_do_humor'] ?? '').toString(),
      observacoesParaOMedico: (json['observacoes_para_o_medico'] ?? '').toString(),
    );
  }
}

class RelatorioIAService {
  // Confira no console do Firebase qual modelo Gemini está disponível para você.
  static const String _modelo = 'gemini-2.5-flash';

  static const String _instrucao = '''
Você é um assistente que organiza os relatos de um diário pessoal para que o
usuário os leve a uma consulta com seu médico.

Regras:
- Leia TODOS os registros (textos, imagens e áudios) e encontre padrões:
  temas que se repetem, situações que aparecem várias vezes, mudanças ao longo
  do mês e dias fora do comum.
- Seja descritivo e neutro. Descreva o que o usuário relatou; NÃO faça
  diagnósticos, NÃO sugira medicamentos e NÃO dê conselhos clínicos.
- Cite as datas (dd/mm) quando apontar algo importante.
- Se houver pouco conteúdo, diga isso em vez de inventar padrões.
- Escreva em português do Brasil, em linguagem clara.
''';

  late final GenerativeModel _model = FirebaseAI.googleAI().generativeModel(
    model: _modelo,
    systemInstruction: Content.system(_instrucao),
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
      temperature: 0.3,
      responseSchema: Schema.object(
        properties: {
          'resumo_geral': Schema.string(
              description: 'Resumo do mês em 1 ou 2 parágrafos.'),
          'temas_recorrentes': Schema.array(
              items: Schema.string(),
              description: 'Assuntos que aparecem em vários registros.'),
          'pontos_de_atencao': Schema.array(
              items: Schema.string(),
              description: 'Fatos relevantes para o médico, com datas.'),
          'variacao_do_humor': Schema.string(
              description: 'Como o humor variou ao longo do mês.'),
          'observacoes_para_o_medico': Schema.string(
              description: 'Texto curto e direto dirigido ao médico.'),
        },
      ),
    ),
  );

  /// Gera a análise de um mês. [registros] deve conter só os do mês escolhido.
  Future<RelatorioIA> gerar({
    required DateTime mes,
    required List<RegistroParaRelatorio> registros,
  }) async {
    if (registros.isEmpty) {
      throw StateError('Não há registros neste mês para gerar o relatório.');
    }

    final ordenados = [...registros]..sort((a, b) => a.data.compareTo(b.data));
    final partes = <Part>[
      TextPart('Registros do diário em ${mes.month.toString().padLeft(2, '0')}/${mes.year}. '
          'Cada registro começa com sua data.'),
    ];

    for (final r in ordenados) {
      final d = '${r.data.day.toString().padLeft(2, '0')}/'
          '${r.data.month.toString().padLeft(2, '0')}/${r.data.year}';
      partes.add(TextPart('\n--- Registro de $d ---'));
      if (r.humor != null) partes.add(TextPart('Humor: ${r.humor}'));
      if (r.texto != null && r.texto!.trim().isNotEmpty) {
        partes.add(TextPart('Texto: ${r.texto}'));
      }
      for (final img in r.imagens) {
        partes.add(InlineDataPart(img.mimeType, img.bytes));
      }
      for (final aud in r.audios) {
        partes.add(InlineDataPart(aud.mimeType, aud.bytes));
      }
    }

    final resposta = await _model.generateContent([Content.multi(partes)]);
    final texto = resposta.text;
    if (texto == null || texto.isEmpty) {
      throw StateError('A IA não retornou conteúdo.');
    }
    return RelatorioIA.fromJson(jsonDecode(texto) as Map<String, dynamic>);
  }
}