// lib/services/diario_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/entrada_diario.dart';

class DiarioService {
  final FirebaseFirestore firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'serenia-db',
  );

  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> salvarEntrada(
    String texto, {
    String titulo = '',
    double humor = 0.5,
    String? audioUrl,
    String? imagemUrl,
    DateTime? data,
  }) async {
    final user = auth.currentUser;
    if (user == null) return;

    await firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('entradas')
        .add({
      'titulo': titulo,
      'texto': texto,
      'data': Timestamp.fromDate(data ?? DateTime.now()),
      'humor': humor,
      'audioUrl': audioUrl,
      'imagemUrl': imagemUrl,
      'favorito': false,
    });
  }

  Future<void> atualizarEntrada(
    String id, {
    required String titulo,
    required String texto,
    required double humor,
    required DateTime data,
  }) async {
    final user = auth.currentUser;
    if (user == null) return;

    await firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('entradas')
        .doc(id)
        .update({
      'titulo': titulo,
      'texto': texto,
      'humor': humor,
      'data': Timestamp.fromDate(data),
    });
  }

  Future<void> alternarFavorito(
    String id,
    bool valorAtual,
  ) async {
    final user = auth.currentUser;
    if (user == null) return;

    await firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('entradas')
        .doc(id)
        .update({
      'favorito': !valorAtual,
    });
  }

  Stream<List<EntradaDiario>> streamEntradasPeriodo(
    DateTime inicio,
    DateTime fim,
  ) {
    final user = auth.currentUser;
    if (user == null) return const Stream.empty();

    return firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('entradas')
        .where(
          'data',
          isGreaterThanOrEqualTo: Timestamp.fromDate(inicio),
        )
        .where(
          'data',
          isLessThan: Timestamp.fromDate(fim),
        )
        .orderBy('data')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EntradaDiario.fromDoc(doc))
              .toList(),
        );
  }

  Future<void> deletarEntrada(String id) async {
    final user = auth.currentUser;
    if (user == null) return;

    await firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('entradas')
        .doc(id)
        .delete();
  }

  Stream<List<EntradaDiario>> streamEntradas() {
    final user = auth.currentUser;
    if (user == null) return const Stream.empty();

    return firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('entradas')
        .orderBy('data', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EntradaDiario.fromDoc(doc))
              .toList(),
        );
  }
}