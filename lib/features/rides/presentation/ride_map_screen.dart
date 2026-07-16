import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/services/api_client.dart';
import '../../auth/domain/user_profile.dart';

class RideMapScreen extends ConsumerStatefulWidget {
  final Ride ride;
  final bool isDriver;

  const RideMapScreen({
    super.key,
    required this.ride,
    required this.isDriver,
  });

  @override
  ConsumerState<RideMapScreen> createState() => _RideMapScreenState();
}

class _RideMapScreenState extends ConsumerState<RideMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _driverPosition;
  bool _loading = true;
  String? _errorMessage;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    if (widget.isDriver) {
      _startDriverTracking();
    } else {
      _startPassengerPolling();
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  // --- LOGICA AUTISTA ---
  Future<void> _startDriverTracking() async {
    try {
      // 1. Verifica ed eventualmente richiedi i permessi
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'I servizi di localizzazione sono disattivati. Attivali nelle impostazioni.';
          _loading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Permesso di geolocalizzazione negato.';
            _loading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'I permessi di geolocalizzazione sono negati permanentemente. Abilitali dalle impostazioni.';
          _loading = false;
        });
        return;
      }

      // 2. Ottieni la posizione iniziale
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      final initialLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _driverPosition = initialLatLng;
        _loading = false;
      });

      // 3. Invia la prima posizione al backend
      await _sendLocationToBackend(initialLatLng);
      if (!mounted) return;

      // 4. Avvia il timer di polling per aggiornare e inviare la posizione ogni 10 secondi
      _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
        try {
          Position pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          if (!mounted) return;
          final latLng = LatLng(pos.latitude, pos.longitude);
          setState(() {
            _driverPosition = latLng;
          });
          await _sendLocationToBackend(latLng);
        } catch (e) {
          debugPrint('Errore nel recupero della posizione dell\'autista: $e');
        }
      });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Errore durante l\'inizializzazione del tracciamento GPS.';
        _loading = false;
      });
    }
  }

  Future<void> _sendLocationToBackend(LatLng coords) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.dio.post(
        'rides/${widget.ride.id}/location',
        data: {
          'latitude': coords.latitude,
          'longitude': coords.longitude,
        },
      );
      debugPrint('Posizione autista inviata con successo: ${coords.latitude}, ${coords.longitude}');
    } catch (e) {
      debugPrint('Errore nell\'invio della posizione al backend: $e');
    }
  }

  // --- LOGICA PASSEGGERO ---
  void _startPassengerPolling() {
    // Effettua subito la prima chiamata
    _fetchDriverLocation();

    // Avvia il timer di polling per chiedere la posizione al backend ogni 10 secondi
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchDriverLocation();
    });
  }

  Future<void> _fetchDriverLocation() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get('rides/${widget.ride.id}/location');
      if (!mounted) return;
      
      if (response.statusCode == 200 && response.data != null) {
        final lat = response.data['latitude'] as double;
        final lng = response.data['longitude'] as double;
        final newPosition = LatLng(lat, lng);

        setState(() {
          _driverPosition = newPosition;
          _loading = false;
          _errorMessage = null;
        });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.response?.statusCode == 404) {
        setState(() {
          _errorMessage = 'L\'autista non ha ancora avviato la condivisione della posizione.';
          _loading = false;
        });
      } else {
        setState(() {
          _errorMessage = e.message ?? 'Impossibile caricare la posizione dell\'autista.';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Errore nel caricamento della posizione.';
        _loading = false;
      });
    }
  }

  void _centerOnDriver() {
    if (_driverPosition != null) {
      _mapController.move(_driverPosition!, 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: Text(
          widget.isDriver ? 'Tracciamento Corsa' : 'Posizione Autista',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _buildBody(),
      floatingActionButton: _driverPosition != null
          ? FloatingActionButton(
              onPressed: _centerOnDriver,
              backgroundColor: AppColors.universityGreen,
              foregroundColor: Colors.white,
              child: const Icon(Icons.my_location),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.universityGreen,
        ),
      );
    }

    if (_errorMessage != null && _driverPosition == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off_outlined, size: 64, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              if (!widget.isDriver) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _loading = true);
                    _fetchDriverLocation();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Riprova'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.universityGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Posizione di default se non ancora disponibile per la visualizzazione iniziale
    final initialPos = _driverPosition ?? const LatLng(41.5602, 14.6585);

    return Stack(
      children: [
        // Mappa
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialPos,
            initialZoom: 15.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.unimove.app',
            ),
            if (_driverPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _driverPosition!,
                    width: 60,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.deepBlack.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.universityGreen, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Icon(
                        widget.isDriver ? Icons.person : Icons.directions_car_filled,
                        color: AppColors.universityGreen,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),

        // Info Card in sovrapposizione in alto
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.ride.departureCity} ➔ ${widget.ride.arrivalCity}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'In Corso',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isDriver
                      ? 'Stai condividendo la tua posizione con i passeggeri'
                      : 'Guidatore: ${widget.ride.driverFullName}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                if (!widget.isDriver && _driverPosition != null) ...[
                  const Divider(color: Colors.white10, height: 16),
                  const Row(
                    children: [
                      Icon(Icons.sync, size: 14, color: AppColors.universityGreen),
                      SizedBox(width: 6),
                      Text(
                        'Aggiornato ogni 10 secondi',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }
}
