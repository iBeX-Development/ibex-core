import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../config/error_message_code.dart';
import '../data/GlobalVariable/globalvariable.dart';
import 'api.dart';
import '../utils/widgets/toast_widget.dart';
import '../../api_helper/header.dart';

final logger = Logger();

class ApiBaseHelper {
  static final Dio _dio = Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Called before request is sent
          if (kDebugMode) {
            logger.i('🚀 ==================== API REQUEST ====================');
          }
          if (kDebugMode) {
            logger.i('📡 Method: ${options.method}');
          }
          if (kDebugMode) {
            logger.i('🌐 URL: ${options.path}');
          }
          if (kDebugMode) {
            logger.i('🔑 Headers: ${options.headers}');
          }
          if (kDebugMode) {
            logger.i('📦 Query Parameters: ${options.queryParameters}');
          }

          // Detailed body logging
          if (options.data != null) {
            if (options.data is FormData) {
              // logger.i('📋 Body Type: FormData');
              FormData formData = options.data as FormData;
              // logger.i('📄 Form Fields:');
              for (var field in formData.fields) {
                if (kDebugMode) {
                  logger.i('  ➜ ${field.key}: ${field.value}');
                }
              }
              // logger.i('📂 Form Files:');
              for (var file in formData.files) {
                logger.i(
                    '  ➜ ${file.key}: ${file.value.filename} (${file.value.length} bytes)');
              }
            } else {
              if (kDebugMode) {
                logger.i('📋 Body Type: JSON');
              }
              // logger.i('📦 Body Data: ${options.data}');
            }
          } else {
            if (kDebugMode) {
              logger.i('📦 Body: null');
            }
          }
          // logger.i('🚀 =================================================');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Called when response is received
          // logger.i('✅ ==================== API RESPONSE ====================');
          // logger.i('📊 Status Code: ${response.statusCode}');
          // logger.i('🌐 URL: ${response.requestOptions.path}');
          // logger.i('⏱️ Response Time: ${DateTime.now()}');
          // logger.i('📦 Response Data: ${response.data}');
          // logger.i('✅ ====================================================');
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Add a delay to ensure this runs after the current execution
            GoRouter.of(navigatorKey.currentContext!).go('/login');

