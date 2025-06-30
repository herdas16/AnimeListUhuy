// lib/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true; // true untuk mode login, false untuk mode daftar (register)
  bool _isLoading = false; // Untuk indikator loading saat proses autentikasi

  final FirebaseAuth _auth = FirebaseAuth.instance; // Instansiasi Firebase Auth

  // Fungsi untuk menangani proses login atau daftar
  Future<void> _submitAuthForm() async {
    setState(() {
      _isLoading = true; // Tampilkan loading indicator
    });
    try {
      if (_isLogin) {
        // Jika _isLogin true, ini adalah mode LOGIN
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login Berhasil!')),
          );
        }
      } else {
        // Jika _isLogin false, ini adalah mode DAFTAR (REGISTER)
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pendaftaran Berhasil! Silakan Login.')),
          );
          // Setelah daftar, bisa langsung arahkan ke mode login agar user bisa langsung masuk
          setState(() {
            _isLogin = true;
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'Email atau password salah.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email sudah terdaftar.';
      } else if (e.code == 'weak-password') {
        message = 'Password terlalu lemah.';
      } else {
        message = 'Terjadi kesalahan: ${e.message}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false; // Sembunyikan loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Daftar Akun Baru'), // Judul AppBar berubah
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Input Email
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
              ),
              const SizedBox(height: 16),
              // Input Password
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              // Tombol Login/Daftar
              _isLoading
                  ? const CircularProgressIndicator() // Tampilkan loading jika _isLoading true
                  : ElevatedButton(
                onPressed: _submitAuthForm, // Panggil fungsi submit
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50), // Lebar penuh
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(_isLogin ? 'MASUK' : 'DAFTAR'), // Teks tombol berubah
              ),
              const SizedBox(height: 16),
              // Tombol untuk beralih mode (Login <-> Daftar)
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin; // Toggle nilai _isLogin
                    _emailController.clear(); // Bersihkan input saat beralih mode
                    _passwordController.clear();
                  });
                },
                child: Text(_isLogin
                    ? 'Belum punya akun? Daftar sekarang!' // Teks untuk beralih ke Daftar
                    : 'Sudah punya akun? Masuk di sini!'), // Teks untuk beralih ke Login
              ),
            ],
          ),
        ),
      ),
    );
  }
}
