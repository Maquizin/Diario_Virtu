// lib/screens/tela_desenvolvedor.dart
//
// "Sobre o desenvolvedor": apresentação + contato, com fundo em parallax,
// terminal digitando sozinho, cartões expansíveis, trecho de código colorido
// e linha do tempo do projeto.
//
// Para editar os textos, mexa nas constantes e listas logo abaixo.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/tema.dart';
import '../widgets/animacoes.dart';

// ---------------------------------------------------------------------------
// TEXTOS (edite à vontade)
// ---------------------------------------------------------------------------
const _nome = 'Max Pierre da Silva Rodrigues';
const _email = 'mrodrigues@alu.paulinia.sp.gov.br';
const _linkedin = 'https://www.linkedin.com/in/maxpierres';

const _bio =
    'Sou aluno do curso Técnico em Informática no CEMEP, em Paulínia-SP. '
    'O SERENIA é o meu TCC: um diário virtual com inteligência artificial '
    'que ajuda a acompanhar o humor no dia a dia e gera um relatório mensal '
    'para apoiar a conversa com profissionais de saúde.\n\n'
    'Projetei e programei o app inteiro, do login ao relatório em PDF, '
    'e gosto de transformar uma ideia em algo que as pessoas realmente usam.';

const _tecnologias = [
  'Flutter', 'Dart', 'Firebase Auth', 'Cloud Firestore', 'Google Sign-In',
  'Gemini API (IA)', 'JSON estruturado', 'REST / HTTP', 'Streams',
  'CustomPainter', 'Animações', 'Temas (ThemeExtension)', 'PDF',
  'Notificações locais', 'Fila com retry',
];

class _Topico {
  final IconData icone;
  final String titulo;
  final String resumo;
  final String detalhe;
  const _Topico(this.icone, this.titulo, this.resumo, this.detalhe);
}

const _topicos = [
  _Topico(
    Icons.palette_outlined,
    'Interface e animações',
    'Temas, fundo animado e gráficos desenhados à mão',
    'Cinco temas com cor de destaque escolhida pelo usuário, fundo com luzes '
        'em movimento, números que contam até o valor e o semicírculo de '
        'humor desenhado com CustomPainter. As cores ficam em uma '
        'ThemeExtension, então qualquer tela muda de tema sem código extra.',
  ),
  _Topico(
    Icons.verified_user_outlined,
    'Contas e login',
    'Firebase Authentication com e-mail/senha e Google',
    'Um AuthGate observa o estado de login e decide qual tela mostrar. Os '
        'dados de cada pessoa ficam separados no banco, em usuarios/{uid}.',
  ),
  _Topico(
    Icons.cloud_sync_outlined,
    'Banco de dados em tempo real',
    'Cloud Firestore com streams',
    'Os registros ficam em usuarios/{uid}/entradas. As telas escutam streams: '
        'ao salvar um registro, o calendário, o histórico e a tela de início '
        'se atualizam sozinhos.',
  ),
  _Topico(
    Icons.auto_awesome,
    'Relatório com IA',
    'O Gemini resume o mês para o profissional de saúde',
    'O app envia os registros do mês e pede uma resposta em JSON com um '
        'schema fixo: resumo, temas recorrentes, pontos de atenção, variação '
        'do humor e observações. É um apoio à conversa, nunca um diagnóstico.',
  ),
  _Topico(
    Icons.hourglass_bottom_rounded,
    'Geração em segundo plano',
    'Fila com retry e backoff exponencial',
    'Se a IA estiver ocupada ou sem internet, o app tenta de novo esperando '
        'cada vez mais (5s, 15s, 30s...). Cada tentativa tem limite de 3 '
        'minutos, a fila é salva no aparelho, dá para cancelar e, quando '
        'termina, chega uma notificação.',
  ),
  _Topico(
    Icons.picture_as_pdf_outlined,
    'PDF e compartilhamento',
    'O relatório vira PDF na hora',
    'O PDF é montado com os números do mês e o texto da IA e enviado pelo '
        'compartilhamento do celular, pronto para levar à consulta.',
  ),
];

const _etapas = [
  ('A ideia', 'Um diário virtual que ajuda a cuidar da saúde mental.'),
  ('A base', 'Login, diário e histórico com Firebase.'),
  ('Visão geral', 'Calendário, estatísticas e sequência de dias.'),
  ('Inteligência', 'Relatório mensal gerado por IA, salvo e em PDF.'),
  ('Experiência', 'Temas, animações e tela de início acolhedora.'),
  ('Próximos passos', 'Fotos, áudio, bloqueio biométrico e lembretes.'),
];

