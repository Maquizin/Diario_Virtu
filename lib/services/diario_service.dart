import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DiarioService {

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> salvarEntrada(String texto) async {

    final user = auth.currentUser;

    print("USUARIO:");
    print(user);

    if (user == null) {
      print("USUARIO NULO");
      return;
    }

    try {

      await firestore
          .collection('usuarios')
          .doc(user.uid)
          .collection('entradas')
          .add({

        'texto': texto,
        'data': Timestamp.now(),

      });

      print("SALVOU NO FIREBASE");

    } catch (e) {

      print("ERRO FIREBASE:");
      print(e);

    }
  }
}

