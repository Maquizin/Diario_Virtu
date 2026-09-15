import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

Future<User?> signInWithGoogle() async {
  final googleUser = await _googleSignIn.signIn();

  if (googleUser == null) return null;

  final googleAuth = await googleUser.authentication;

  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  final userCredential =
      await _auth.signInWithCredential(credential);

  return userCredential.user;
}

Future<User?> signInWithEmail(String email, String senha) async {
  try {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: senha,
    );

    return credential.user;
  } catch (e) {
    print("Erro no login: $e");
    return null;
  }
}
}