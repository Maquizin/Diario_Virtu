// lib/services/bloqueio_biometrico.dart
//
// Bloqueio do app por biometria (ou PIN/senha de tela do aparelho).
// - Liga/desliga em Configurações (valor salvo no aparelho).
// - Trava ao abrir o app e ao voltar do segundo plano depois de alguns segundos.

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BloqueioBiometrico {
  static const _chave = 'bloqueio_biometrico';
  static final _auth = LocalAuthentication();

  /// O aparelho tem biometria ou PIN/senha cadastrados?
  static Future<bool> disponivel() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> ativado() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getBool(_chave) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Só liga depois de o usuário se autenticar uma vez (evita se trancar fora).
  static Future<bool> definir(bool ligar) async {
    if (ligar && !await autenticar('Confirme para ativar o bloqueio')) {
      return false;
    }
    final p = await SharedPreferences.getInstance();
    await p.setBool(_chave, ligar);
    return true;
  }

  static Future<bool> autenticar([String motivo = 'Desbloqueie o SERENIA']) async {
    try {
      // local_auth 3.x. Se o seu der erro em "persistAcrossBackgrounding",
      // use a forma antiga:
      //   options: const AuthenticationOptions(stickyAuth: true)
      return await _auth.authenticate(
        localizedReason: motivo,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      debugPrint('BIOMETRIA: $e');
      return false;
    }
  }
}

/// Envolve o app inteiro (use em MaterialApp.builder).
class PortaoBiometrico extends StatefulWidget {
  final Widget child;
  const PortaoBiometrico({super.key, required this.child});

  @override
  State<PortaoBiometrico> createState() => _PortaoBiometricoState();
}

class _PortaoBiometricoState extends State<PortaoBiometrico>
    with WidgetsBindingObserver {
  static const _tolerancia = Duration(seconds: 20);

  bool _travado = true; // começa travado até checar
  bool _checando = true; // ainda não sabemos se o bloqueio está ligado
  bool _tentando = false;
  bool _falhou = false;
  DateTime? _saiuEm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checarInicio();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checarInicio() async {
    final ligado = await BloqueioBiometrico.ativado();
    if (!mounted) return;
    setState(() => _checando = false);
    if (ligado) {
      _desbloquear();
    } else {
      setState(() => _travado = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.paused) {
      _saiuEm = DateTime.now();
    } else if (estado == AppLifecycleState.resumed) {
      final saiu = _saiuEm;
      _saiuEm = null;
      if (saiu != null && DateTime.now().difference(saiu) > _tolerancia) {
        _travarSeAtivado();
      }
    }
  }

  Future<void> _travarSeAtivado() async {
    if (await BloqueioBiometrico.ativado() && mounted) {
      setState(() => _travado = true);
      _desbloquear();
    }
  }

  Future<void> _desbloquear() async {
    if (_tentando) return;
    _tentando = true;
    if (mounted) setState(() {
      _travado = true;
      _falhou = false;
    });
    final ok = await BloqueioBiometrico.autenticar();
    _tentando = false;
    if (!mounted) return;
    setState(() {
      if (ok) _travado = false;
      _falhou = !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_travado)
          Positioned.fill(
            child: _checando
                ? const ColoredBox(color: Color(0xFF0B0B14))
                : _TelaBloqueio(
              falhou: _falhou,
              ocupado: _tentando,
              aoDesbloquear: _desbloquear,
            ),
          ),
      ],
    );
  }
}

/// Tela de bloqueio: fundo em degradê, logo que "respira" e botão de digital.
class _TelaBloqueio extends StatefulWidget {
  final bool falhou;
  final bool ocupado;
  final VoidCallback aoDesbloquear;

  const _TelaBloqueio({
    required this.falhou,
    required this.ocupado,
    required this.aoDesbloquear,
  });

  @override
  State<_TelaBloqueio> createState() => _TelaBloqueioState();
}

class _TelaBloqueioState extends State<_TelaBloqueio>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parado = MediaQuery.of(context).disableAnimations;
    if (parado) {
      _anim.stop();
    } else if (!_anim.isAnimating) {
      _anim.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme.primary;

    return RepaintBoundary(
      child: Material(
      color: const Color(0xFF0B0B14),
      child: Stack(
        children: [
          // Degradê de fundo
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.alphaBlend(cor.withValues(alpha: 0.28),
                        const Color(0xFF0B0B14)),
                    const Color(0xFF0B0B14),
                    const Color(0xFF07070D),
                  ],
                  stops: const [0, 0.55, 1],
                ),
              ),
            ),
          ),
          // Brilho suave atrás do logo
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Align(
              alignment: const Alignment(0, -0.35),
              child: Transform.scale(
                scale: 1 + 0.15 * _anim.value,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      cor.withValues(alpha: 0.30 + 0.12 * _anim.value),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                // Logo
                AnimatedBuilder(
                  animation: _anim,
                  builder: (_, child) => Transform.scale(
                      scale: 1 + 0.04 * _anim.value, child: child),
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18)),
                      boxShadow: [
                        BoxShadow(
                            color: cor.withValues(alpha: 0.45),
                            blurRadius: 36,
                            spreadRadius: 2),
                      ],
                    ),
                    child: const Icon(Icons.lock_rounded,
                        color: Colors.white, size: 46),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'SERENIA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Seu diário está protegido',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14),
                ),
                const Spacer(flex: 3),
                // Botão de desbloqueio
                GestureDetector(
                  onTap: widget.ocupado ? null : widget.aoDesbloquear,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [cor, cor.withValues(alpha: 0.6)],
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: cor.withValues(alpha: 0.5),
                            blurRadius: 24),
                      ],
                    ),
                    child: widget.ocupado
                        ? const Padding(
                            padding: EdgeInsets.all(28),
                            child: CircularProgressIndicator(
                                strokeWidth: 3, color: Colors.white),
                          )
                        : const Icon(Icons.fingerprint,
                            color: Colors.white, size: 44),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    widget.falhou
                        ? 'Não foi possível desbloquear. Toque para tentar de novo.'
                        : 'Toque para desbloquear',
                    key: ValueKey(widget.falhou),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: widget.falhou
                          ? Colors.orangeAccent
                          : Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          ),
        ],
      ),
      ),
    );
  }
}