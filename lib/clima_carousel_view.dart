import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:intl/intl.dart';

class ClimaCarouselView extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> ciudadesGuardadas;
  final Function(Map<String, dynamic>) actualizaClima;
  const ClimaCarouselView({
    super.key,
    required this.ciudadesGuardadas,
    required this.actualizaClima,
  });
  @override
  State<ClimaCarouselView> createState() => _ClimaCarouselViewState();
}

class _ClimaCarouselViewState extends State<ClimaCarouselView> {
  int _currentIndex = 0; 
  IconData _obtenerIconoClima(int simbolo) {
    switch (simbolo) {
      case 0:
        return WeatherIcons.na;
      case 1:
        return WeatherIcons.day_sunny;
      case 2:
        return WeatherIcons.day_sunny_overcast;
      case 3:
        return WeatherIcons.day_cloudy;
      case 4:
        return WeatherIcons.cloudy;
      case 5:
        return WeatherIcons.day_rain; 
      case 6:
        return WeatherIcons.day_sleet;
      case 7:
        return WeatherIcons.day_snow;
      case 8:
        return WeatherIcons.day_showers;
      case 9:
        return WeatherIcons.day_sleet_storm;
      case 10:
        return WeatherIcons.day_snow_wind;
      case 11:
        return WeatherIcons.day_fog;
      case 12:
        return WeatherIcons.fog;
      case 13:
        return WeatherIcons.day_rain_mix;
      case 14:
        return WeatherIcons.thunderstorm;
      case 15:
        return WeatherIcons.day_sprinkle;
      case 16:
        return WeatherIcons.sandstorm;
      case 101:
        return WeatherIcons.night_clear;
      case 102:
        return WeatherIcons.night_cloudy_gusts;
      case 103:
        return WeatherIcons.night_alt_partly_cloudy;
      case 104:
        return WeatherIcons.night_rain;
      case 105:
        return WeatherIcons.night_sleet;
      case 106:
        return WeatherIcons.night_snow;
      case 107:
        return WeatherIcons.night_showers;
      case 108:
        return WeatherIcons.night_sleet_storm;
      case 109:
        return WeatherIcons.night_snow_wind;
      case 110:
        return WeatherIcons.night_cloudy_windy;
      case 111:
        return WeatherIcons.night_fog;
      case 112:
        return WeatherIcons.fog;
      case 113:
        return WeatherIcons.night_rain_mix;
      case 114: 
        return WeatherIcons.night_thunderstorm;
      case 115:
        return WeatherIcons.night_sprinkle;
      case 116:
        return WeatherIcons.night_alt_sleet_storm;
      default:
        return WeatherIcons.na;
    }
  }

  String _obtenerDescripcionClima(int simbolo) {
    switch (simbolo) {
      case 0:
        return 'Sin datos';
      case 1:
        return 'Despejado';
      case 2:
        return 'Mayormente despejado';
      case 3:
        return 'Parcialmente Nublado';
      case 4:
        return 'Nublado';
      case 5:
        return 'Lluvia';
      case 6:
        return 'Agua Nieve';
      case 7:
        return 'Nevado';
      case 8:
        return 'Lluvia intensa';
      case 9:
        return 'Nevisa';
      case 10:
        return 'Lluvia intensa de Aguanieve';
      case 11:
        return 'Niebla ligera';
      case 12:
        return 'Niebla densa';
      case 13:
        return 'Lluvia helada';
      case 14:
        return 'Tormenta eléctrica';
      case 15:
        return 'LLovizna';
      case 16:
        return 'Tormenta de arena';
      case 101:
        return 'Despejadon (noche)';
      case 102:
        return 'Mayormente despejado (noche)';
      case 103:
        return 'Parcialmente Nublado (noche)';
      case 104:
        return 'Nublado (noche)';
      case 105:
        return 'Lluvia (noche)';
      case 106:
        return 'Agua Nieve (noche)';
      case 107:
        return 'Nevado (noche)';
      case 108:
        return 'Lluvia intensa (noche)';
      case 109:
        return 'Nevisa (noche)';
      case 110:
        return 'Lluvia intensa de Aguanieve (noche)';
      case 111:
        return 'Niebla ligera (noche)';
      case 112:
        return 'Niebla densa (noche)';
      case 113:
        return 'Lluvia helada (noche)';
      case 114:
        return 'Tormenta eléctrica (noche)';
      case 115:
        return 'LLovizna (noche)';
      case 116:
        return 'Tormenta de arena (noche)';
      default:
        return 'Desconocido';
    }
  }

  // Tu función para formatear la hora (Mantenida)
  String _formatearHora(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return 'Desconocido';
    try {
      final fecha = DateTime.parse(timestamp);
      return DateFormat('HH:mm').format(fecha.toLocal());
    } catch (e) {
      return 'Desconocido';
    }
  }

