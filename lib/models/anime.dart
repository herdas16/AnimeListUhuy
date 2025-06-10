class Anime {
  final int malId;
  final String title;
  final String imageUrl;
  final String? synopsis; //mengambil sinopsis, jika tidak ada akan jadi null

  Anime({
    required this.malId,
    required this.title,
    required this.imageUrl,
    this.synopsis,
  });

  // mengambil data dari json
  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      malId: json['mal_id'],
      title: json['title'],
      imageUrl: json['images']['jpg']['large_image_url'],
      synopsis: json['synopsis'],
    );
  }
}
