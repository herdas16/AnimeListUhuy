// lib/favorite_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:belajar/models/anime.dart'; // Pastikan path ini benar
import 'package:firebase_auth/firebase_auth.dart'; // <-- Tambahkan import ini

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  // Mendapatkan ID user yang sedang login
  // Ini akan null jika tidak ada user yang login
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // Method untuk menghapus anime dari favorit di Firestore
  Future<void> _removeFavorite(Anime anime) async {
    // Pastikan user sudah login sebelum menghapus favorit
    if (currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anda harus login untuk menghapus favorit!')),
        );
      }
      return; // Keluar dari fungsi jika tidak ada user ID
    }

    try {
      // Menghapus dokumen dari sub-koleksi 'favorites' di dalam dokumen user spesifik
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .doc(anime.malId.toString())
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${anime.title} removed from favorites!')),
        );
      }
    } on FirebaseException catch (e) {
      debugPrint('Error removing ${anime.title} from favorites: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove ${anime.title}: ${e.message}')),
        );
      }
    } catch (e) {
      debugPrint('General error removing ${anime.title} from favorites: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan pesan jika user belum login
    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Favorite Anime')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Silakan login untuk melihat daftar favorit Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    // Jika user sudah login, tampilkan daftar favorit
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorite Anime'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // StreamBuilder sekarang mendengarkan perubahan pada sub-koleksi 'favorites'
        // di dalam dokumen user yang sedang login. Ini memastikan tampilan real-time.
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId) // Dokumen user spesifik
            .collection('favorites') // Sub-koleksi favorit user tersebut
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No favorite anime added yet.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'Go to the Home screen and add some!',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Jika data tersedia, tampilkan daftar menggunakan ListView.builder
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final animeData = doc.data() as Map<String, dynamic>;

              final anime = Anime(
                malId: animeData['malId'] as int? ?? 0,
                title: animeData['title'] as String? ?? 'Unknown Title',
                imageUrl: animeData['imageUrl'] as String? ?? 'https://via.placeholder.com/100x150?text=No+Image',
                synopsis: animeData['synopsis'] as String?,
              );

              return Card(
                margin: const EdgeInsets.all(8.0),
                elevation: 2.0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gambar Anime
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: SizedBox(
                          width: 100,
                          height: 150,
                          child: Image.network(
                            anime.imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) =>
                            loadingProgress == null
                                ? child
                                : Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Judul dan Sinopsis Anime
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
                            const SizedBox(height: 6),
                            Text(
                              anime.synopsis ?? 'No synopsis available.',
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                      // Tombol Hapus dari Favorit
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Remove from Favorites',
                          onPressed: () => _removeFavorite(anime), // Panggil method penghapus
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