  // NUEVA: Función para el gradiente dinámico
  List<Color> _getGradientColors(int simboloInt) {
    // DÍA (1-99)
    if (simboloInt >= 1 && simboloInt < 100) {
      if (simboloInt <= 3) { // Despejado o Parcialmente Despejado
        return [const Color(0xFF4FA0C9), const Color(0xFF4C81AF)]; // Azul cielo
      } else if (simboloInt >= 4 && simboloInt <= 10) { // Nublado, Lluvia, Niebla
        return [const Color(0xFF90A4AE), const Color(0xFF607D8B)]; // Gris / Azul Pálido
      } else if (simboloInt > 10) { // Tormenta, nieve
        return [const Color(0xFF455A64), const Color(0xFF263238)]; // Gris Oscuro
      }
    } 
    // NOCHE (100+)
    else if (simboloInt >= 100) {
      return [const Color(0xFF0D1B2A), const Color(0xFF1B2A41)]; // Azul noche/índigo
    }
    

    return [Colors.blue.shade400, Colors.blue.shade700];
  }
  Widget _buildDetailColumn(IconData icon, String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 30, color: color),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 14, color: color.withOpacity(0.7))),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: widget.ciudadesGuardadas,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           // Uso de gradiente predeterminado para el loading
           return Container(
             decoration: BoxDecoration(
               gradient: LinearGradient(
                 begin: Alignment.topCenter,
                 end: Alignment.bottomCenter,
                 colors: [Colors.blue.shade400, Colors.blue.shade700],
               ),
             ),
             child: const Center(
               child: CircularProgressIndicator(color: Colors.white),
             ),
           );
        }
        if (snapshot.hasError) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.red.shade400, Colors.red.shade700], 
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 50),
                  const SizedBox(height: 10),
                  Text(
                    'Error al cargar ciudades: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        }
        final ciudades = snapshot.data ?? [];
        final ciudadesOrdenadas = List<Map<String, dynamic>>.from(ciudades);
        ciudadesOrdenadas.sort((a, b) => (a['nombre'] ?? '').toString().toLowerCase().compareTo(
                (b['nombre'] ?? '').toString().toLowerCase()));
        
        if (ciudadesOrdenadas.isEmpty) {
          return Container(
            decoration: BoxDecoration(
               gradient: LinearGradient(
                 begin: Alignment.topCenter,
                 end: Alignment.bottomCenter,
                 colors: [Colors.blue.shade400, Colors.blue.shade700],
               ),
             ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, color: Colors.white, size: 60),
                  SizedBox(height: 20),
                  Text(
                    'No hay ciudades guardadas',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          );
        }
        
        return _buildCarousel(ciudadesOrdenadas);
      },
    );
  }

  Widget _buildCarousel(List<Map<String, dynamic>> ciudades) {
    return Stack(
      children: [
        PageView.builder(
          itemCount: ciudades.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return _buildCiudadCard(ciudades[index]);
          },
        ),
        
        // Botón de refresco (Mantenido)
        Positioned(
          top: 50,
          right: 20,
          child: IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              if (_currentIndex < ciudades.length) {
                widget.actualizaClima(ciudades[_currentIndex]);
              }
            },
          ),
        ),
      ],
    ); 
  }

  Widget _buildCiudadCard(Map<String, dynamic> ciudad) {
    final temperatura = ciudad['temperatura'] ?? 0.0;
    final simboloClima = ciudad['simbolo_clima'] as int? ?? 0;
    final velocidadViento = ciudad['velocidad_viento'] ?? 0.0;
    final nombre = ciudad['nombre'] ?? 'Desconocido';
    final ultimaActualizacion = ciudad['ultima_actualizacion'] ?? '';

    final List<Color> backgroundColors = _getGradientColors(simboloClima);
    final IconData climaIcono = _obtenerIconoClima(simboloClima);

    return Container(
      // Aplicamos el Gradiente Dinámico aquí
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: backgroundColors,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
          child: Column(
            // Utilizamos spaceBetween para distribuir el contenido
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. SECCIÓN SUPERIOR: Nombre de la ciudad
              Text(
                nombre, 
                style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              
              // 2. SECCIÓN CENTRAL: Icono, Temperatura y Descripción
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(climaIcono, size: 120, color: Colors.white),
                    const SizedBox(height: 10),
                    // Temperatura (con °C separado para mejor control de estilo)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start, // Alineación vertical
                      children: [
                        Text(
                          '${temperatura.round()}', // Redondeamos para mayor impacto visual
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 100, // Más grande
                            fontWeight: FontWeight.w200,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 15), // Ajuste vertical
                          child: Text(
                            '°C',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Descripción del clima
                    Text(
                      _obtenerDescripcionClima(simboloClima),
                      style: const TextStyle(fontSize: 22, color: Colors.white70, fontWeight: FontWeight.w300),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // 3. SECCIÓN INFERIOR: Viento y Última Actualización (Centrados y Agrupados)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                // Usamos una decoración suave para destacar los detalles
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    // DETALLE 1: VIENTO
                    _buildDetailColumn(
                      Icons.air, 
                      '${velocidadViento.toStringAsFixed(1)} m/s', 
                      'Viento', 
                      Colors.white
                    ),
                    
                    // Separador vertical
                    Container(width: 1, height: 40, color: Colors.white54),
                    
                    // DETALLE 2: ÚLTIMA ACTUALIZACIÓN
                    _buildDetailColumn(
                      Icons.schedule, 
                      _formatearHora(ultimaActualizacion), 
                      'Actualización', 
                      Colors.white
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}