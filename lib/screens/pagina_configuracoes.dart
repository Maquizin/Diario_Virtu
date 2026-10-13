// lib/screens/pagina_configuracoes.dart
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import '../services/perfil_service.dart';
import '../theme/tema.dart';
import '../widgets/animacoes.dart';
import 'acessibilidade_screen.dart';
import 'login_screen.dart';
import 'tela_ajuda.dart';
import 'tela_debug.dart';
import 'tela_desenvolvedor.dart';
import 'tela_privacidade_seguranca.dart';
import 'tela_relatorios.dart';
import 'tela_sobre_mim.dart';

class PaginaConfiguracoes extends StatelessWidget {
  const PaginaConfiguracoes({super.key});

  Future<void> _sair(BuildContext context) async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    }
  }

  void _push(BuildContext context, Widget tela) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => tela));

  /// Menu para trocar foto ou banner.
  Future<void> _editarImagem(BuildContext context, {required bool banner}) async {
    final acao = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(ctx, 'galeria'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar uma foto'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(banner ? 'Remover banner' : 'Remover foto'),
              onTap: () => Navigator.pop(ctx, 'remover'),
            ),
          ],
        ),
      ),
    );
    if (acao == null) return;
    try {
      if (acao == 'remover') {
        await PerfilService.remover(banner: banner);
      } else {
        await PerfilService.escolher(
          banner: banner,
          origem: acao == 'camera' ? ImageSource.camera : ImageSource.gallery,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Não consegui: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const Text(
            'Configurações',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          StreamBuilder<Map<String, dynamic>>(
            stream: PerfilService.stream(),
            builder: (context, snap) {
              final dados = snap.data;
              return _cabecalho(
                context,
                user: user,
                banner: PerfilService.imagem(dados, 'banner'),
                foto: PerfilService.imagem(dados, 'foto'),
              );
            },
          ),

          const SizedBox(height: 28),

          _opcaoConfig(
            context,
            ordem: 1,
            icone: Icons.person_outline,
            cor: Colors.pinkAccent,
            titulo: 'Sobre mim',
            subtitulo: 'Seus dados, exportar e excluir',
            onTap: () => _push(context, const TelaSobreMim()),
          ),
          _opcaoConfig(
            context,
            ordem: 2,
            icone: Icons.shield_outlined,
            cor: Colors.purpleAccent,
            titulo: 'Privacidade e segurança',
            subtitulo: 'Acesso do psicólogo e bloqueio por biometria',
            onTap: () => _push(context, const TelaPrivacidadeSeguranca()),
          ),
          _opcaoConfig(
            context,
            ordem: 3,
            icone: Icons.palette_outlined,
            cor: context.cores.destaque,
            titulo: 'Aparência',
            subtitulo: 'Temas, cores e fundo animado',
            onTap: () => Navigator.pushNamed(context, '/aparencia'),
          ),
          _opcaoConfig(
            context,
            ordem: 4,
            icone: Icons.description_outlined,
            cor: Colors.tealAccent,
            titulo: 'Meus relatórios',
            subtitulo: 'Relatórios mensais salvos',
            onTap: () => _push(context, const TelaRelatorios()),
          ),
          _opcaoConfig(
            context,
            ordem: 5,
            icone: Icons.accessibility_new,
            cor: Colors.blueAccent,
            titulo: 'Acessibilidade',
            subtitulo: 'Texto, contraste e mais',
            onTap: () => _push(context, const AcessibilidadeScreen()),
          ),
          _opcaoConfig(
            context,
            ordem: 6,
            icone: Icons.sos_rounded,
            cor: Colors.redAccent,
            titulo: 'Preciso de ajuda',
            subtitulo: 'CVV 188 e SAMU 192',
            onTap: () => _push(context, const TelaAjuda()),
          ),
          _opcaoConfig(
            context,
            ordem: 7,
            icone: Icons.code_rounded,
            cor: Colors.cyanAccent,
            titulo: 'Sobre o desenvolvedor',
            subtitulo: 'Quem fez o SERENIA e como entrar em contato',
            onTap: () => _push(context, const TelaDesenvolvedor()),
          ),
          _opcaoConfig(
            context,
            ordem: 8,
            icone: Icons.logout,
            cor: Colors.redAccent,
            titulo: 'Sair da conta',
            subtitulo: 'Encerrar sessão',
            onTap: () => _sair(context),
          ),

          // Só aparece quando o app roda em modo debug.
          if (kDebugMode)
            _opcaoConfig(
              context,
              ordem: 9,
              icone: Icons.bug_report_outlined,
              cor: Colors.orangeAccent,
              titulo: 'Debug',
              subtitulo: 'Ferramentas de desenvolvedor',
              onTap: () => _push(context, const TelaDebug()),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- cabeçalho
  Widget _cabecalho(
    BuildContext context, {
    required User? user,
    required Uint8List? banner,
    required Uint8List? foto,
  }) {
    final cores = context.cores;
    const alturaBanner = 130.0;
    const raio = 46.0;

    ImageProvider? imagemFoto;
    if (foto != null) {
      imagemFoto = MemoryImage(foto);
    } else if (user?.photoURL != null) {
      imagemFoto = NetworkImage(user!.photoURL!);
    }

    Widget botaoEditar(VoidCallback aoTocar) => GestureDetector(
          onTap: aoTocar,
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: cores.destaque,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black26),
            ),
            child: const Icon(Icons.edit, size: 15, color: Colors.white),
          ),
        );

    return EntradaSuave(
      child: Column(
        children: [
          SizedBox(
            height: alturaBanner + raio,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Banner
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: alturaBanner,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: banner == null
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  cores.destaque,
                                  cores.destaque.withValues(alpha: 0.25),
                                ],
                              )
                            : null,
                        image: banner != null
                            ? DecorationImage(
                                image: MemoryImage(banner), fit: BoxFit.cover)
                            : null,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: botaoEditar(
                      () => _editarImagem(context, banner: true)),
                ),
                // Foto, sobreposta ao banner
                Positioned(
                  left: 20,
                  bottom: 0,
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                        child: CircleAvatar(
                          radius: raio,
                          backgroundColor: cores.cardSuave,
                          backgroundImage: imagemFoto,
                          child: imagemFoto == null
                              ? Icon(Icons.person,
                                  size: 44, color: cores.textoSecundario)
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: botaoEditar(
                            () => _editarImagem(context, banner: false)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? user?.email ?? 'Usuário',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  if (user?.email != null && user?.displayName != null)
                    Text(user!.email!,
                        style: TextStyle(
                            color: cores.textoSecundario, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- botões
  Widget _opcaoConfig(
    BuildContext context, {
    required int ordem,
    required IconData icone,
    required Color cor,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    final cores = context.cores;

    return EntradaSuave(
      delay: Duration(milliseconds: 120 + ordem * 70),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cores.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icone, color: cor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitulo,
                        style: TextStyle(
                            color: cores.textoSecundario, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cores.textoSecundario),
            ],
          ),
        ),
      ),
    );
  }
}