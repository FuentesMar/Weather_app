import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'app_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'providers/city_notifier.dart';
import 'providers/weather_provider.dart';
import 'package:go_router/go_router.dart';

class AgregarCiudadesPage extends StatefulWidget {
  const AgregarCiudadesPage({super.key});
  @override
  State<AgregarCiudadesPage> createState() => _AgregarCiudadesPageState();
}

class _AgregarCiudadesPageState extends State<AgregarCiudadesPage> {
  final TextEditingController _cityController = TextEditingController();
  final MapController _mapController = MapController();
  List ciudadData = [];
  bool _isSearching = false;
  String? _searchError;
  double dLat = 29.0948207;
  double dLon = -110.9692202;
  double selectedLat = 29.0948207;
  double selectedLon = -110.9692202;
  int? selectedIndex;
  Future<List<Map<String, dynamic>>> ciudadesGuardadas =
      Future<List<Map<String, dynamic>>>.value([]);

  @override
  void initState() {
    super.initState();
    ciudadesGuardadas = _ciudadesGuardadas();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Administrar Ciudades",
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. SECCIÓN DE BÚSQUEDA ---
              _buildSearchSection(context),
              const SizedBox(height: 20),

              // --- 2. RESULTADOS DE BÚSQUEDA ---
              _buildSearchResults(context),
              const SizedBox(height: 30),

              // --- BOTÓN DE AGREGAR ---
              ElevatedButton.icon(
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text("Agregar Ciudad Seleccionada"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {
                  if (_cityController.text.isNotEmpty &&
                      selectedIndex != null) {
                    _agregarCiudad(
                      _cityController.text,
                      selectedLat,
                      selectedLon,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Por favor, busca y selecciona una ciudad.',
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 30),

              // --- 3. CIUDADES GUARDADAS ---
              Text(
                "Tus Ciudades Guardadas",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildSavedCitiesList(),
              const SizedBox(height: 30),

              // --- 4. MAPA (Para previsualización) ---
              _buildMapSection(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Busca una Ciudad", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        TextField(
          controller: _cityController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            hintText: 'Ingresa el nombre de la ciudad',
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () async {
                final ciudad = _cityController.text;
                if (ciudad.isNotEmpty) {
                  setState(() {
                    _isSearching = true;
                    _searchError = null;
                  });
                  final resultados = await _buscarCiudad(ciudad);
                  if (!mounted) return;
                  setState(() {
                    ciudadData = resultados;
                    selectedIndex = null;
                    _isSearching = false;
                  });
                  if (resultados.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No se encontraron resultados.')),
                    );
                  }
                }
              },
            ),
          ),
          onSubmitted: (value) async {
            final resultados = await _buscarCiudad(value);
            if (!mounted) return;
            setState(() {
              ciudadData = resultados;
              selectedIndex = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (ciudadData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(10.0),
          child: Text("Busca una ciudad para ver los resultados aquí."),
        ),
      );
    }

    // Mostrar error de búsqueda si existe
    if (_searchError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            _searchError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      padding: const EdgeInsets.all(8.0),
      height: 200,
      child: ListView.builder(
        itemCount: ciudadData.length,
        itemBuilder: (context, index) {
          final ciudadInfo = ciudadData[index];

          return Card(
            color: selectedIndex == index
                ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                : null,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.pin_drop, color: Colors.blueGrey),
              title: Text(
                ciudadInfo['display_name'],
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Lat: ${ciudadInfo['lat'].substring(0, 7)}, Lon: ${ciudadInfo['lon'].substring(0, 7)}',
              ),
              onTap: () {
                setState(() {
                  selectedIndex = index;
                  _cityController.text = ciudadInfo['display_name'];
                  selectedLat = double.parse(ciudadInfo['lat']);
                  selectedLon = double.parse(ciudadInfo['lon']);
                  _mapController.move(LatLng(selectedLat, selectedLon), 10);
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSavedCitiesList() {
    return SizedBox(
      height: 200,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: ciudadesGuardadas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Text('Error al cargar ciudades: ${snapshot.error}');
          }
          final data = snapshot.data ?? const <Map<String, dynamic>>[];
          if (data.isEmpty) {
            return const Center(child: Text('No hay ciudades guardadas.'));
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final ciudad = data[index];
              return Card(
                elevation: 2.0, 
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: ListTile(
                  leading: const Icon(Icons.location_city_outlined),
                  title: Text(
                    ciudad['nombre'].toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // Añadimos el botón de eliminar 
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      _eliminarCiudad(ciudad['nombre'].toString());
                    },
                  ),
                  subtitle: Text(
                    'Lat: ${ciudad["latitud"]}°, Lon: ${ciudad["longitud"]}°',
                  ),
                  onTap: () {
                    _mapController.move(
                      LatLng(ciudad["latitud"], ciudad["longitud"]),
                      10,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMapSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Ubicación Seleccionada en el Mapa",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              10,
            ), // Borde redondeado 
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(selectedLat, selectedLon),
                initialZoom: 10,
                maxZoom: 18,
                minZoom: 3,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.weather_app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(selectedLat, selectedLon),
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<List> _buscarCiudad(String nombreCiudad) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': nombreCiudad,
        'format': 'json',
        'addressdetails': '1',
      });

      String contact;
      try {
        contact = dotenv.env['nominatim_contact'] ?? 'noreply@example.com';
      } catch (e) {
        if (kDebugMode) print('dotenv not initialized when reading nominatim_contact: $e');
        contact = 'noreply@example.com';
      }

      final headers = {
        'User-Agent': 'weather_app/1.0 (contact: $contact)',
        'Accept': 'application/json',
        'From': contact,
      };

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data;
      } else {
        if (kDebugMode) {
          print('Nominatim returned ${response.statusCode}');
          try {
            print('Nominatim body: ${response.body}');
          } catch (_) {}
        }
        final bodyLower = response.body.toLowerCase();
        final blocked = response.statusCode == 403 || bodyLower.contains('access blocked') || bodyLower.contains('request blocked');

        if (blocked) {
          if (kDebugMode) print('Nominatim parece haber bloqueado la IP/cliente. Probando fallback.');
          final fallback = await _buscarConLocationIQ(nombreCiudad);
          if (fallback.isNotEmpty) return fallback;
        }
        try {
          if (mounted) {
            setState(() {
              _searchError = 'Error ${response.statusCode} al buscar en Nominatim. Si persiste, configura LOCATIONIQ_KEY en .env para usar un proveedor alternativo.';
            });
          }
        } catch (_) {}

        return [];
      }
    } catch (e) {
      if (kDebugMode) print('Error buscarCiudad: $e');
      return [];
    }
  }

  Future<List> _buscarConLocationIQ(String nombreCiudad) async {
    String? key;
    try {
      key = dotenv.env['LOCATIONIQ_KEY'];
    } catch (e) {
      if (kDebugMode) print('dotenv not initialized when reading LOCATIONIQ_KEY: $e');
      key = null;
    }

    if (key == null || key.isEmpty) {
      if (kDebugMode) print('No LOCATIONIQ_KEY in .env; skipping fallback.');
      return [];
    }

    try {
      final uri = Uri.https('us1.locationiq.com', '/v1/search.php', {
        'key': key,
        'q': nombreCiudad,
        'format': 'json',
        'addressdetails': '1',
      });

      final response = await http.get(uri, headers: {
        'User-Agent': 'weather_app/1.0 (fallback: LocationIQ)'
      });

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final normalized = data.map<Map<String, dynamic>>((item) {
          return {
            'display_name': item['display_name'] ?? (item['licence'] ?? nombreCiudad),
            'lat': item['lat'] ?? item['latitude'] ?? '0',
            'lon': item['lon'] ?? item['longitude'] ?? '0',
            'address': item['address'] ?? {},
          };
        }).toList();

        return normalized;
      } else {
        if (kDebugMode) print('LocationIQ returned ${response.statusCode}');
        return [];
      }
    } catch (e) {
      if (kDebugMode) print('Error LocationIQ: $e');
      return [];
    }
  }

  void _agregarCiudad(String nombre, double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> listaciudadesGuardadas = prefs.getStringList('ciudades') ?? [];

    String ciudadString = json.encode({
      'nombre': nombre,
      'latitud': lat,
      'longitud': lon,
      'temperatura': 0.0,
      'velocidad_viento': 0.0,
      'simbolo_clima': 0,
      'ultima_actualizacion': null,
    });

    listaciudadesGuardadas.add(ciudadString);
    await prefs.setStringList('ciudades', listaciudadesGuardadas);

    // Intentar cargar el clima inmediatamente para la ciudad añadida
    try {
      final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
      await weatherProvider.fetchAndSaveCityWeather(nombre, lat, lon);
    } catch (e) {
      // Si falla el provider, igual notificamos a la app para que recargue
      if (kDebugMode) print('No se pudo usar WeatherProvider: $e');
      try {
        Provider.of<CityNotifier>(context, listen: false).notifyCitiesChanged();
      } catch (_) {}
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Ciudad agregada: $nombre')));
    setState(() {
      ciudadesGuardadas = _ciudadesGuardadas();
      selectedIndex = null; 
      _cityController.clear(); 
    });
    Future.microtask(() => context.go('/'));
  }

  Future<List<Map<String, dynamic>>> _ciudadesGuardadas() async {
    final prefs = await SharedPreferences.getInstance();
    final ciudadesString = prefs.getStringList('ciudades') ?? [];
    return ciudadesString
        .map((ciudadStr) => json.decode(ciudadStr) as Map<String, dynamic>)
        .toList();
  }

  void _eliminarCiudad(String nombreCiudad) async {
    final prefs = await SharedPreferences.getInstance();
    final ciudadesString = prefs.getStringList('ciudades') ?? [];

    final nuevasCiudadesString = ciudadesString.where((jsonStr) {
      final ciudad = json.decode(jsonStr) as Map<String, dynamic>;
      return ciudad['nombre'] != nombreCiudad;
    }).toList();

    await prefs.setStringList('ciudades', nuevasCiudadesString);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Ciudad eliminada: $nombreCiudad')));

    setState(() {
      ciudadesGuardadas = _ciudadesGuardadas(); // Refrescar la lista
    });
  }
}
