


import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});




  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS Comparativa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Indigo
          brightness: Brightness.dark,
        ),
      ),
      home: const GpsLocationScreen(),
    );
  }
}

class GpsLocationScreen extends StatefulWidget {
  const GpsLocationScreen({super.key});

  @override
  State<GpsLocationScreen> createState() => _GpsLocationScreenState();
}

class _GpsLocationScreenState extends State<GpsLocationScreen> {
  Position? _currentPosition;
  String _statusMessage = 'Presiona el botón para obtener la ubicación de alta precisión.';
  bool _isLoading = false;

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Verificando servicio y permisos de ubicación...';
      _currentPosition = null;
    });

    try {
      // 1. Verificar si los servicios de ubicación (GPS) están encendidos en el dispositivo.
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const LocationServiceDisabledException();
      }

      // 2. Verificar y solicitar los permisos nativos correspondientes.
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _statusMessage = 'Permiso denegado. Para usar la funcionalidad GPS, debes conceder los permisos.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Permisos denegados permanentemente. Por favor, habilítalos desde la configuración del sistema.';
        });
        return;
      }

      // 3. Obtener la ubicación actual con precisión alta.
      setState(() {
        _statusMessage = 'Estableciendo conexión con satélites GPS...';
      });

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
        _statusMessage = 'Ubicación obtenida exitosamente.';
      });
    } on LocationServiceDisabledException {
      setState(() {
        _isLoading = false;
        _statusMessage = 'El GPS / Servicio de ubicación está apagado en este dispositivo.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Ocurrió un error inesperado al obtener la ubicación: $e';
      });
    }
  }

  Future<void> _openGoogleMaps() async {
    if (_currentPosition == null) return;
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${_currentPosition!.latitude},${_currentPosition!.longitude}'
    );
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'No se puede abrir el enlace de mapas.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir Google Maps: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Encabezado
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.gps_fixed_rounded,
                        color: theme.colorScheme.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GPS Comparativa',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          Text(
                            'Precisión nativa en tiempo real',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Panel principal de Estado y Datos
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildStatusCard(theme),
                        const SizedBox(height: 24),
                        if (_currentPosition != null) _buildDataPanel(theme),
                      ],
                    ),
                  ),
                ),

                // Panel de Botones de Acción
                _buildActionButtons(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    IconData icon;
    Color iconColor;
    
    if (_isLoading) {
      icon = Icons.hourglass_top_rounded;
      iconColor = theme.colorScheme.primary;
    } else if (_currentPosition != null) {
      icon = Icons.check_circle_rounded;
      iconColor = Colors.tealAccent;
    } else if (_statusMessage.contains('denegado') || _statusMessage.contains('desactivado') || _statusMessage.contains('error')) {
      icon = Icons.warning_amber_rounded;
      iconColor = theme.colorScheme.error;
    } else {
      icon = Icons.satellite_alt_rounded;
      iconColor = theme.colorScheme.onSurfaceVariant;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      color: theme.colorScheme.surface.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Column(
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: iconColor),
              ),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataPanel(ThemeData theme) {
    final pos = _currentPosition!;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Datos del Sensor GPS',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            _buildDataRow(
              theme,
              icon: Icons.explore_rounded,
              label: 'Latitud',
              value: '${pos.latitude.toStringAsFixed(8)}°',
            ),
            _buildDataRow(
              theme,
              icon: Icons.explore_outlined,
              label: 'Longitud',
              value: '${pos.longitude.toStringAsFixed(8)}°',
            ),
            _buildDataRow(
              theme,
              icon: Icons.gps_fixed_rounded,
              label: 'Precisión',
              value: '± ${pos.accuracy.toStringAsFixed(2)} m',
            ),
            _buildDataRow(
              theme,
              icon: Icons.filter_hdr_rounded,
              label: 'Altitud',
              value: '${pos.altitude.toStringAsFixed(2)} m s.n.m.',
            ),
            _buildDataRow(
              theme,
              icon: Icons.speed_rounded,
              label: 'Velocidad',
              value: '${pos.speed.toStringAsFixed(2)} m/s (${(pos.speed * 3.6).toStringAsFixed(2)} km/h)',
            ),
            _buildDataRow(
              theme,
              icon: Icons.update_rounded,
              label: 'Última Lectura',
              value: pos.timestamp.toLocal().toString().split('.')[0],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openGoogleMaps,
                icon: const Icon(Icons.map_rounded),
                label: const Text('Abrir en Google Maps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(ThemeData theme, {required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    final bool isDeniedForever = _statusMessage.contains('permanentemente');
    final bool isServiceDisabled = _statusMessage.contains('apagado');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isDeniedForever || isServiceDisabled) ...[
          OutlinedButton.icon(
            onPressed: () async {
              if (isServiceDisabled) {
                await Geolocator.openLocationSettings();
              } else {
                await Geolocator.openAppSettings();
              }
            },
            icon: const Icon(Icons.settings_suggest_rounded),
            label: Text(
              isServiceDisabled
                  ? 'Abrir Ajustes de Ubicación'
                  : 'Abrir Configuración de la App',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: BorderSide(color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 12),
        ],
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _getCurrentLocation,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.satellite_alt_rounded),
          label: Text(_isLoading ? 'Sintonizando Satélites...' : 'Obtener Ubicación GPS'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      ],
    );
  }
}