            // Return a resolved response instead of an error
            return handler.resolve(Response(
              requestOptions: e.requestOptions,
              data: {'message': 'Unauthorized, redirecting to login'},
              statusCode: 200,
            ));
          }

          if (e.response?.statusCode == 403) {
            logger.i(
                '⛔ FORBIDDEN (403): You don\'t have permission to access this resource');
            if (kDebugMode) {
              logger.i('⛔ URL: ${e.requestOptions.path}');
            }
            if (kDebugMode) {
              logger.i('⛔ Method: ${e.requestOptions.method}');
            }
            if (kDebugMode) {
              logger.i('⛔ Headers: ${e.requestOptions.headers}');
            }
            if (kDebugMode) {
              logger.i('⛔ Response: ${e.response?.data}');
            }
            logger.i(
                '⛔ FIX: Check Directus admin panel → Settings → Roles & Permissions');
            logger.i(
                '⛔ Make sure your admin role has "Admin Access" enabled or all collection permissions are granted');
          }

          if (kDebugMode) {

            logger.i('⛔ Error: ${e.response?.statusCode} ${e.message}');

          }
          return handler.next(e);
        },
      ),
    );
  static Future<dynamic> patch({
    Map<String, dynamic>? body,
    required String url,
    bool useAuthToken = true,
    Map<String, dynamic>? queryParameters,
    Function(int, int)? onSendProgress,
    Function(int, int)? onReceiveProgress,
    bool isMultipart = false, // <-- Add a flag to toggle FormData
  }) async {
    try {
      // logger.d("PATCH REQUEST => URL: $url\nBODY: $body");

      final Map<String, String>? header = await headers;

      dynamic dataToSend;

      if (isMultipart && body != null) {
        FormData formData = FormData();

        body.forEach((key, value) {
          if (value is File) {
            formData.files.add(MapEntry(
              key,
              MultipartFile.fromFileSync(value.path,
                  filename: value.path.split('/').last),
            ));
          } else {
            formData.fields.add(MapEntry(key, value.toString()));
          }
        });

        dataToSend = formData;
      } else {
        dataToSend = body;
        header?['Content-Type'] = 'application/json'; // important
      }

      final response = await _dio.patch(
        url,
        data: dataToSend,
        queryParameters: queryParameters,
        options: Options(
          headers: header,
        ),
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      return {
        "data": Map.from(response.data),
        "status": 200,
      };
    } on DioException catch (e) {
      logger.e("DioException: ${e.response?.data}");
      rethrow;
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } catch (e) {
      logger.e("Unhandled error: $e");
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

//   static Future<dynamic> patch({
//     Map<String, dynamic>? body,
//     bool isFcm = false,
//     required String url,
//     bool? useAuthToken,
//     Map<String, dynamic>? queryParameters,
//     Function(int, int)? onSendProgress,
//     Function(int, int)? onReceiveProgress,
//   }) async {
//     try {
//       logger.i("HEADER ? BODY $url $body");
//       body ??= {};
//       FormData formData = FormData();
//       final Map<String, String>? header = await headers;
//
//       body.forEach((key, value) {
//         if (value is File) {
//           formData.files.add(MapEntry(
//             key,
//             MultipartFile.fromFileSync(value.path,
//                 filename: value.path.split('/').last),
//           ));
//         } else {
//           formData.fields.add(MapEntry(key, value.toString()));
//         }
//       });
// logger.i("fvgbhnjm Header $header");
//       // Add your custom patch logic here
//       final response = await _dio.patch(
//
//         url,
//         // data: body is Map<String, dynamic> ? body : formData,
//         data: body is FormData ? body : FormData.fromMap(body),
//
//         queryParameters: queryParameters,
//         options: Options(headers: header),
//       );
//
//       // Handling response error
//       // if (response.data['error']) {
//       //   throw ApiException(response.data['message']);
//       // }
//
//       return <String, dynamic>{
//         "data": Map.from(response.data),
//         "status": 200,
//       };
//     } on DioException catch (e) {
//        logger.i(e.response?.data);
//       rethrow;
//     } on ApiException catch (e) {
//       throw ApiException(e.errorMessage);
//     } catch (e) {
//       logger.i("e: $e");
//       throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
//     }
//   }

  static Future<Map<String, dynamic>> loginPost({
    Map<String, dynamic>? body,
    required String url,
  }) async {
    try {
      // logger.i("FDJ Fkd,zhgnd;y $body");
      // logger.i("FDJ Fkd,zhgnd;x $url");
      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (kDebugMode) {
        logger.i("DioException,err; ${e}");
      }

      logger.e("DioException: ${e.response?.data}");
      if (e.response?.data is Map<String, dynamic>) {
        return e.response?.data as Map<String, dynamic>;
      }
      throw ApiException(
        e.error is SocketException
            ? ErrorMessageKeysAndCode.noInternetCode
            : ErrorMessageKeysAndCode.defaultErrorMessageCode,
        isNoInternet: true,
      );
    } on ApiException catch (e) {
      if (kDebugMode) {
        logger.i("ApiException,err; ${e}");
      }

      throw ApiException(e.errorMessage);
    } catch (e) {
      logger.e("Unhandled Exception: $e");
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

  static Future<Map<String, dynamic>> signUpPost({
    Map<String, dynamic>? body,
    required String url,
  }) async {
    try {
      final response = await _dio.post(url,
          data: body,
          options: Options(headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          }));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      logger.e("DioException: ${e.response?.data}");
      throw ApiException(
          e.error is SocketException
              ? ErrorMessageKeysAndCode.noInternetCode
              : ErrorMessageKeysAndCode.defaultErrorMessageCode,
          isNoInternet: true);
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } catch (e) {
      logger.e("Unhandled Exception: $e");
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

  static Future<Map<String, dynamic>> formPost({
    required String url,
    dynamic body, // Can be Map<String, dynamic> or FormData
    bool useAuthToken = true,
    Map<String, dynamic>? queryParameters,
    Function(int, int)? onSendProgress,
    Function(int, int)? onReceiveProgress,
  }) async {
    try {
      // Fetch headers dynamically
      final Map<String, String>? authHeaders = await headers;
      final response = await _dio.post(
        url,
        data: body, // Supports FormData or JSON body
        queryParameters: queryParameters,
        options: Options(
          headers: authHeaders,
          contentType:
              Headers.jsonContentType, // Automatically handles FormData
        ),
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      if (response.statusCode != 200) {
        flutterToastCustom(msg: "Request failed");
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e, stackTrace) {
      logger.e("DioException: ${e.message}", stackTrace: stackTrace);

      if (e.response?.data != null) {
        return e.response?.data as Map<String, dynamic>;
      }

      throw ApiException(
        e.error is SocketException
            ? ErrorMessageKeysAndCode.noInternetCode
            : ErrorMessageKeysAndCode.defaultErrorMessageCode,
        isNoInternet: true,
      );
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } catch (e) {
      logger.e("Unhandled Exception: $e");
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

// Assuming _dio is a pre-configured Dio instance

// Assuming headers is a method that fetches auth headers dynamically

  static Future<Map<String, dynamic>> formPostChat({
    required String url,
    dynamic body, // Can be Map<String, dynamic> or FormData
    bool useAuthToken = true,
    Map<String, dynamic>? queryParameters,
    Function(int, int)? onSendProgress,
    Function(int, int)? onReceiveProgress,
  }) async {
    try {
      final Map<String, String>? authHeaders =
          useAuthToken ? await headerForChat : null;
      if (body is FormData) {
        if (kDebugMode) {
          logger.i("📤 Sending FormData:");
        }
        for (var f in body.fields) {
          if (kDebugMode) {
            logger.i("  ➜ ${f.key} = ${f.value}");
          }
        }
      }

      // logger.i("➡️ Headers: $headerForChat");
      // logger.i("➡️ URL: $url");
      // logger.i("➡️ Query Params: $queryParameters");

      final response = await _dio.post(
        url,
        data: body,
        queryParameters: queryParameters,
        options: Options(
          headers: authHeaders,
          contentType: body is FormData ? null : Headers.jsonContentType,
        ),
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      if (response.statusCode != 200) {
        if (kDebugMode) {
          logger.d("Response data: ${response.data}");
        }
        flutterToastCustom(msg: "Request failed");
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e, stackTrace) {
      logger.e("DioException: ${e.message}", stackTrace: stackTrace);

      if (e.response?.data != null) {
        return e.response?.data as Map<String, dynamic>;
      }

      throw ApiException(
        e.error is SocketException
            ? ErrorMessageKeysAndCode.noInternetCode
            : ErrorMessageKeysAndCode.defaultErrorMessageCode,
        isNoInternet: true,
      );
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } catch (e) {
      logger.e("Unhandled Exception: $e");
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

  static Future<Map<String, dynamic>> post({
    Map<String, dynamic>? body,
    required String url,
    bool? useAuthToken,
    Map<String, dynamic>? queryParameters,
    Function(int, int)? onSendProgress,
    Function(int, int)? onReceiveProgress,
  }) async {
    try {
      body ??= {};

      final Map<String, String>? authHeaders = await headers;
      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          headers: authHeaders,
        ),
      );
      if (kDebugMode) {
        logger.i("authHeaders");
      }
      if (response.statusCode != 200) {
        flutterToastCustom(msg: "ghj ");
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e, stackTrace) {
      if (e.response != null) {
        if (kDebugMode) {
          logger.i("${e.response!.data}");
        }
        if (kDebugMode) {
          logger.i("${e.response!.headers}");
        }
        if (kDebugMode) {
          logger.i("${e.response!.requestOptions}");
        }
      } else {
        // Something happened in setting up or sending the request that triggered an Error
        if (kDebugMode) {
          logger.i("${e.requestOptions.validateStatus}");
        }
        if (kDebugMode) {
          logger.i("${e.message}");
        }
      }
      if (kDebugMode) {
        logger.i("sfgbgbdzvm  $stackTrace");
      }
      if (e.response?.data != null) {
        return e.response?.data as Map<String, dynamic>;
      }
      if (kDebugMode) {
        logger.i("Error Response Data: ${e.response?.data}");
      }
      throw ApiException(
        e.error is SocketException
            ? ErrorMessageKeysAndCode.noInternetCode
            : ErrorMessageKeysAndCode.defaultErrorMessageCode,
        isNoInternet: true,
      );
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } catch (e) {
      logger.e("Unhandled Exception: $e");
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

  static Future<Map<String, dynamic>> postImageWithText({
    Map<String, dynamic>? body,
    required String url,
    bool? useAuthToken,
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    Function(int, int)? onSendProgress,
    Function(int, int)? onReceiveProgress,
  }) async {
    try {
      // logger.i("ogk;lm $formData");
      for (var field in formData.fields) {
        if (kDebugMode) {
          logger.i("Field: ${field.key} = ${field.value}");
        }
        if (kDebugMode) {
          logger.i("klesgkdx,nv ${field.key}");
        }
      }
      final Map<String, String>? authHeaders = await headers;

      final response = await _dio.post(url,
          data: formData, options: Options(headers: authHeaders));

      // logger.i("dgklfgxcmg. $response");
      if (response.statusCode != 200) {
        flutterToastCustom(msg: "ghj ");
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e, stackTrace) {
      if (e.response != null) {
        if (kDebugMode) {
          logger.i(e.response!.data);
        }
        if (kDebugMode) {
          logger.i(e.response!.headers);
        }
        if (kDebugMode) {
          logger.i(e.response!.requestOptions);
        }
      } else {
        // Something happened in setting up or sending the request that triggered an Error
        if (kDebugMode) {
          logger.i(e.requestOptions.validateStatus);
        }
        if (kDebugMode) {
          logger.i(e.message);
        }
      }
      if (kDebugMode) {
        logger.i("sfgbgbdzvm  $stackTrace");
      }
      if (e.response?.data != null) {
        return e.response?.data as Map<String, dynamic>;
      }
      if (kDebugMode) {
        logger.i("Error Response Data: ${e.response?.data}");
      }
      throw ApiException(
        e.error is SocketException
            ? ErrorMessageKeysAndCode.noInternetCode
            : ErrorMessageKeysAndCode.defaultErrorMessageCode,
        isNoInternet: true,
      );
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } catch (e) {
      logger.e("Unhandled Exception: $e");
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

  static Future<Map<String, dynamic>> postMedia({
    Map<String, dynamic>? body,
    required String url,
    bool? useAuthToken,
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    Function(int, int)? onSendProgress,
    Function(int, int)? onReceiveProgress,
  }) async {
    try {
      // Debugging FormData
      if (kDebugMode) {
        logger.i("🚀 Sending FormData media:");
      }
      for (var field in formData.fields) {
        if (kDebugMode) {
          logger.i("📄 Field: ${field.key} = ${field.value}");
        }
      }
      for (var file in formData.files) {
        if (kDebugMode) {
          logger.i("📂 File: ${file.key} = ${file.value.filename}");
        }
      }

      final Map<String, String>? authHeaders = await headers;

      final response = await _dio.post(
        url,
        data: formData,
        options: Options(headers: authHeaders),
      );
      // if (response.data['error']) {
      //   throw ApiException(response.data['message']);
      // }

      // return <String, dynamic>{
      //   "data": Map.from(response.data),
      //   "status": 200,
      // };
      // logger.i('✅ GET Response Status: ${response.statusCode}');
      // logger.i('✅ GET Response Type: ${response.data.runtimeType}');
      // logger.i(
      //     '✅ GET Response Keys: ${response.data is Map ? response.data.keys : 'Not a Map'}');

      // ✅ Ensure response.data is a Map
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      } else if (response.data is String) {
        // If response is a String, try to decode it
        try {
          final decoded = json.decode(response.data);
          if (decoded is Map) {
            return Map<String, dynamic>.from(decoded);
          }
        } catch (e) {
          if (kDebugMode) {
            logger.i('❌ Failed to decode string response: $e');
          }
        }
      }

      // ✅ Wrap non-Map responses
      return {
        'data': response.data,
        'status': response.statusCode,
      };
    } on DioException catch (e) {
      logger.e("DioException: ${e.response?.data}");
      throw ApiException(
          e.error is SocketException
              ? ErrorMessageKeysAndCode.noInternetCode
              : ErrorMessageKeysAndCode.defaultErrorMessageCode,
          isNoInternet: true);
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } catch (e) {
      logger.e("Unhandled Exception: $e");
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

  static Future<dynamic> postProfile({
    required String url,
    bool? useAuthToken,
    File? profile,
    String? type,
    int? id,
    Map<String, dynamic>? queryParameters,
    Function(int, int)? onSendProgress,
    Function(int, int)? onReceiveProgress,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'upload': await MultipartFile.fromFile(profile!.path),
        'id': id,
        'type': type,
      });

      final Map<String, String>? header = await headers;
      final response = await _dio.post(
        url,
        data: formData,
        options: Options(headers: header),
      );
      if (response.data['error']) {
        throw ApiException(response.data['message']);
      }

      return <String, dynamic>{
        "data": Map.from(response.data),
        "status": 200,
      };
    } on DioException catch (e) {
      logger.e("DioException: ${e.response?.data}");
      throw ApiException(
          e.error is SocketException
              ? ErrorMessageKeysAndCode.noInternetCode
              : ErrorMessageKeysAndCode.defaultErrorMessageCode,
          isNoInternet: true);
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } catch (e) {
      logger.e("Unhandled Exception: $e");
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

  static Future<dynamic> delete({
    Map<String, dynamic>? body,
    required String url,
    bool? useAuthToken,
    Map<String, dynamic>? queryParameters,
    Function(int, int)? onSendProgress,
    Function(int, int)? onReceiveProgress,
  }) async {
    try {
      body ??= {};

      FormData formData = FormData();
      final Map<String, String>? header = await headers;

      body.forEach((key, value) {
        if (value is File) {
          formData.files.add(MapEntry(
            key,
            MultipartFile.fromFileSync(value.path,
                filename: value.path.split('/').last),
          ));
        } else {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });

      // logger.i(" Deleting url: $url");
      final response = await _dio.delete(
        url,
        data: body,
        queryParameters: queryParameters,
        options: Options(headers: header),
      );

      if (response.data is Map && response.data['error'] == true) {
        throw ApiException(response.data['message']);
      }

      return <String, dynamic>{
        "data": response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : response.data,
        "status": 200,
      };
    } on DioException catch (e) {
      flutterToastCustom(msg: e.response?.data['message']);
      throw ApiException(
          e.error is SocketException
              ? ErrorMessageKeysAndCode.noInternetCode
              : ErrorMessageKeysAndCode.defaultErrorMessageCode,
          isNoInternet: true);
    } on ApiException catch (e) {
      flutterToastCustom(msg: e.toString());
      throw ApiException(e.errorMessage);
    } catch (e) {
      if (kDebugMode) {
        logger.i("e: $e");
      }
      flutterToastCustom(msg: e.toString());
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

  static Future<Map<String, dynamic>> deleteApi({
    Map<String, dynamic>? body,
    required String url,
    bool? useAuthToken,
    Map<String, dynamic>? queryParameters,
    Function(int, int)? onSendProgress,
    Function(int, int)? onReceiveProgress,
  }) async {
    try {
      body ??= {};
      FormData formData = FormData();
      final Map<String, String>? header = await headers;

      body.forEach((key, value) {
        if (value is File) {
          formData.files.add(MapEntry(
            key,
            MultipartFile.fromFileSync(value.path,
                filename: value.path.split('/').last),
          ));
        } else {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });

      final response = await _dio.delete(
        url,
        data: body,
        queryParameters: queryParameters,
        options: Options(headers: header),
      );

      if (response.data['error']) {
        throw ApiException(response.data['message']);
      }
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      flutterToastCustom(msg: e.response?.data['message']);

      throw ApiException(
          e.error is SocketException
              ? ErrorMessageKeysAndCode.noInternetCode
              : ErrorMessageKeysAndCode.defaultErrorMessageCode,
          isNoInternet: true);
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } catch (e) {
      if (kDebugMode) {
        logger.i("e: $e");
      }
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

  static Future<dynamic> get(
      {required String url,
      required bool useAuthToken,
      required Map<String, dynamic> params}) async {
    Response responseJson;

    final Map<String, String>? header = await headers;
    try {
      // logger.i("get url header $header $params");
      final response = await _dio.get(url,
          queryParameters: params, options: Options(headers: header));
      if (kDebugMode) {
        logger.i(
            'response api****PARAMS $params *********** $url *****************${response.statusCode}*********${response.data}');
      }
      responseJson = response;
    } on SocketException {
      throw ApiException('No Internet connection');
    }
    return responseJson;
  }

  static Future<Map<String, dynamic>> getApi(
      {required String url,
      required bool useAuthToken,
      required Map<String, dynamic> params}) async {
    final Map<String, String>? header = await headers;
    try {
      final response = await _dio.get(url,
          queryParameters: params, options: Options(headers: header));
      // logger.i('response url****$url ');
      // logger.i('response params****$params');
      // logger.i('response statusCode****${response.statusCode} ');
      // logger.i('response_data****${response.data}');
      // if (kDebugMode) {}
      return response.data as Map<String, dynamic>;
    } on SocketException {
      throw ApiException('No Internet connection');
    } catch (e) {
      throw ApiException('Error: $e');
    }
  }

  static Future<List<dynamic>> getGoogleApi({
    required String url,
    required bool useAuthToken,
    required Map<String, dynamic> params,
  }) async {
    final Map<String, String>? header = await headers;

    try {
      final response = await _dio.get(url,
          queryParameters: params, options: Options(headers: header));

      // if (kDebugMode) {
      //   logger.i(
      //       'response api****$params****************** $url *****************${response.statusCode}*********${response.data}');
      // }

      if (response.data is List) {
        return response.data as List<dynamic>;
      } else {
        throw ApiException('Unexpected response format: ${response.data}');
      }
    } on SocketException {
      throw ApiException('No Internet connection');
    } catch (e) {
      throw ApiException('Error: $e');
    }
  }

  static Future<dynamic> getRole(
      {required String url,
      required bool useAuthToken,
      required Map<String, dynamic> params}) async {
    Response responseJson;
    final Dio dio = Dio();

    final Map<String, String>? header = await headers;

    try {
      final response = await dio.get(url,
          queryParameters: params, options: Options(headers: header));
      // if (kDebugMode) {
      //   logger.i(
      //       'response api**** $url *****************${response.statusCode}*********${response.data}');
      // }
      responseJson = response;
    } on SocketException {
      throw ApiException('No Internet connection');
    }
    return responseJson;
  }
}

// class CustomException implements Exception {
//   final String? _message;
//   final String? _prefix;
//
//   CustomException([this._message, this._prefix]);
//
//   @override
//   String toString() {
//     return "$_prefix$_message";
//   }
// }
//
// class FetchDataException extends CustomException {
//   FetchDataException([message])
//       : super(message, "Error During Communication: ");
// }
//
// class BadRequestException extends CustomException {
//   BadRequestException([message]) : super(message, "Invalid Request: ");
// }
//
// class UnauthorisedException extends CustomException {
//   UnauthorisedException([message]) : super(message, "Unauthorised: ");
// }
