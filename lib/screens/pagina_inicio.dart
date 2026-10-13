// lib/screens/pagina_inicio.dart
//
// Tela de início: saudação, "como você está hoje?", sequência da semana,
// resumo do mês, uma frase do dia e, mais abaixo, o calendário.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/entrada_diario.dart';
import '../services/diario_service.dart';
import '../theme/tema.dart';
import '../utils/humor_utils.dart';
import '../widgets/animacoes.dart';
import 'pagina_calendario.dart';
import 'pagina_diario.dart';

const _diasSemana = [
  'segunda-feira', 'terça-feira', 'quarta-feira', 'quinta-feira',
  'sexta-feira', 'sábado', 'domingo',
];
const _meses = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];
const _abrevSemana = ['Seg.', 'Ter.', 'Qua.', 'Qui.', 'Sex.', 'Sáb.', 'Dom.'];

const _frases = [
  'Um pequeno passo por dia já é caminho.',
  'Escrever é uma forma de cuidar de si.',
  'Não precisa ser perfeito. Só precisa ser seu.',
  'Seus sentimentos são válidos, todos eles.',
  'Respire fundo. Você está fazendo o seu melhor.',
  'Hoje é uma página nova.',
  'Observar como você se sente já é um ato de cuidado.',
  'Dias difíceis passam, e você continua escrevendo a sua história.',
  'Ser gentil consigo mesmo também é produtividade.',
  'Tudo bem não estar bem o tempo todo.',
  'Pequenas vitórias também merecem ser anotadas.',
  'Você não precisa passar por tudo sozinho.',
];

// Resposta acolhedora para cada nível de humor (0 = pior, 4 = melhor).
const _respostas = [
  'Sinto muito que o dia esteja pesado. Escrever pode aliviar um pouco. '
      'Se estiver difícil demais, conversar com alguém de confiança ou com um '
      'profissional também ajuda.',
  'Dias assim acontecem. Quer colocar em palavras o que está sentindo?',
  'Um dia no meio-termo também conta. Quer registrar como foi?',
  'Que bom! O que deixou o seu dia bom?',
  'Que alegria! Guarde esse momento no seu diário.',
];

DateTime _soDia(DateTime d) => DateTime(d.year, d.month, d.day);

class PaginaInicio extends StatefulWidget {
  const PaginaInicio({super.key});

  @override
  State<PaginaInicio> createState() => _PaginaInicioState();
}

class _PaginaInicioState extends State<PaginaInicio> {
  late final Stream<List<EntradaDiario>> _stream =
      DiarioService().streamEntradas();

  int? _humorEscolhido; // 0..4

  String? get _primeiroNome {
    final nome = FirebaseAuth.instance.currentUser?.displayName?.trim();
    if (nome == null || nome.isEmpty) return null;
    return nome.split(RegExp(r'\s+')).first;
  }

  void _escrever() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaginaDiario(dataSelecionada: _soDia(DateTime.now())),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    final hoje = _soDia(agora);

    final String saudacao;
    final IconData iconeHora;
    if (agora.hour < 12) {
      saudacao = 'Bom dia';
      iconeHora = Icons.wb_sunny_outlined;
    } else if (agora.hour < 18) {
      saudacao = 'Boa tarde';
      iconeHora = Icons.wb_twilight;
    } else {
      saudacao = 'Boa noite';
      iconeHora = Icons.nights_stay_outlined;
    }

    final nome = _primeiroNome;
    final cores = context.cores;

