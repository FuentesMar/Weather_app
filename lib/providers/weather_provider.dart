import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherProvider extends ChangeNotifier {
  String _apiToken = '';

  static String get _apiTokenUrl {
    try {
      return dotenv.env['meteomatics_api_url'] ?? 'https://login.meteomatics.com/api/v1/token';
    } catch (_) {
      return 'https://login.meteomatics.com/api/v1/token';
    }
  }

  static String get _username {
    try {
      return dotenv.env['meteomatics_user'] ?? '';
    } catch (_) {
      return '';
    }
  }

  static String get _password {
    try {
      return dotenv.env['meteomatics_pwd'] ?? '';
    } catch (_) {
      return '';
    }
  }

  static String? get _tokenFromEnv {
    try {
      return dotenv.env['meteomatics_token'];
    } catch (_) {
      return null;
    }
  }

  Future<void> _obtenToken() async {
    if (_apiToken.isNotEmpty) return;

    // Si se proporcionó un token directo en el .env úsalo inmediatamente.
    final envToken = _tokenFromEnv;
    if (envToken != null && envToken.isNotEmpty) {
      _apiToken = envToken;
      if (kDebugMode) print('Using METEOMATICS token from .env');
      return;
    }

    // Si no hay token directo, intentar obtenerlo vía usuario/clave si están presentes
    if (_username.isEmpty || _password.isEmpty) {
      if (kDebugMode) print('No credentials provided for Meteomatics token.');
      return;
    }

    final url = _apiTokenUrl;
    final response = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Basic ${base64Encode(utf8.encode('$_username:$_password'))}',
    });
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _apiToken = data['access_token'] ?? '';
    } else {
      if (kDebugMode) print('Token request failed: ${response.statusCode}');
    }
  }

  /// Consulta el clima para las coordenadas dadas y guarda la ciudad actualizada
  /// en SharedPreferences bajo la clave `ciudades`.
  Future<void> fetchAndSaveCityWeather(String nombre, double lat, double lon) async {
    await _obtenToken();
    if (_apiToken.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final ciudadesString = prefs.getStringList('ciudades') ?? [];
    List<Map<String, dynamic>> ciudades = ciudadesString.map((s) => json.decode(s) as Map<String, dynamic>).toList();

    // Buscar índice de la ciudad (por nombre)
    final index = ciudades.indexWhere((c) => c['nombre'] == nombre);

    // Preparar URL de Meteomatics (ajustar variables necesarias según su API)
    final hora = DateTime.now().toUtc().toIso8601String();
    final url = 'https://api.meteomatics.com/$hora/t_2m:C,wind_speed_10m:ms,weather_symbol_1h:idx/$lat,$lon/json?access_token=$_apiToken';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final climaData = json.decode(response.body);
        final data = climaData['data'];

        final temperatura = data[0]['coordinates'][0]['dates'][0]['value'];
        final viento = data[1]['coordinates'][0]['dates'][0]['value'];
        final simbolo = data[2]['coordinates'][0]['dates'][0]['value'];
        final fecha = data[0]['coordinates'][0]['dates'][0]['date'];

        final ciudadMap = {
          'nombre': nombre,
          'latitud': lat,
          'longitud': lon,
          'temperatura': temperatura,
          'velocidad_viento': viento,
          'simbolo_clima': simbolo,
          'ultima_actualizacion': fecha,
        };

        if (index >= 0) {
          ciudades[index] = ciudadMap;
        } else {
          ciudades.add(ciudadMap);
        }

        final nuevas = ciudades.map((c) => json.encode(c)).toList();
        await prefs.setStringList('ciudades', nuevas);
        notifyListeners();
      } else {
        // No actualizamos si falla la consulta; se deja lo que haya
        if (kDebugMode) print('Error Meteomatics: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('Error fetchWeather: $e');
    }
  }
}
