// lib/services/relatorio_ia_service.dart
//
// Versão que chama a API do Gemini direto (sem Firebase AI Logic).
// Os nomes das classes são os mesmos da versão anterior, então o resto do
// app não precisa mudar.
//
// A chave NÃO fica no código. Rode o app assim:
//   flutter run --dart-define=GEMINI_API_KEY=SUA_CHAVE
//
// Gere a chave em: https://aistudio.google.com/apikey

import 'dart:convert';
import 'dart:typed_data';
import '../config/segredos.dart';
import 'perfil_contexto.dart';
import 'package:http/http.dart' as http;

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
  final String? humor;
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
  // Confira em https://ai.google.dev/gemini-api/docs/models qual modelo usar.
  static const String _modelo = 'gemini-3.8-flash';
  static const String _chave = geminiApiKey;

  static Uri get _url => Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_modelo:generateContent');

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
- Se vier um bloco "Contexto informado pela própria pessoa", use-o só para
  entender melhor os relatos (ex.: o que costuma lhe fazer bem ou mal). Não
  trate esse contexto como diagnóstico nem tire conclusões clínicas dele.
''';

  static const Map<String, dynamic> _schema = {
    'type': 'OBJECT',
    'properties': {
      'resumo_geral': {
        'type': 'STRING',
        'description': 'Resumo do mês em 1 ou 2 parágrafos.'
      },
      'temas_recorrentes': {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
        'description': 'Assuntos que aparecem em vários registros.'
      },
      'pontos_de_atencao': {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
        'description': 'Fatos relevantes para o médico, com datas.'
      },
      'variacao_do_humor': {
        'type': 'STRING',
        'description': 'Como o humor variou ao longo do mês.'
      },
      'observacoes_para_o_medico': {
        'type': 'STRING',
        'description': 'Texto curto e direto dirigido ao médico.'
      },
    },
  };

  void _exigirChave() {
    if (_chave.isEmpty) {
      throw StateError(
          'Chave da IA não configurada. Rode o app com '
          '--dart-define=GEMINI_API_KEY=SUA_CHAVE');
    }
  }

  Future<Map<String, dynamic>> _chamar(Map<String, dynamic> corpo) async {
    _exigirChave();
    final resposta = await http.post(
      _url,
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': _chave,
      },
      body: jsonEncode(corpo),
    );
    if (resposta.statusCode != 200) {
      throw StateError('Erro ${resposta.statusCode} da API:\n${resposta.body}');
    }
    return jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;
  }

  String _extrairTexto(Map<String, dynamic> json) {
    final candidatos = json['candidates'] as List?;
    final partes = (candidatos?.isNotEmpty ?? false)
        ? (candidatos!.first['content']?['parts'] as List?)
        : null;
    final texto = partes?.map((p) => p['text'] ?? '').join();
    if (texto == null || texto.isEmpty) {
      throw StateError('A IA não retornou conteúdo.\n$json');
    }
    return texto;
  }

  /// Teste rápido de conexão (usado pelo botão "Testar IA").
  Future<String> testarConexao() async {
    final json = await _chamar({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': 'Diga olá em uma frase.'}
          ]
        }
      ],
    });
    return _extrairTexto(json);
  }

  /// Gera a análise de um mês. [registros] deve conter só os do mês escolhido.
  Future<RelatorioIA> gerar({
    required DateTime mes,
    required List<RegistroParaRelatorio> registros,
  }) async {
    if (registros.isEmpty) {
      throw StateError('Não há registros neste mês para gerar o relatório.');
    }

    final ordenados = [...registros]..sort((a, b) => a.data.compareTo(b.data));
    final partes = <Map<String, dynamic>>[
      {
        'text': 'Registros do diário em '
            '${mes.month.toString().padLeft(2, '0')}/${mes.year}. '
            'Cada registro começa com sua data.'
      },
    ];

    // Perfil informado pelo usuário (só vem se ele ligou "Usar no relatório").
    String? contexto;
    try {
      contexto = await PerfilContexto.texto();
    } catch (_) {}
    if (contexto != null && contexto.trim().isNotEmpty) {
      partes.add({'text': '\n$contexto'});
    }

    for (final r in ordenados) {
      final d = '${r.data.day.toString().padLeft(2, '0')}/'
          '${r.data.month.toString().padLeft(2, '0')}/${r.data.year}';
      partes.add({'text': '\n--- Registro de $d ---'});
      if (r.humor != null) partes.add({'text': 'Humor: ${r.humor}'});
      if (r.texto != null && r.texto!.trim().isNotEmpty) {
        partes.add({'text': 'Texto: ${r.texto}'});
      }
      for (final a in [...r.imagens, ...r.audios]) {
        partes.add({
          'inlineData': {
            'mimeType': a.mimeType,
            'data': base64Encode(a.bytes),
          }
        });
      }
    }

    final json = await _chamar({
      'systemInstruction': {
        'parts': [
          {'text': _instrucao}
        ]
      },
      'contents': [
        {'role': 'user', 'parts': partes}
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': _schema,
        'temperature': 0.3,
      },
    });

    return RelatorioIA.fromJson(
        jsonDecode(_extrairTexto(json)) as Map<String, dynamic>);
  }
}