// lib/creditos_page.dart

import 'package:flutter/material.dart';
import 'app_scaffold.dart';

class CreditosPage extends StatelessWidget {
  const CreditosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Créditos y Fuentes',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Agradecimientos y Fuentes de Datos',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 30),
            
            // --- INTEGRANTES DEL EQUIPO ---
            const Text(
              'Desarrollado por:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.blue),
            ),
            const SizedBox(height: 10),
            _buildCreditItem(context, 'Integrantes:', 'Fuentes Mar Eidtan Amor'),
            
            const SizedBox(height: 30),

            // --- FUENTES DE DATOS ---
            const Text(
              'Fuentes de Información del Clima y Mapas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.blue),
            ),
            const SizedBox(height: 10),
            _buildSourceItem(
              context, 
              'Datos del Clima:', 
              'Meteomatics API', 
              'https://www.meteomatics.com'
            ),
            _buildSourceItem(
              context, 
              'Mapas:', 
              'OpenStreetMap / flutter_map', 
              'Utilizado para la visualización geográfica y selección de ciudades.'
            ),
            _buildSourceItem(
              context, 
              'Íconos de Clima:', 
              'Paquete flutter weather_icons', 
              'Utilizado para la representación visual de los estados del clima.'
            ),
            
            const SizedBox(height: 30),
            
            const Text(
              'Repositorio del Proyecto',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.blue),
            ),
            const SizedBox(height: 10),
            _buildCreditItem(context, 'GitHub Link:', 'https://github.com/FuentesMar/weather_app'),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditItem(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(content),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSourceItem(BuildContext context, String title, String source, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 5),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 5),
            Text(
              'Fuente: $source',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}