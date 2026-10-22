// lib/services/perfil_service.dart
//
// Foto de perfil e banner do usuário.
// As imagens são reduzidas e guardadas no próprio Firestore (campo em base64
// no documento usuarios/{uid}), então NÃO precisa do Firebase Storage/Blaze.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/diario_service.dart';
import '../screens/tela_recortar.dart';

class PerfilService {
  PerfilService._();

  static DocumentReference<Map<String, dynamic>>? get _doc {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return DiarioService().firestore.collection('usuarios').doc(uid);
  }

  /// Dados do perfil em tempo real (foto, banner, descricao...).
  static Stream<Map<String, dynamic>> stream() {
    final doc = _doc;
    if (doc == null) return const Stream.empty();
    return doc.snapshots().map((d) => d.data() ?? <String, dynamic>{});
  }

  static Uint8List? imagem(Map<String, dynamic>? dados, String campo) {
    final b64 = dados?[campo] as String?;
    if (b64 == null || b64.isEmpty) return null;
    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  static AjusteImagem? ajuste(Map<String, dynamic>? dados, String campo) =>
      AjusteImagem.fromList(dados?['${campo}Ajuste']);

  /// Abre a galeria/câmera, deixa o usuário recortar e salva.
  /// [banner] = true para o banner. Devolve false se cancelou.
  static Future<bool> escolher(
    BuildContext context, {
    required bool banner,
    ImageSource origem = ImageSource.gallery,
  }) async {
    final doc = _doc;
    if (doc == null) return false;

    final arquivo = await ImagePicker().pickImage(
      source: origem,
      maxWidth: banner ? 1200 : 800,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (arquivo == null) return false;
    final original = await arquivo.readAsBytes();
    if (!context.mounted) return false;

    final ajuste = await Navigator.of(context).push<AjusteImagem>(
      MaterialPageRoute(
        builder: (_) => TelaRecortar(
          bytes: original,
          titulo: banner ? 'Ajustar banner' : 'Ajustar foto',
          proporcao: banner ? 2.7 : 1,
          circulo: !banner,
        ),
      ),
    );
    if (ajuste == null) return false;

    final campo = banner ? 'banner' : 'foto';
    await doc.set(
      {campo: base64Encode(original), '${campo}Ajuste': ajuste.toList()},
      SetOptions(merge: true),
    );
    return true;
  }

  static Future<void> remover({required bool banner}) async {
    await _doc?.set(
      {
        banner ? 'banner' : 'foto': FieldValue.delete(),
        banner ? 'bannerAjuste' : 'fotoAjuste': FieldValue.delete(),
      },
      SetOptions(merge: true),
    );
  }
}