    return SafeArea(
      child: StreamBuilder<List<EntradaDiario>>(
        stream: _stream,
        builder: (context, snapshot) {
          final entradas = snapshot.data ?? const <EntradaDiario>[];

          // ----- cálculos -----
          final dias = entradas.map((e) => _soDia(e.data)).toSet();
          final registrouHoje = dias.contains(hoje);
          final registrosHoje =
              entradas.where((e) => _soDia(e.data) == hoje).length;

          var sequencia = 0;
          var cursor = registrouHoje ? hoje : hoje.subtract(const Duration(days: 1));
          while (dias.contains(cursor)) {
            sequencia++;
            cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
          }

          final doMes = entradas
              .where((e) => e.data.year == agora.year && e.data.month == agora.month)
              .toList();
          final diasDoMes = doMes.map((e) => _soDia(e.data)).toSet().length;
          final humorMedio = doMes.isEmpty
              ? null
              : doMes.map((e) => e.humor).reduce((a, b) => a + b) / doMes.length;

          final ultimos7 = List.generate(
              7, (i) => DateTime(hoje.year, hoje.month, hoje.day - (6 - i)));

          final diaDoAno = hoje.difference(DateTime(hoje.year)).inDays;
          final frase = _frases[diaDoAno % _frases.length];

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              // ----- saudação -----
              EntradaSuave(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$saudacao  ·  ${_diasSemana[agora.weekday - 1]}, '
                            '${agora.day} de ${_meses[agora.month - 1]}',
                            style: TextStyle(
                                color: cores.textoSecundario, fontSize: 13),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            nome == null ? 'Olá!' : 'Olá, $nome.',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Como você está hoje?',
                            style: TextStyle(color: Colors.white, fontSize: 22),
                          ),
                        ],
                      ),
                    ),
                    Pulsar(
                      intensidade: 0.06,
                      child: Icon(iconeHora, size: 44, color: cores.destaque),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // ----- humor -----
              EntradaSuave(
                delay: const Duration(milliseconds: 100),
                child: _Cartao(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var i = 0; i < 5; i++) _BotaoHumor(
                            nivel: i,
                            selecionado: _humorEscolhido == i,
                            aoTocar: () {
                              HapticFeedback.selectionClick();
                              setState(() => _humorEscolhido = i);
                            },
                          ),
                        ],
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        alignment: Alignment.topCenter,
                        child: _humorEscolhido == null
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding: const EdgeInsets.only(top: 18),
                                child: Column(
                                  children: [
                                    Text(
                                      _respostas[_humorEscolhido!],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: FilledButton.icon(
                                        onPressed: _escrever,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: cores.destaque,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14)),
                                        ),
                                        icon: const Icon(Icons.edit_outlined),
                                        label: const Text('Escrever sobre isso'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ----- hoje + semana -----
              EntradaSuave(
                delay: const Duration(milliseconds: 200),
                child: _Cartao(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_fire_department,
                              size: 40,
                              color: sequencia > 0
                                  ? Colors.orange
                                  : cores.textoSecundario),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sequencia == 0
                                      ? 'Comece sua sequência hoje'
                                      : (sequencia == 1
                                          ? '1 dia seguido'
                                          : '$sequencia dias seguidos'),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  registrouHoje
                                      ? 'Você já escreveu hoje ($registrosHoje '
                                          '${registrosHoje == 1 ? 'registro' : 'registros'})'
                                      : 'Você ainda não escreveu hoje',
                                  style: TextStyle(
                                      color: cores.textoSecundario,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final dia in ultimos7)
                            _DiaDaSemana(
                              rotulo: _abrevSemana[dia.weekday - 1],
                              numero: dia.day,
                              feito: dias.contains(dia),
                              ehHoje: dia == hoje,
                            ),
                        ],
                      ),
                      if (!registrouHoje) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton.icon(
                            onPressed: _escrever,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.25)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Escrever agora'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ----- neste mês -----
              EntradaSuave(
                delay: const Duration(milliseconds: 300),
                child: Row(
                  children: [
                    Expanded(
                      child: _MiniEstatistica(
                        valor: doMes.length,
                        rotulo: 'registros\nneste mês',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniEstatistica(
                        valor: diasDoMes,
                        rotulo: 'dias com\nregistro',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniHumor(humorMedio: humorMedio),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ----- frase do dia -----
              EntradaSuave(
                delay: const Duration(milliseconds: 400),
                child: _Cartao(
                  child: Row(
                    children: [
                      Icon(Icons.format_quote_rounded,
                          color: cores.destaque, size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          frase,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ----- calendário (é só rolar para baixo) -----
              const SizedBox(height: 32),
              Row(
                children: [
                  const Text('Calendário',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Icon(Icons.keyboard_arrow_down, color: cores.textoSecundario),
                ],
              ),
              const SizedBox(height: 14),
              const PaginaCalendario(embutido: true),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Peças
// ---------------------------------------------------------------------------
class _Cartao extends StatelessWidget {
  final Widget child;
  const _Cartao({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cores.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }
}

class _BotaoHumor extends StatelessWidget {
  final int nivel; // 0..4
  final bool selecionado;
  final VoidCallback aoTocar;
  const _BotaoHumor({
    required this.nivel,
    required this.selecionado,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final valor = nivel / 4;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: aoTocar,
      child: AnimatedScale(
        scale: selecionado ? 1.18 : 1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: corDoHumor(valor).withValues(alpha: selecionado ? 1 : 0.8),
                border: Border.all(
                  color: selecionado ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: selecionado
                    ? [
                        BoxShadow(
                          color: corDoHumor(valor).withValues(alpha: 0.55),
                          blurRadius: 14,
                        ),
                      ]
                    : const [],
              ),
              child: Icon(iconeHumor(valor), color: Colors.black87, size: 28),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 58,
              child: Text(
                rotuloHumor(valor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selecionado
                      ? Colors.white
                      : context.cores.textoSecundario,
                  fontSize: 10.5,
                  fontWeight:
                      selecionado ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiaDaSemana extends StatelessWidget {
  final String rotulo;
  final int numero;
  final bool feito, ehHoje;
  const _DiaDaSemana({
    required this.rotulo,
    required this.numero,
    required this.feito,
    required this.ehHoje,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final fundo = feito
        ? cores.destaque.withValues(alpha: 0.25)
        : (ehHoje ? cores.destaque : Colors.white.withValues(alpha: 0.08));

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(shape: BoxShape.circle, color: fundo),
          child: Icon(feito ? Icons.check : Icons.add,
              size: 17,
              color: feito
                  ? cores.destaque
                  : (ehHoje ? Colors.white : Colors.white54)),
        ),
        const SizedBox(height: 5),
        Text('$numero',
            style: TextStyle(
                color: ehHoje ? cores.destaque : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
        Text(rotulo,
            style: TextStyle(
                color: ehHoje ? cores.destaque : cores.textoSecundario,
                fontSize: 10.5)),
      ],
    );
  }
}

class _MiniEstatistica extends StatelessWidget {
  final int valor;
  final String rotulo;
  const _MiniEstatistica({required this.valor, required this.rotulo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: context.cores.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          NumeroAnimado(
            valor: valor,
            estilo: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(rotulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.cores.textoSecundario, fontSize: 11.5)),
        ],
      ),
    );
  }
}

class _MiniHumor extends StatelessWidget {
  final double? humorMedio;
  const _MiniHumor({required this.humorMedio});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final valor = humorMedio == null ? null : (humorMedio! * 4).round() / 4;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: cores.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          valor == null
              ? Icon(Icons.remove, color: cores.textoSecundario, size: 30)
              : CircleAvatar(
                  radius: 16,
                  backgroundColor: corDoHumor(valor),
                  child:
                      Icon(iconeHumor(valor), color: Colors.black87, size: 20),
                ),
          const SizedBox(height: 8),
          Text(
            valor == null ? 'humor\nmédio' : rotuloHumor(valor),
            textAlign: TextAlign.center,
            style: TextStyle(color: cores.textoSecundario, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}