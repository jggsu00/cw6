import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool isLogin = true;

  Future<void> authAction() async {
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailCtrl.text,
          password: passCtrl.text,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailCtrl.text,
          password: passCtrl.text,
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Auth error: ${e.toString()}'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Register')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: emailCtrl, decoration: InputDecoration(labelText: 'Email')),
          TextField(controller: passCtrl, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
          SizedBox(height: 20),
          ElevatedButton(onPressed: authAction, child: Text(isLogin ? 'Login' : 'Register')),
          TextButton(
            onPressed: () => setState(() => isLogin = !isLogin),
            child: Text(isLogin ? 'Create account' : 'Already have an account?'),
          )
        ]),
      ),
    );
  }
}
