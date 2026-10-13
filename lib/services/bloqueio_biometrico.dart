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
  bool _tentando = false;
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
    if (await BloqueioBiometrico.ativado()) {
      _desbloquear();
    } else if (mounted) {
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
    if (mounted) setState(() => _travado = true);
    final ok = await BloqueioBiometrico.autenticar();
    _tentando = false;
    if (ok && mounted) setState(() => _travado = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_travado)
          Positioned.fill(
            child: Material(
              color: const Color(0xFF0B0B14),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_rounded, color: Colors.white70, size: 56),
                    const SizedBox(height: 16),
                    const Text('SERENIA bloqueado',
                        style: TextStyle(color: Colors.white, fontSize: 20)),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _desbloquear,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Desbloquear'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}