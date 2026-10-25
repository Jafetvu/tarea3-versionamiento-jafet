import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gestor_cafeteria/core/failure.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  final http.Client _client;
  final Uri baseUrl;
  final Duration timeout;

  //Clase Client
  ApiClient({
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client(),
       baseUrl = Uri.parse(
         baseUrl ??
             (const String.fromEnvironment('API_URL').isNotEmpty
                 ? const String.fromEnvironment('API_URL')
                 : (kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000')),
       );

  //POST,GET,PATCH,DELETE
  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, Object body) => _send('POST', path, body);
  Future<dynamic> patch(String path, Object body) => _send('PATCH', path, body);
  Future<void> delete(String path) => _send('DELETE', path);

  //Funcion SEND -> Mandar la peticion al Servicio, esperar una respuesta y adecuarlo para flutter

  Future<dynamic> _send(String method, String path, [Object? body]) async {
    //Request: Va arma la peticion con la inyeccion de los HEADERS
    final request = http.Request(method, baseUrl.resolve(path))
      ..headers['Accept'] = 'application/json';

    //Si es una peticion que tiene que mandar un body
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    //Guardar la respuesta del servicio
    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(timeout);
      response = await http.Response.fromStream(streamed);
    } catch (_) {
      throw const NetworkFailure();
    }

    //El response se va a tratar segun el caso con el servicio respondio

    Map<String, String> fieldsFromJson(Object? json) {
      final fields = <String, String>{};
      if (json is Map && json['detail'] is List) {
        for (final error in json['detail'] as List) {
          if (error is Map && error['loc'] is List && error['msg'] is String) {
            final loc = error['loc'] as List;
            if (loc.length > 1) {
              fields[loc[1].toString()] = error['msg'] as String;
            } else if (loc.isNotEmpty) {
              fields[loc.last.toString()] = error['msg'] as String;
            }
          }
        }
      }
      return fields;
    }

    String extractDetail(Object? json, [String fallback = 'Error inesperado']) {
      if (json is Map && json['detail'] is String) {
        return json['detail'] as String;
      }
      return fallback;
    }

    Failure mapHttpError(int code, Object? json) {
      final detail = extractDetail(json);
      return switch (code) {
        404 => NotFoundFailure(detail),
        409 => ConflictFailure(detail),
        422 => ValidationFailure(fieldsFromJson(json)),
        >= 500 && < 600 => ServerFailure(code),
        _ => UnexpectedFailure(code, detail),
      };
    }

    dynamic tryDecode(http.Response response) {
      if (response.bodyBytes.isEmpty) return null;

      try {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        return null;
      }
    }

    final json = tryDecode(response);
    final code = response.statusCode;
    if (code >= 200 && code < 300) {
      return json;
    } else {
      throw mapHttpError(code, json);
    }
  }
}
