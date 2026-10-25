import 'package:flutter/material.dart';

import 'package:gestor_cafeteria/core/failure.dart';

import 'core/http_client.dart';

Future<void> probar(String nombre, Future<dynamic> Function() llamada) async {
  try {
    final r = await llamada();
    debugPrint('$nombre -> OK: $r');
  } on Failure catch (f) {
    debugPrint('$nombre -> ${f.runtimeType}: ${f.message}');
  }
}

void main() async {
  final api = ApiClient();

  // 1. Control
  await probar('1. Control', () => api.get('/orders'));

  // 2. No encontrado (404)
  await probar('2. No encontrado', () => api.get('/orders/9999'));

  // 3. Conflicto (409)
  // Nota: Primero creamos un pedido o usamos un id recién creado para provocar el cambio inválido a 'delivered'
  final nuevoPedido = await api.post('/orders', {
    'customer': 'Ana',
    'drink': 'latte',
    'size': 'M',
  });
  final id = nuevoPedido['id'];
  await probar(
    '3. Conflicto',
    () => api.patch('/orders/$id', {'status': 'delivered'}),
  );

  // 4. Validación (422)
  await probar(
    '4. Validación',
    () => api.post('/orders', {'customer': '', 'drink': 'te', 'size': 'M'}),
  );

  // 5. Error del servidor (503)
  await probar('5. Error del servidor', () => api.get('/orders?fail=503'));

  // 6. Código no contemplado (418)
  await probar('6. Código no contemplado', () => api.get('/orders?fail=418'));

  // 7. Sin conexión (NetworkFailure)
  await probar('7. Sin conexión', () => api.get('/orders'));

  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  MainApp({super.key});

  final ApiClient clientePrueba = ApiClient();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: FutureBuilder<dynamic>(
            future: clientePrueba.get('/orders'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              return Text('${snapshot.data}');
            },
          ),
        ),
      ),
    );
  }
}
