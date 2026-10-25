# Gestor Cafetería ☕

Proyecto base para la gestión de pedidos de una cafetería mediante una aplicación móvil desarrollada en Flutter. Esta app consume una API RESTful local e incluye el manejo de estados, tipado de errores HTTP (Failures) y pruebas unitarias.

## Requisitos
* Flutter SDK (versión más reciente recomendada).
* Node.js 22.13 o superior (para ejecutar el servidor local).

## El Backend (mini_backend)
Esta app funciona en conjunto con un backend ligero hecho en Node + SQLite. No está incluido en este código fuente.
* **Repositorio oficial:** [mini_backend](https://github.com/DMI-2026/mini_backend)
* **Versión probada:** Se utilizó la última versión clonada a finales de octubre de 2026.

### ¿Cómo levantar el servidor?
Abre una terminal en la carpeta donde hayas descargado el `mini_backend` y ejecuta:
```bash
node server.js
```
*(Correrá por defecto en `http://127.0.0.1:8000`)*

## ¿Cómo ejecutar la App Flutter?
Como usamos un backend local, debemos inyectar la URL base por línea de comandos para que el cliente HTTP la configure correctamente.

**Para Web o Windows (localhost):**
```bash
flutter run --dart-define API_URL=http://localhost:8000
```
**Para Emulador Android (redirección a máquina host):**
```bash
flutter run --dart-define API_URL=[http://10.0.2.2:8000](http://10.0.2.2:8000)
```

## ¿Cómo correr las pruebas?
El proyecto incluye baterías de prueba unitaria usando `MockClient` para validar los fallos de red y respuestas del servidor sin necesidad de hacer peticiones reales.
```bash
flutter test
```

## Estructura de carpetas principal
```text
lib/
 ├─ core/
 │   ├─ failure.dart      # Sealed class de los errores tipados
 │   └─ http_client.dart  # Cliente HTTP configurado para interactuar con la API
 └─ main.dart
test/                     # Pruebas unitarias del cliente HTTP
```

*Declaración de uso de IA: No se utilizó IA para la generación de este código*