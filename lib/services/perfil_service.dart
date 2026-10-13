// lib/services/perfil_service.dart
//
// Foto de perfil e banner do usuário.
// As imagens são reduzidas e guardadas no próprio Firestore (campo em base64
// no documento usuarios/{uid}), então NÃO precisa do Firebase Storage/Blaze.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'diario_service.dart';

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

  /// Abre a galeria/câmera e salva. [banner] = true para o banner.
  /// Devolve false se o usuário cancelou.
  static Future<bool> escolher({
    required bool banner,
    ImageSource origem = ImageSource.gallery,
  }) async {
    final doc = _doc;
    if (doc == null) return false;

    final arquivo = await ImagePicker().pickImage(
      source: origem,
      maxWidth: banner ? 1000 : 400,
      maxHeight: banner ? 500 : 400,
      imageQuality: banner ? 70 : 75,
    );
    if (arquivo == null) return false;

    final bytes = await arquivo.readAsBytes();
    await doc.set(
      {banner ? 'banner' : 'foto': base64Encode(bytes)},
      SetOptions(merge: true),
    );
    return true;
  }

  static Future<void> remover({required bool banner}) async {
    await _doc?.set(
      {banner ? 'banner' : 'foto': FieldValue.delete()},
      SetOptions(merge: true),
    );
  }
}