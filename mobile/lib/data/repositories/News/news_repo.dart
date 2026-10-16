import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../api_helper/api_base_helper.dart';
import '../../../config/end_points.dart';
import '../../model/News/news_model.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class NewsRepo {
  Future<List<NewsModel>> getNews({int? limit, int? offset}) async {
    try {
      Map<String, dynamic> params = {};

      if (limit != null) {
        params["limit"] = limit;
      }

      if (offset != null) {
        params["offset"] = offset;
      }

      params["fields"] = "*, image.*";
      params["sort"] = "-date_created"; // Sort by newest first

      final response = await ApiBaseHelper.getApi(
        url: newsUrl,
        useAuthToken: true,
        params: params,
      );

      // print('NEWS RESPONSE: $response');
      if (response['data'] != null) {
        final List<dynamic> newsData = response['data'];
        return newsData.map((json) => NewsModel.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (kDebugMode) {
        logger.d('DioException in getNews: ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        logger.d('Error in getNews: $e');
      }
      rethrow;
    }
  }
}
