// lib/home_screen.dart
import 'dart:async'; // Untuk StreamSubscription

import 'package:flutter/material.dart';
import 'package:belajar/models/anime.dart';
import 'package:belajar/services/api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- PENTING: Cloud Firestore
import 'package:belajar/favorite_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Anime>> _topAnime;

  // Mendapatkan ID user yang sedang login
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
  // Instansiasi Cloud Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // StreamSubscription untuk memantau perubahan user
  StreamSubscription<User?>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _topAnime = ApiService().fetchTopAnime();

    // Memantau perubahan status autentikasi
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        // Memicu rebuild HomeScreen ketika status auth berubah
        // Ini memastikan StreamBuilder per item mendapatkan currentUserId terbaru
        setState(() {
          debugPrint('Auth state changed. User ID: ${user?.uid}');
        });
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel(); // Pastikan subscription ditutup saat widget dibuang
    super.dispose();
  }

  // Method untuk menambah/menghapus anime dari favorit di Cloud Firestore
  Future<void> _toggleFavorite(Anime anime) async {
    if (currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anda harus login untuk memfavoritkan anime!')),
        );
      }
      return;
    }

    // Referensi ke dokumen favorit user spesifik di Firestore
    final DocumentReference animeFavoriteDocRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('favorites')
        .doc(anime.malId.toString()); // Menggunakan malId sebagai ID dokumen

    try {
      final DocumentSnapshot currentFavoriteStatus = await animeFavoriteDocRef.get();
      final bool isCurrentlyFavorite = currentFavoriteStatus.exists; // Cek status langsung dari Firestore

      if (isCurrentlyFavorite) {
        // Hapus dari favorit
        await animeFavoriteDocRef.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${anime.title} removed from favorites!')),
          );
        }
      } else {
        // Tambahkan ke favorit
        await animeFavoriteDocRef.set({
          'malId': anime.malId,
          'title': anime.title,
          'imageUrl': anime.imageUrl,
          'synopsis': anime.synopsis,
          'favoritedAt': FieldValue.serverTimestamp(), // Gunakan FieldValue.serverTimestamp() untuk Firestore
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${anime.title} added to favorites!')),
          );
        }
      }
      debugPrint('Toggled favorite for ${anime.title}. New state: ${!isCurrentlyFavorite}');
    } on FirebaseException catch (e) {
      debugPrint('Firebase error toggling favorite for ${anime.title}: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update favorite status: ${e.message}')),
        );
      }
    } catch (e) {
      debugPrint('General error toggling favorite for ${anime.title}: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Anime List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _topAnime = ApiService().fetchTopAnime();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoriteScreen()),
              );
              // Tidak perlu muat ulang di sini lagi karena ikon sudah real-time
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Berhasil Logout!')),
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Anime>>(
        future: _topAnime,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No anime found.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final anime = snapshot.data![index];

                return StreamBuilder<DocumentSnapshot?>( // <--- PENTING: Tipe snapshot untuk Firestore
                  // Pastikan stream ini hanya aktif jika user sudah login
                  stream: currentUserId != null
                      ? _firestore
                      .collection('users')
                      .doc(currentUserId)
                      .collection('favorites')
                      .doc(anime.malId.toString()) // Stream spesifik untuk dokumen ini
                      .snapshots() // Menggunakan .snapshots() untuk Firestore
                      : Stream.value(null), // Jika belum login, beri stream null agar tidak error
                  builder: (context, favoriteSnapshot) {
                    bool isFavorite = false;
                    // Jika ada data di dokumen ini (berarti favorit)
                    if (favoriteSnapshot.hasData && favoriteSnapshot.data!.exists) { // <--- Cek .exists untuk Firestore
                      isFavorite = true;
                    }

                    // Tambahan pengecekan: jika user belum login, ikon selalu abu-abu dan tidak bisa diklik
                    if (currentUserId == null) {
                      isFavorite = false;
                    }

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 150,
                              child: Image.network(
                                anime.imageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.error, size: 50, color: Colors.grey);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    anime.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    anime.synopsis ?? 'No synopsis available.',
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : Colors.grey,
                                ),
                                onPressed: currentUserId != null
                                    ? () => _toggleFavorite(anime)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }, // Penutup StreamBuilder
                );
              },
            );
          }
        },
      ),
    );
  }
}