const _trechoCodigo = r'''// Tenta de novo, esperando cada vez mais
const atrasos = [5, 15, 30, 60, 120, 300];

while (!tarefa.cancelada) {
  try {
    final pronto = await gerarRelatorio()
        .timeout(Duration(minutes: 3));
    return avisar(pronto);
  } catch (erro) {
    final seg = atrasos[min(tentativa, 5)];
    await Future.delayed(Duration(seconds: seg));
  }
}''';

// ---------------------------------------------------------------------------
// TELA
// ---------------------------------------------------------------------------
class TelaDesenvolvedor extends StatefulWidget {
  const TelaDesenvolvedor({super.key});

  @override
  State<TelaDesenvolvedor> createState() => _TelaDesenvolvedorState();
}

class _TelaDesenvolvedorState extends State<TelaDesenvolvedor> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _aviso(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _abrir(Uri uri, String textoParaCopiar) async {
    HapticFeedback.lightImpact();
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok) {
      await Clipboard.setData(ClipboardData(text: textoParaCopiar));
      if (mounted) _aviso('Não consegui abrir. Copiei para você: $textoParaCopiar');
    }
  }

  Future<void> _copiar(String texto, String rotulo) async {
    HapticFeedback.selectionClick();
    await Clipboard.setData(ClipboardData(text: texto));
    if (mounted) _aviso('$rotulo copiado.');
  }

  @override
  Widget build(BuildContext context) {
    final tela = MediaQuery.sizeOf(context);
    final cores = context.cores;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Desenvolvedor'),
      ),
      body: Stack(
        children: [
          // ----- fundo com parallax (anda mais devagar que o conteúdo) -----
          Positioned.fill(
            child: ListenableBuilder(
              listenable: _scroll,
              builder: (context, _) {
                final off = _scroll.hasClients ? _scroll.offset : 0.0;
                final deslocamento = math.min(off * 0.25, tela.height * 0.1);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Transform.translate(
                      offset: Offset(0, -deslocamento),
                      child: Transform.scale(
                        scale: 1.2,
                        child: Image.asset(
                          'assets/29.png',
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.25),
                            Colors.black.withValues(alpha: 0.65),
                            Colors.black.withValues(alpha: 0.92),
                          ],
                          stops: const [0, 0.45, 1],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ----- conteúdo -----
          ListView(
            controller: _scroll,
            padding: EdgeInsets.fromLTRB(20, 0, 20, 40 + MediaQuery.paddingOf(context).bottom),
            children: [
              // Espaço para a imagem aparecer, com o nome por cima.
              SizedBox(
                height: tela.height * 0.30,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: EntradaSuave(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DESENVOLVEDOR DO SERENIA',
                            style: TextStyle(
                                color: cores.destaque,
                                fontSize: 12,
                                letterSpacing: 2,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text(
                          _nome,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(blurRadius: 12, color: Colors.black)],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              EntradaSuave(child: const _Terminal()),
              const SizedBox(height: 16),

              EntradaSuave(
                child: _Vidro(
                  titulo: 'Sobre mim',
                  icone: Icons.person_outline,
                  child: const Text(
                    _bio,
                    style: TextStyle(
                        color: Colors.white, fontSize: 14.5, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              EntradaSuave(
                child: _Vidro(
                  titulo: 'Tecnologias usadas no app',
                  icone: Icons.layers_outlined,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < _tecnologias.length; i++)
                        EntradaSuave(
                          delay: Duration(milliseconds: 60 * i),
                          child: _Pilula(_tecnologias[i]),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              EntradaSuave(
                child: _Vidro(
                  titulo: 'Por dentro do SERENIA',
                  icone: Icons.settings_suggest_outlined,
                  subtitulo: 'Toque para ver como cada parte funciona.',
                  child: Column(
                    children: [
                      for (final t in _topicos) _CartaoExpansivel(topico: t),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              EntradaSuave(
                child: _Vidro(
                  titulo: 'Um trecho do código',
                  icone: Icons.terminal_rounded,
                  subtitulo: 'A lógica de tentar de novo, simplificada.',
                  child: const _BlocoCodigo(_trechoCodigo),
                ),
              ),
              const SizedBox(height: 16),

              EntradaSuave(
                child: _Vidro(
                  titulo: 'Etapas do projeto',
                  icone: Icons.timeline_rounded,
                  child: Column(
                    children: [
                      for (var i = 0; i < _etapas.length; i++)
                        _ItemLinhaDoTempo(
                          titulo: _etapas[i].$1,
                          texto: _etapas[i].$2,
                          primeiro: i == 0,
                          ultimo: i == _etapas.length - 1,
                          futuro: i == _etapas.length - 1,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              EntradaSuave(
                child: _Vidro(
                  titulo: 'Vamos conversar?',
                  icone: Icons.mail_outline,
                  subtitulo: 'Contato profissional',
                  child: Column(
                    children: [
                      _BotaoContato(
                        icone: Icons.alternate_email,
                        rotulo: 'E-mail',
                        valor: _email,
                        aoAbrir: () => _abrir(
                          Uri(
                            scheme: 'mailto',
                            path: _email,
                            queryParameters: {'subject': 'Contato pelo SERENIA'},
                          ),
                          _email,
                        ),
                        aoCopiar: () => _copiar(_email, 'E-mail'),
                      ),
                      const SizedBox(height: 10),
                      _BotaoContato(
                        icone: Icons.work_outline,
                        rotulo: 'LinkedIn',
                        valor: 'linkedin.com/in/maxpierres',
                        aoAbrir: () => _abrir(Uri.parse(_linkedin), _linkedin),
                        aoCopiar: () => _copiar(_linkedin, 'Link'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Center(
                child: Text(
                  'Feito com Flutter · SERENIA · TCC CEMEP Paulínia',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cores.textoSecundario, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cartão de vidro (fundo desfocado)
// ---------------------------------------------------------------------------
class _Vidro extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final IconData icone;
  final Widget child;

  const _Vidro({
    required this.titulo,
    required this.icone,
    required this.child,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icone, color: cores.destaque, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(titulo,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              if (subtitulo != null) ...[
                const SizedBox(height: 4),
                Text(subtitulo!,
                    style: TextStyle(color: cores.textoSecundario, fontSize: 12.5)),
              ],
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _Pilula extends StatelessWidget {
  final String texto;
  const _Pilula(this.texto);

  @override
  Widget build(BuildContext context) {
    final d = context.cores.destaque;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: d.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: d.withValues(alpha: 0.45)),
      ),
      child: Text(texto,
          style: const TextStyle(color: Colors.white, fontSize: 12.5)),
    );
  }
}

// ---------------------------------------------------------------------------
// Terminal que digita sozinho
// ---------------------------------------------------------------------------
class _LinhaTerminal {
  final String texto;
  final bool comando;
  const _LinhaTerminal(this.texto, {this.comando = false});
}

class _Terminal extends StatefulWidget {
  const _Terminal();

  @override
  State<_Terminal> createState() => _TerminalState();
}

class _TerminalState extends State<_Terminal>
    with SingleTickerProviderStateMixin {
  static const _linhas = [
    _LinhaTerminal('whoami', comando: true),
    _LinhaTerminal('Max Pierre, desenvolvedor'),
    _LinhaTerminal('cat formacao.txt', comando: true),
    _LinhaTerminal('Técnico em Informática · CEMEP Paulínia-SP'),
    _LinhaTerminal('./serenia --sobre', comando: true),
    _LinhaTerminal('Diário virtual com IA para cuidar da saúde mental'),
  ];

  late final AnimationController _cursor = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  )..repeat(reverse: true);

  Timer? _timer;
  int _linha = 0; // linha sendo mostrada
  int _letra = 0; // letras já digitadas (só para comandos)
  int _espera = 8; // pausa inicial

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 40), (_) => _passo());
  }

  void _passo() {
    if (!mounted) return;
    if (_linha >= _linhas.length) {
      _timer?.cancel();
      return;
    }
    if (_espera > 0) {
      _espera--;
      return;
    }
    setState(() {
      final atual = _linhas[_linha];
      if (atual.comando) {
        _letra++;
        if (_letra >= atual.texto.length) {
          _linha++;
          _letra = 0;
          _espera = 9; // "pensa" antes de mostrar a resposta
        }
      } else {
        _linha++;
        _letra = 0;
        _espera = 6;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cursor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const verde = Color(0xFF7EE787);
    final linhas = <Widget>[];

    for (var i = 0; i <= _linha && i < _linhas.length; i++) {
      final l = _linhas[i];
      final texto = (i == _linha && l.comando)
          ? l.texto.substring(0, _letra.clamp(0, l.texto.length))
          : l.texto;
      // Linhas ainda não "chegadas" (resposta aguardando) não aparecem.
      if (i == _linha && !l.comando) continue;

      linhas.add(Text.rich(
        TextSpan(children: [
          if (l.comando)
            const TextSpan(
                text: r'$ ',
                style: TextStyle(color: verde, fontWeight: FontWeight.bold)),
          TextSpan(
            text: texto,
            style: TextStyle(color: l.comando ? Colors.white : Colors.white70),
          ),
        ]),
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.6),
      ));
    }

    // Cursor piscando no fim.
    linhas.add(FadeTransition(
      opacity: _cursor,
      child: const Text('█',
          style: TextStyle(color: verde, fontFamily: 'monospace', fontSize: 13)),
    ));

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 170),
        decoration: BoxDecoration(
          color: const Color(0xE60D1117),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // barra de título com os 3 "botões" do macOS
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: Colors.white.withValues(alpha: 0.05),
              child: Row(
                children: [
                  for (final c in const [
                    Color(0xFFFF5F56),
                    Color(0xFFFFBD2E),
                    Color(0xFF27C93F),
                  ])
                    Container(
                      width: 11,
                      height: 11,
                      margin: const EdgeInsets.only(right: 7),
                      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                    ),
                  const SizedBox(width: 6),
                  const Text('serenia — terminal',
                      style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11.5,
                          fontFamily: 'monospace')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: linhas,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cartão que abre e fecha
// ---------------------------------------------------------------------------
class _CartaoExpansivel extends StatefulWidget {
  final _Topico topico;
  const _CartaoExpansivel({required this.topico});

  @override
  State<_CartaoExpansivel> createState() => _CartaoExpansivelState();
}

class _CartaoExpansivelState extends State<_CartaoExpansivel> {
  bool _aberto = false;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final t = widget.topico;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _aberto = !_aberto);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _aberto ? 0.10 : 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _aberto
                ? cores.destaque.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(t.icone, color: cores.destaque, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.titulo,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(t.resumo,
                          style: TextStyle(
                              color: cores.textoSecundario, fontSize: 12.5)),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _aberto ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(Icons.keyboard_arrow_down,
                      color: cores.textoSecundario),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _aberto
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(t.detalhe,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13.5, height: 1.5)),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trecho de código com cores (feito à mão, sem pacote)
// ---------------------------------------------------------------------------
class _BlocoCodigo extends StatelessWidget {
  final String codigo;
  const _BlocoCodigo(this.codigo);

  static const _comentario = Color(0xFF8B949E);
  static const _texto = Color(0xFFC9D1D9);
  static const _palavra = Color(0xFFFF7B72);
  static const _numero = Color(0xFF79C0FF);

  List<InlineSpan> _colorir() {
    final re = RegExp(
      r'(//[^\n]*)|\b(final|const|while|try|catch|await|return|async|if|else)\b|\b(\d+)\b',
    );
    final spans = <InlineSpan>[];
    var pos = 0;
    for (final m in re.allMatches(codigo)) {
      if (m.start > pos) {
        spans.add(TextSpan(text: codigo.substring(pos, m.start)));
      }
      final Color cor;
      if (m.group(1) != null) {
        cor = _comentario;
      } else if (m.group(2) != null) {
        cor = _palavra;
      } else {
        cor = _numero;
      }
      spans.add(TextSpan(text: m[0], style: TextStyle(color: cor)));
      pos = m.end;
    }
    if (pos < codigo.length) spans.add(TextSpan(text: codigo.substring(pos)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text.rich(
          TextSpan(children: _colorir()),
          style: const TextStyle(
            color: _texto,
            fontFamily: 'monospace',
            fontSize: 12.5,
            height: 1.55,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Linha do tempo
// ---------------------------------------------------------------------------
class _ItemLinhaDoTempo extends StatelessWidget {
  final String titulo;
  final String texto;
  final bool primeiro, ultimo, futuro;

  const _ItemLinhaDoTempo({
    required this.titulo,
    required this.texto,
    required this.primeiro,
    required this.ultimo,
    required this.futuro,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final d = cores.destaque;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 6,
                  color: primeiro ? Colors.transparent : d.withValues(alpha: 0.4),
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: futuro ? Colors.transparent : d,
                    border: Border.all(color: d, width: 2),
                    boxShadow: futuro
                        ? const []
                        : [BoxShadow(color: d.withValues(alpha: 0.5), blurRadius: 8)],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: ultimo ? Colors.transparent : d.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(texto,
                      style: TextStyle(
                          color: cores.textoSecundario, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Botão de contato (toque abre; ícone copia)
// ---------------------------------------------------------------------------
class _BotaoContato extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final String valor;
  final VoidCallback aoAbrir;
  final VoidCallback aoCopiar;

  const _BotaoContato({
    required this.icone,
    required this.rotulo,
    required this.valor,
    required this.aoAbrir,
    required this.aoCopiar,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Material(
      color: cores.destaque.withValues(alpha: 0.20),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: aoAbrir,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cores.destaque.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(icone, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rotulo,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    Text(valor,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: cores.textoSecundario, fontSize: 12.5)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Copiar',
                onPressed: aoCopiar,
                icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}