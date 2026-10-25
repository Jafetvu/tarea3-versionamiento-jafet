import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_cafeteria/core/http_client.dart';
import 'package:gestor_cafeteria/core/failure.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'dart:convert';

//Simulación de un cliente http
ApiClient client(int status, [Object? body]) {
  return ApiClient(
    baseUrl: 'http://test',
    client: MockClient(
      (request) async => http.Response(
        body == null ? '' : jsonEncode(body),
        status,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      ),
    ),
  );
}

void main() {
  group('Pruebas del cliente', () {
    test('200 -> Exitoso', () async {
      final api = client(200);
      await expectLater(api.get('/orders/999'), completion(isNull));
    });
    test('404 -> NotFoundFailure()', () async {
      final api = client(404, {'detail': 'Order 999 not found'});
      await expectLater(
        api.get('/orders/999'),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('409 -> ConflictFailure()', () async {
      final api = client(409, {
        'detail': 'No tienes permisos para esta acción',
      });
      await expectLater(
        api.get('/orders/999'),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('422 -> ValidationFailure con mapeo de campos', () async {
      final api = client(422, {
        'detail': [
          {
            'loc': ['body', 'nombre'],
            'msg': 'El nombre es obligatorio',
          },
        ],
      });
      await expectLater(
        api.get('/orders/999'),
        throwsA(
          isA<ValidationFailure>().having(
            (f) => f.fields['nombre'],
            'fields[nombre]',
            'El nombre es obligatorio',
          ),
        ),
      );
    });

    test('503 -> ServerFailure', () async {
      final api = client(503);
      await expectLater(
        api.get('/orders/999'),
        throwsA(
          isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 503),
        ),
      );
    });

    test('Sin conexión (ClientException) -> NetworkFailure', () async {
      final api = ApiClient(
        baseUrl: 'http://test',
        client: MockClient((request) async {
          throw http.ClientException('sin red');
        }),
      );

      await expectLater(api.get('/orders/999'), throwsA(isA<NetworkFailure>()));
    });

    test(
      '300 -> UnexpectedFailure (código de redirección no exitoso)',
      () async {
        final api = client(300);
        await expectLater(
          api.get('/orders/999'),
          throwsA(
            isA<UnexpectedFailure>().having(
              (f) => f.statusCode,
              'statusCode',
              300,
            ),
          ),
        );
      },
    );
  });
}
