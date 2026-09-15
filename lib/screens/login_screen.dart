import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'tela_principal.dart';


class ConteudoLogin extends StatefulWidget {
  @override
  _ConteudoLoginState createState() => _ConteudoLoginState();
}

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0), // ou a cor que você quiser
      body: ConteudoLogin(),
    );
  }
}

class _ConteudoLoginState extends State<ConteudoLogin> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Text(
              "SERENIA",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                letterSpacing: 3,
              ),
            ),

            SizedBox(height: 40),

            TextField(
              controller: emailController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Email",
                hintStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),

            SizedBox(height: 20),

            TextField(
              controller: senhaController,
              obscureText: true,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Senha",
                hintStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),

            SizedBox(height: 30),

            // 🔥 BOTÕES LADO A LADO
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // 🔐 LOGIN NORMAL
                ElevatedButton(
                  onPressed: () async {
                    if (emailController.text.isEmpty ||
                        senhaController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Preencha todos os campos")),
                      );
                      return;
                    }

                    setState(() => isLoading = true);

                    final user = await AuthService().signInWithEmail(
                      emailController.text,
                      senhaController.text,
                    );

                    setState(() => isLoading = false);

                    if (user != null) {
                      Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TelaPrincipal(),
                      ),
                     );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Erro ao fazer login")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : Text("Entrar"),
                ),

                SizedBox(width: 20),

                // 🌐 GOOGLE
                GestureDetector(
                  onTap: () async {
                    setState(() => isLoading = true);

                    final user = await AuthService().signInWithGoogle();

                    setState(() => isLoading = false);

                    if (user != null) {
                      Navigator.pushReplacementNamed(context, '/diario');
                    }
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/google.png',
                        width: 25,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}