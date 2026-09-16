// lib/services/diario_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/entrada_diario.dart';

class DiarioService {
  final FirebaseFirestore firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'serenia-db', // precisa bater com o nome no console
  );

  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> salvarEntrada(String texto, {double humor = 0.5}) async {
    final user = auth.currentUser;
    if (user == null) return;

    await firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('entradas')
        .add({
          'texto': texto,
          'data': Timestamp.now(),
        });
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

  // Stream: atualiza a tela automaticamente quando algo muda
  Stream<List<EntradaDiario>> streamEntradas() {
    final user = auth.currentUser;
    if (user == null) return const Stream.empty();

    return firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('entradas')
        .orderBy('data', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EntradaDiario.fromDoc(doc)).toList());
  }
}