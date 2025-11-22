import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'providers/city_notifier.dart';
import 'providers/weather_provider.dart';
import 'app_scaffold.dart';
import 'theme_provider.dart';
import 'agregar_ciudades_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'clima_carousel_view.dart';
import 'creditos_page.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: .env file not found or could not be loaded: $e');
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CityNotifier()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final GoRouter router = GoRouter(routes: [
      GoRoute(path: '/', builder: (context, state) => const MyHomePage(title: 'Inicio')),
      GoRoute(path: '/agregar_ciudades', builder: (context, state) => AgregarCiudadesPage()),
      GoRoute(path: '/creditos', builder: (context, state) => const CreditosPage()),
    ]);
    return MaterialApp.router(
      title: 'Weather App',
      routerConfig: router,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.themeMode,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<List<Map<String, dynamic>>> ciudadesGuardadas = Future<List<Map<String, dynamic>>>.value([]);
  static String get apiTokenUrl {
    try {
      return dotenv.env['meteomatics_api_url'] ?? 'https://login.meteomatics.com/api/v1/token';
    } catch (_) {
      return 'https://login.meteomatics.com/api/v1/token';
    }
  }

static String get username {
  try {
    // CAMBIO: Añadir .toString() para asegurar la lectura limpia
    return dotenv.env['meteomatics_user']?.toString() ?? ''; 
  } catch (_) {
    return '';
  }
}

  static String get password {
  try {
    // CAMBIO: Añadir .toString() para asegurar la lectura limpia
    return dotenv.env['meteomatics_pwd']?.toString() ?? ''; 
  } catch (_) {
    return '';
  }
}
  String apiToken = '';
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    debugPrint('API URL: $apiTokenUrl');
    debugPrint('Username: $username');
    debugPrint('Password: ${'*' * password.length}');
    obtenToken();
    // Escuchar cambios en la lista de ciudades y refrescar cuando ocurran
    final cityNotifier = Provider.of<CityNotifier>(context, listen: false);
    cityNotifier.addListener(_cargarYActualizarTodoElClima);
    // La primera carga debe realizar la actualización completa
    _cargarYActualizarTodoElClima(); 
  }

  @override
  void dispose() {
    // Remover el listener para evitar fugas
    final cityNotifier = Provider.of<CityNotifier>(context, listen: false);
    cityNotifier.removeListener(_cargarYActualizarTodoElClima);
    super.dispose();
  }
  
  Future<void> _cargarYActualizarTodoElClima() async {
    // 1. Cargamos las ciudades guardadas, sin importar si tienen datos de clima viejos o no.
    final ciudades = await _ciudadesGuardadas();
    
    if (ciudades.isEmpty) {
      setState(() {
         ciudadesGuardadas = Future.value([]);
      });
      debugPrint('No hay ciudades guardadas para actualizar el clima');
      return;
    }

    // 2. Intentamos actualizar el clima para todas las ciudades
    final ciudadesActualizadas = await _actualizaClimaDeTodas(ciudades);
    
    // 3. Actualizamos el estado con la lista final (con datos de API o con datos cacheados)
    setState(() {
      ciudadesGuardadas = Future.value(ciudadesActualizadas);
    });
  }

  Future<List<Map<String, dynamic>>> _actualizaClimaDeTodas(List<Map<String, dynamic>> ciudades) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> listaFinal = [];
    bool seLlamoALaAPI = false;

    for (var ciudad in ciudades) {
      String nombreCiudad = ciudad['nombre'] ?? 'Desconocida';
      bool debeActualizar = true;

      // LÓGICA DE CACHING POR CIUDAD (60 minutos)
      if (ciudad.containsKey('ultima_actualizacion') && ciudad['ultima_actualizacion'] != null) {
        DateTime ultimaActualizacionDT = DateTime.parse(ciudad['ultima_actualizacion']);
        DateTime ahora = DateTime.now().toUtc();
        
        // Si el último dato tiene menos de 60 minutos, usamos el cache
        if (ahora.difference(ultimaActualizacionDT).inMinutes < 60) {
          debeActualizar = false;
          debugPrint('$nombreCiudad: Usando caché (${ahora.difference(ultimaActualizacionDT).inMinutes} min.)');
        }
      }

      if (debeActualizar && apiToken.isNotEmpty) {
        // LLAMADA A LA API
        seLlamoALaAPI = true;
        final latitud = ciudad['latitud'] ?? 0.0;
        final longitud = ciudad['longitud'] ?? 0.0;
        String horaActualz = DateTime.now().toUtc().toIso8601String();
        
        String url = 'https://api.meteomatics.com/$horaActualz/t_2m:C,wind_speed_10m:ms,weather_symbol_1h:idx/$latitud,$longitud/json?access_token=$apiToken';
        
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final climaData = json.decode(response.body);
          final data = climaData['data']; 
          
          ciudad['temperatura'] = data[0]['coordinates'][0]['dates'][0]['value'];
          ciudad['velocidad_viento'] = data[1]['coordinates'][0]['dates'][0]['value'];
          ciudad['simbolo_clima'] = data[2]['coordinates'][0]['dates'][0]['value'];
          ciudad['ultima_actualizacion'] = data[0]['coordinates'][0]['dates'][0]['date'];
          
          debugPrint('$nombreCiudad: Datos de API obtenidos.');
        } else {
          debugPrint('Error al obtener el clima para $nombreCiudad: ${response.statusCode}'); 
        }
      }
      
      listaFinal.add(ciudad);
    }
    
    // GUARDAR LA LISTA COMPLETA SI HUBO ALGUNA LLAMADA EXITOSA A LA API
    if (seLlamoALaAPI) {
        List<String> nuevasCiudadesString = listaFinal.map((c) => json.encode(c)).toList();
        await prefs.setStringList('ciudades', nuevasCiudadesString);
    }

    // Retornar la lista final (ya sea con datos viejos o nuevos)
    return listaFinal;
  }
  
  // Función llamada desde ClimaCarouselView para forzar una actualización
  Future<void> _forzarActualizaClima(Map<String, dynamic> ciudad) async {
    if (apiToken.isEmpty) {
      debugPrint('No se puede actualizar el clima sin un token válido.');
      return;
    }
    
    // Obtenemos todas las ciudades
    final todasLasCiudades = await _ciudadesGuardadas();
    
    // Buscamos la ciudad actual en la lista completa
    int index = todasLasCiudades.indexWhere((c) => c['nombre'] == ciudad['nombre']);
    
    if (index == -1) return; 

    final latitud = ciudad['latitud'] ?? 0.0;
    final longitud = ciudad['longitud'] ?? 0.0;
    String horaActualz = DateTime.now().toUtc().toIso8601String();
    String url = 'https://api.meteomatics.com/$horaActualz/t_2m:C,wind_speed_10m:ms,weather_symbol_1h:idx/$latitud,$longitud/json?access_token=$apiToken';
    
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
        final climaData = json.decode(response.body);
        final data = climaData['data']; 
        
        ciudad['temperatura'] = data[0]['coordinates'][0]['dates'][0]['value'];
        ciudad['velocidad_viento'] = data[1]['coordinates'][0]['dates'][0]['value'];
        ciudad['simbolo_clima'] = data[2]['coordinates'][0]['dates'][0]['value'];
        ciudad['ultima_actualizacion'] = data[0]['coordinates'][0]['dates'][0]['date'];

        // 1. Actualizar la lista en memoria (todasLasCiudades)
        todasLasCiudades[index] = ciudad;

        // 2. Guardar la lista actualizada en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        List<String> ciudadesString = todasLasCiudades.map((c) => json.encode(c)).toList();
        await prefs.setStringList('ciudades', ciudadesString);
        
        // 3. Actualizar la UI
        if (mounted) {
            setState(() {
                ciudadesGuardadas = Future.value(todasLasCiudades);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${ciudad['nombre']} actualizada con éxito.')),
            );
        }
    } else {
        debugPrint('Error al forzar actualización: ${response.statusCode}'); 
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al actualizar el clima.')),
          );
        }
    }
  }

  Future<List<Map<String, dynamic>>> _ciudadesGuardadas() async {
    final prefs = await SharedPreferences.getInstance();
    final ciudadesString = prefs.getStringList('ciudades') ?? [];
    return ciudadesString.map((ciudad) => json.decode(ciudad) as Map<String, dynamic>).toList();
  }
void obtenToken() async {
  if (apiToken.isNotEmpty) return;
  String url = apiTokenUrl;

  // CREACIÓN DE LA CADENA DE AUTENTICACIÓN
  final authString = '$username:$password';
  
  // CODIFICACIÓN ESTRICTA EN BASE64
  final base64Auth = base64Encode(utf8.encode(authString));

  final response = await http.get(Uri.parse(url), headers: {
    // ESTA LÍNEA DEBE USAR LA CADENA CODIFICADA:
    'Authorization': 'Basic $base64Auth', 
  });

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    setState(() {
      apiToken = data['access_token'];
    });
    debugPrint('Token obtenido: $apiToken');
    await _cargarYActualizarTodoElClima();
  } else {
    debugPrint('Error al obtener el token: ${response.statusCode}');
    debugPrint('Error: No se pudo obtener el token con las credenciales proporcionadas.');
  }
}

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.title,
      body: ClimaCarouselView(
        ciudadesGuardadas: ciudadesGuardadas,
        actualizaClima: _forzarActualizaClima, // Usamos la función refactorizada
      ),
    );
  }
}