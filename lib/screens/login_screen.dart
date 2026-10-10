// lib/screens/login_screen.dart
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/tema.dart';
import '../widgets/animacoes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirmar = TextEditingController();

  bool _cadastro = false; // false = entrar, true = criar conta
  bool _carregando = false;
  bool _verSenha = false;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  void _aviso(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _irParaApp() => Navigator.pushReplacementNamed(context, '/diario');

  String _erroAuth(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Já existe uma conta com esse e-mail.';
      case 'invalid-email':
        return 'Esse e-mail não é válido.';
      case 'weak-password':
        return 'Senha fraca. Use pelo menos 6 caracteres.';
      case 'network-request-failed':
        return 'Sem conexão. Verifique sua internet.';
      case 'operation-not-allowed':
        return 'Cadastro por e-mail não está ativado no Firebase.';
      default:
        return 'Não foi possível concluir (${e.code}).';
    }
  }

  // ----- ações -----
  Future<void> _entrar() async {
    final email = _email.text.trim();
    final senha = _senha.text;
    if (email.isEmpty || senha.isEmpty) {
      _aviso('Preencha e-mail e senha.');
      return;
    }

    setState(() => _carregando = true);
    try {
      final user = await AuthService().signInWithEmail(email, senha);
      if (!mounted) return;
      if (user != null) {
        _irParaApp();
      } else {
        _aviso('Não foi possível entrar. Confira seu e-mail e senha.');
      }
    } catch (_) {
      if (mounted) _aviso('Erro ao entrar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _criarConta() async {
    final nome = _nome.text.trim();
    final email = _email.text.trim();
    final senha = _senha.text;

    if (nome.isEmpty || email.isEmpty || senha.isEmpty) {
      _aviso('Preencha todos os campos.');
      return;
    }
    if (senha != _confirmar.text) {
      _aviso('As senhas não são iguais.');
      return;
    }

    setState(() => _carregando = true);
    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: senha);
      await cred.user?.updateDisplayName(nome);
      if (!mounted) return;
      _irParaApp();
    } on FirebaseAuthException catch (e) {
      if (mounted) _aviso(_erroAuth(e));
    } catch (_) {
      if (mounted) _aviso('Erro ao criar a conta. Tente novamente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _google() async {
    setState(() => _carregando = true);
    try {
      final user = await AuthService().signInWithGoogle();
      if (!mounted) return;
      if (user != null) _irParaApp();
    } catch (_) {
      if (mounted) _aviso('Erro ao entrar com o Google.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _esqueciSenha() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      _aviso('Digite seu e-mail para receber o link de redefinição.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) _aviso('Enviamos um link de redefinição para $email.');
    } on FirebaseAuthException catch (e) {
      if (mounted) _aviso(_erroAuth(e));
    }
  }

  void _alternarModo() {
    setState(() {
      _cadastro = !_cadastro;
      _confirmar.clear();
    });
  }

  // ----- UI -----
  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    return Scaffold(
      // Fundo transparente: o fundo animado do app aparece atrás.
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EntradaSuave(
                    child: Column(
                      children: [
                        const Text(
                          'SERENIA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            letterSpacing: 6,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Seu espaço para sentir e registrar',
                          style: TextStyle(color: cores.textoSecundario),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  EntradaSuave(
                    delay: const Duration(milliseconds: 150),
                    child: _CartaoVidro(child: _conteudoCartao(cores)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _conteudoCartao(AppCores cores) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _cadastro ? 'Criar conta' : 'Entrar',
                key: ValueKey(_cadastro),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: _carregando ? null : _alternarModo,
              child: Text(
                _cadastro ? 'Já tenho conta' : 'Criar conta',
                style: TextStyle(
                  color: cores.destaque,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Os campos extras do cadastro aparecem com animação.
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_cadastro) ...[
                _campo(
                  controller: _nome,
                  dica: 'Seu nome',
                  icone: Icons.person_outline,
                  tipo: TextInputType.name,
                ),
                const SizedBox(height: 14),
              ],
              _campo(
                controller: _email,
                dica: 'E-mail',
                icone: Icons.alternate_email,
                tipo: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _campo(
                controller: _senha,
                dica: 'Senha',
                icone: Icons.key_outlined,
                senha: true,
                sufixo: IconButton(
                  onPressed: () => setState(() => _verSenha = !_verSenha),
                  icon: Icon(
                    _verSenha
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: cores.textoSecundario,
                  ),
                ),
              ),
              if (_cadastro) ...[
                const SizedBox(height: 14),
                _campo(
                  controller: _confirmar,
                  dica: 'Confirmar senha',
                  icone: Icons.lock_outline,
                  senha: true,
                ),
              ],
            ],
          ),
        ),

        if (!_cadastro)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _carregando ? null : _esqueciSenha,
              child: Text('Esqueci a senha',
                  style: TextStyle(color: cores.textoSecundario)),
            ),
          )
        else
          const SizedBox(height: 14),

        const SizedBox(height: 6),
        _botaoPrincipal(cores),
        const SizedBox(height: 22),

        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.18))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('ou continue com',
                  style: TextStyle(color: cores.textoSecundario, fontSize: 13)),
            ),
            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.18))),
          ],
        ),
        const SizedBox(height: 18),

        SizedBox(
          height: 54,
          child: OutlinedButton(
            onPressed: _carregando ? null : _google,
            style: OutlinedButton.styleFrom(
              shape: const StadiumBorder(),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
              foregroundColor: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/google.png', width: 22),
                const SizedBox(width: 12),
                const Text('Continuar com o Google',
                    style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _botaoPrincipal(AppCores cores) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: cores.destaque.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: _carregando ? null : (_cadastro ? _criarConta : _entrar),
        style: FilledButton.styleFrom(
          backgroundColor: cores.destaque,
          disabledBackgroundColor: cores.destaque.withValues(alpha: 0.6),
          shape: const StadiumBorder(),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _carregando
              ? const SizedBox(
                  key: ValueKey('carregando'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  _cadastro ? 'Criar conta' : 'Entrar',
                  key: ValueKey(_cadastro),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String dica,
    required IconData icone,
    bool senha = false,
    TextInputType? tipo,
    Widget? sufixo,
  }) {
    final cores = context.cores;
    OutlineInputBorder borda(Color cor, [double largura = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: cor, width: largura),
        );

    return TextField(
      controller: controller,
      obscureText: senha && !_verSenha,
      keyboardType: tipo,
      autocorrect: false,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: dica,
        hintStyle:
            TextStyle(color: cores.textoSecundario.withValues(alpha: 0.7)),
        prefixIcon: Icon(icone, color: cores.destaque),
        suffixIcon: sufixo,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: borda(Colors.white.withValues(alpha: 0.14)),
        enabledBorder: borda(Colors.white.withValues(alpha: 0.14)),
        focusedBorder: borda(cores.destaque, 1.6),
      ),
    );
  }
}

/// Cartão de "vidro fosco": desfoca o fundo animado que passa por trás.
class _CartaoVidro extends StatelessWidget {
  final Widget child;
  const _CartaoVidro({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: child,
        ),
      ),
    );
  }
}