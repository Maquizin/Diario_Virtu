// lib/theme/tema.dart
//
// Tudo sobre aparência do app: temas prontos, cor de destaque do usuário
// e o controlador que guarda a escolha.

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum EstiloFonte { serifa, moderna, arredondada }

TextTheme _aplicarFonte(TextTheme base, EstiloFonte f) => switch (f) {
      EstiloFonte.serifa => GoogleFonts.loraTextTheme(base),
      EstiloFonte.moderna => GoogleFonts.poppinsTextTheme(base),
      EstiloFonte.arredondada => GoogleFonts.nunitoTextTheme(base),
    };

/// Um tema completo: fundo, luzes que se movem, cartões, fonte e destaque.
class TemaApp {
  final String id;
  final String nome;
  final String descricao;
  final List<Color> fundo; // sempre 2 cores (gradiente de cima para baixo)
  final List<Color> orbes; // luzes coloridas que flutuam no fundo
  final Color card;
  final Color destaque;
  final Color texto;
  final Color textoSecundario;
  final EstiloFonte fonte;
  final bool estrelas;

  const TemaApp({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.fundo,
    required this.orbes,
    required this.card,
    required this.destaque,
    required this.fonte,
    this.texto = Colors.white,
    this.textoSecundario = const Color(0xB3FFFFFF),
    this.estrelas = false,
  });
}

const temasDisponiveis = <TemaApp>[
  TemaApp(
    id: 'noite_roxa',
    nome: 'Noite roxa',
    descricao: 'Céu estrelado',
    fundo: [Color(0xFF0B0615), Color(0xFF1B1040)],
    orbes: [Color(0xFF7C4DFF), Color(0xFFB388FF), Color(0xFF3D5AFE)],
    card: Color(0xCC1E1738),
    destaque: Color(0xFF7C4DFF),
    fonte: EstiloFonte.arredondada,
    estrelas: true,
  ),
  TemaApp(
    id: 'oceano',
    nome: 'Oceano',
    descricao: 'Águas profundas',
    fundo: [Color(0xFF03111F), Color(0xFF0A3550)],
    orbes: [Color(0xFF00B8D4), Color(0xFF2979FF), Color(0xFF1DE9B6)],
    card: Color(0xCC0B2538),
    destaque: Color(0xFF26C6DA),
    fonte: EstiloFonte.moderna,
  ),
  TemaApp(
    id: 'floresta',
    nome: 'Floresta',
    descricao: 'Verde e calmo',
    fundo: [Color(0xFF07140D), Color(0xFF123524)],
    orbes: [Color(0xFF2E7D32), Color(0xFF9CCC65), Color(0xFF00897B)],
    card: Color(0xCC12261A),
    destaque: Color(0xFF66BB6A),
    fonte: EstiloFonte.serifa,
  ),
  TemaApp(
    id: 'por_do_sol',
    nome: 'Pôr do sol',
    descricao: 'Quente e vibrante',
    fundo: [Color(0xFF1A0A18), Color(0xFF4A1942)],
    orbes: [Color(0xFFFF7043), Color(0xFFFF4081), Color(0xFFFFB74D)],
    card: Color(0xCC2E1229),
    destaque: Color(0xFFFF7043),
    fonte: EstiloFonte.serifa,
  ),
  TemaApp(
    id: 'classico',
    nome: 'Clássico',
    descricao: 'O visual atual',
    fundo: [Color(0xFF000000), Color(0xFF0C0C0E)],
    orbes: [Color(0xFF3B2A7A), Color(0xFF241A4D), Color(0xFF2C2C2E)],
    card: Color(0xFF1C1C1E),
    destaque: Color(0xFF7C4DFF),
    fonte: EstiloFonte.moderna,
  ),
];

/// Cores que o usuário pode escolher como destaque.
const coresDestaque = <Color>[
  Color(0xFF7C4DFF),
  Color(0xFF448AFF),
  Color(0xFF26C6DA),
  Color(0xFF66BB6A),
  Color(0xFFFFCA28),
  Color(0xFFFF7043),
  Color(0xFFFF4081),
  Color(0xFFE040FB),
];

/// Cores extras do tema, acessadas com `context.cores` em qualquer tela.
class AppCores extends ThemeExtension<AppCores> {
  final Color card;
  final Color cardSuave;
  final Color destaque;
  final Color textoSecundario;

  const AppCores({
    required this.card,
    required this.cardSuave,
    required this.destaque,
    required this.textoSecundario,
  });

  @override
  AppCores copyWith({
    Color? card,
    Color? cardSuave,
    Color? destaque,
    Color? textoSecundario,
  }) =>
      AppCores(
        card: card ?? this.card,
        cardSuave: cardSuave ?? this.cardSuave,
        destaque: destaque ?? this.destaque,
        textoSecundario: textoSecundario ?? this.textoSecundario,
      );

  @override
  AppCores lerp(ThemeExtension<AppCores>? other, double t) {
    if (other is! AppCores) return this;
    return AppCores(
      card: Color.lerp(card, other.card, t)!,
      cardSuave: Color.lerp(cardSuave, other.cardSuave, t)!,
      destaque: Color.lerp(destaque, other.destaque, t)!,
      textoSecundario: Color.lerp(textoSecundario, other.textoSecundario, t)!,
    );
  }
}

extension CoresDoContexto on BuildContext {
  AppCores get cores => Theme.of(this).extension<AppCores>()!;
}

/// Guarda o tema escolhido e avisa o app inteiro quando muda.
class TemaController extends ChangeNotifier {
  TemaApp _tema = temasDisponiveis.first;
  Color? _destaquePersonalizado;

  TemaApp get tema => _tema;
  Color? get destaquePersonalizado => _destaquePersonalizado;
  Color get destaque => _destaquePersonalizado ?? _tema.destaque;

  Future<void> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('tema_id');
      final cor = prefs.getInt('tema_destaque');
      _tema = temasDisponiveis.firstWhere(
        (t) => t.id == id,
        orElse: () => temasDisponiveis.first,
      );
      _destaquePersonalizado = cor == null ? null : Color(cor);
    } catch (_) {
      // se falhar, fica com o tema padrão
    }
  }

  Future<void> escolherTema(String id) async {
    _tema = temasDisponiveis.firstWhere((t) => t.id == id);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tema_id', id);
    } catch (_) {}
  }

  /// Passe `null` para voltar à cor padrão do tema.
  Future<void> escolherDestaque(Color? cor) async {
    _destaquePersonalizado = cor;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (cor == null) {
        await prefs.remove('tema_destaque');
      } else {
        await prefs.setInt('tema_destaque', cor.toARGB32());
      }
    } catch (_) {}
  }

  ThemeData get themeData {
    final d = destaque;
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: d,
        brightness: Brightness.dark,
      ).copyWith(primary: d),
    );

    return base.copyWith(
      // Transparente para o fundo animado aparecer atrás de todas as telas.
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: _aplicarFonte(base.textTheme, _tema.fonte).apply(
        bodyColor: _tema.texto,
        displayColor: _tema.texto,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _tema.texto,
        centerTitle: false,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      extensions: [
        AppCores(
          card: _tema.card,
          cardSuave: Color.alphaBlend(
              Colors.white.withValues(alpha: 0.06), _tema.card),
          destaque: d,
          textoSecundario: _tema.textoSecundario,
        ),
      ],
    );
  }
}

/// Instância única usada pelo app inteiro.
final temaController = TemaController();