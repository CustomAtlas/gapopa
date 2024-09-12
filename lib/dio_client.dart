import 'package:dio/dio.dart';
import 'package:gapopa/model.dart';

class DioClient {
  final dio = Dio();

  // Get data from API
  Future<List<Model>> getImages(int page, String query) async {
    final response = await dio.get(
      'https://pixabay.com/api/',
      queryParameters: {
        "key": "45925802-225a3bd7fe9a1012644c47fd4",
        "page": page,
        "q": query,
      },
    );
    // Take only necessary list
    return (response.data['hits'] as List<dynamic>)
        .map((e) => Model.fromMap(e))
        .toList();
  }
}
