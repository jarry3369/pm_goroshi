import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pmgoroshi/domain/entities/form_data.dart';

part 'api_service.g.dart';

@RestApi(baseUrl: "https://api.example.com")
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  @POST("/submit-data")
  Future<Map<String, dynamic>> submitFormData(@Body() FormData formData);
}

@riverpod
ApiService apiService(ApiServiceRef ref) {
  final dio = Dio();

  // 요청 인터셉터 설정
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // 요청 헤더 설정 등
        options.headers['Content-Type'] = 'application/json';
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // 응답 처리
        return handler.next(response);
      },
      onError: (DioError e, handler) {
        // 에러 처리
        return handler.next(e);
      },
    ),
  );

  return ApiService(dio);
}
