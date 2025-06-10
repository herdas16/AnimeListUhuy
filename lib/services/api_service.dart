import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:belajar/models/anime.dart'; // Import model Anime

//servis api yang di ambil
class ApiService {
  static const String _baseUrl = 'https://api.jikan.moe/v4';
// Fungsi untuk mengambil daftar top anime
  Future<List<Anime>> fetchTopAnime() async {
    final response = await http.get(Uri.parse('$_baseUrl/top/anime'));
// Jika response berhasil
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> animeListJson = data['data'];

      return animeListJson
          .map((json) => Anime.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load top anime: ${response.statusCode}');
    }
  }
  // Fungsi untuk mengambil detail anime berdasarkan ID
  Future<Anime> fetchAnimeDetail(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/anime/$id'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return Anime.fromJson(data['data']);
    } else {
      throw Exception('Failed to load anime detail for ID $id: ${response.statusCode}');
    }
  }
}
