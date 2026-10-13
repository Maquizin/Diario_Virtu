// lib/screens/tela_privacidade_seguranca.dart
//
// Agrupa tudo o que protege o usuário: privacidade (o que o psicólogo vê)
// e bloqueio por biometria.

import 'package:flutter/material.dart';

import '../services/bloqueio_biometrico.dart';
import '../theme/tema.dart';
import 'privacidade_screen.dart';

class TelaPrivacidadeSeguranca extends StatefulWidget {
  const TelaPrivacidadeSeguranca({super.key});

  @override
  State<TelaPrivacidadeSeguranca> createState() =>
      _TelaPrivacidadeSegurancaState();
}

class _TelaPrivacidadeSegurancaState extends State<TelaPrivacidadeSeguranca> {
  bool _biometria = false;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    BloqueioBiometrico.ativado().then((v) {
      if (mounted) setState(() {
            _biometria = v;
            _carregando = false;
          });
    });
  }

  Future<void> _alternar(bool ligar) async {
    if (ligar && !await BloqueioBiometrico.disponivel()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Cadastre uma biometria, PIN ou senha no aparelho primeiro.')));
      return;
    }
    final ok = await BloqueioBiometrico.definir(ligar);
    if (ok && mounted) setState(() => _biometria = ligar);
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;

    Widget cartao(Widget filho) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: cores.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: filho,
        );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Privacidade e segurança'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          cartao(ListTile(
            leading: const Icon(Icons.lock_outline, color: Colors.purpleAccent),
            title: const Text('Privacidade',
                style: TextStyle(color: Colors.white)),
            subtitle: Text('Controle o que o psicólogo pode acessar',
                style: TextStyle(color: cores.textoSecundario)),
            trailing:
                Icon(Icons.chevron_right, color: cores.textoSecundario),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacidadeScreen()),
            ),
          )),
          cartao(SwitchListTile(
            secondary:
                const Icon(Icons.fingerprint, color: Colors.greenAccent),
            title: const Text('Bloqueio por biometria',
                style: TextStyle(color: Colors.white)),
            subtitle: Text(
                'Pede digital, rosto ou senha do aparelho ao abrir o app',
                style: TextStyle(color: cores.textoSecundario)),
            value: _biometria,
            onChanged: _carregando ? null : _alternar,
          )),
          const SizedBox(height: 6),
          Text(
            'Seus registros ficam na sua conta e só você os acessa. '
            'Para exportar ou apagar seus dados, use "Sobre mim".',
            style: TextStyle(color: cores.textoSecundario, height: 1.4),
          ),
        ],
      ),
    );
  }
}