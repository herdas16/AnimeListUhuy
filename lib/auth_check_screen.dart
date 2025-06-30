// lib/auth_check_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'auth_screen.dart'; // Import halaman autentikasi
import 'package:belajar/home_screen.dart'; // Import halaman utama lo

class AuthCheckScreen extends StatelessWidget {
  const AuthCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder mendengarkan perubahan status autentikasi dari Firebase
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Tampilkan indikator loading saat menunggu status autentikasi
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        // Jika ada data (user sudah login)
        if (snapshot.hasData) {
          return const HomeScreen(); // Arahkan ke HomeScreen
        } else {
          // Jika tidak ada data (user belum login)
          return const AuthScreen(); // Arahkan ke AuthScreen
        }
      },
    );
  }
}
