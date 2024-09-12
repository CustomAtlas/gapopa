/// Model for fetched data from API
class Model {
  final String previewURL;
  final int likes;
  final int views;

  Model({
    required this.previewURL,
    required this.likes,
    required this.views,
  });

  factory Model.fromMap(Map<String, dynamic> map) {
    return Model(
      previewURL: map['previewURL'] as String,
      likes: map['likes'] as int,
      views: map['views'] as int,
    );
  }
}
