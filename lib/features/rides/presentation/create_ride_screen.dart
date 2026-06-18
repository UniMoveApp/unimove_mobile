import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/services/api_client.dart';
import '../../../shared/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';

class CreateRideScreen extends ConsumerStatefulWidget {
  const CreateRideScreen({super.key});

  @override
  ConsumerState<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends ConsumerState<CreateRideScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controller per i campi di testo
  final _departureCityController = TextEditingController();
  final _arrivalCityController = TextEditingController();
  final _departureTimeController = TextEditingController();
  final _arrivalTimeEstController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _hotspot1Controller = TextEditingController();
  final _hotspot2Controller = TextEditingController();
  final _hotspot3Controller = TextEditingController();
  final _travelPreferencesController = TextEditingController();

  // Stati interni
  DateTime? _departureDateTime;
  DateTime? _arrivalTimeEstDateTime;
  int _totalSeats = 4;
  bool _isLoading = false;

  @override
  void dispose() {
    _departureCityController.dispose();
    _arrivalCityController.dispose();
    _departureTimeController.dispose();
    _arrivalTimeEstController.dispose();
    _vehicleModelController.dispose();
    _vehiclePlateController.dispose();
    _hotspot1Controller.dispose();
    _hotspot2Controller.dispose();
    _hotspot3Controller.dispose();
    _travelPreferencesController.dispose();
    super.dispose();
  }

  // Selettore personalizzato di Data e Ora
  Future<DateTime?> _selectDateTime({DateTime? initialDate, DateTime? firstDate}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now().add(const Duration(minutes: 10)),
      firstDate: firstDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.universityGreen,
                  onPrimary: Colors.white,
                  surface: AppColors.surfaceDark,
                ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return null;

    if (!mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate ?? DateTime.now().add(const Duration(minutes: 10))),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.universityGreen,
                  onPrimary: Colors.white,
                  surface: AppColors.surfaceDark,
                ),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final hotspots = <String>[];
      if (_hotspot1Controller.text.trim().isNotEmpty) {
        hotspots.add(_hotspot1Controller.text.trim());
      }
      if (_hotspot2Controller.text.trim().isNotEmpty) {
        hotspots.add(_hotspot2Controller.text.trim());
      }
      if (_hotspot3Controller.text.trim().isNotEmpty) {
        hotspots.add(_hotspot3Controller.text.trim());
      }

      final requestData = {
        'departureCity': _departureCityController.text.trim(),
        'departureTime': _departureDateTime!.toIso8601String().split('.').first,
        'arrivalCity': _arrivalCityController.text.trim(),
        'arrivalTimeEst': _arrivalTimeEstDateTime!.toIso8601String().split('.').first,
        'hotspots': hotspots,
        'vehicleModel': _vehicleModelController.text.trim().isEmpty ? null : _vehicleModelController.text.trim(),
        'vehiclePlate': _vehiclePlateController.text.trim().isEmpty ? null : _vehiclePlateController.text.trim(),
        'totalSeats': _totalSeats,
        'travelPreferences': _travelPreferencesController.text.trim().isEmpty ? null : _travelPreferencesController.text.trim(),
      };

      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.post(
        'rides',
        data: requestData,
      );

      if (response.statusCode == 200 && mounted) {
        // Invalida il profilo utente per aggiornare la lista delle corse in Home
        ref.invalidate(userProfileProvider);

        // Mostra Dialog di successo
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.universityGreen, size: 28),
                SizedBox(width: 10),
                Text('Corsa Creata!', style: TextStyle(color: AppColors.textPrimary)),
              ],
            ),
            content: const Text(
              'La tua corsa è stata registrata con successo e ora è visibile agli altri studenti.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Chiude il dialog
                  context.go('/home'); // Torna alla home
                },
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: AppColors.universityGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        throw Exception("Stato risposta non valido dal server");
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['message'] ?? 'Si è verificato un errore durante la creazione della corsa.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Offri un passaggio',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Inserisci i dettagli del tuo viaggio per condividerlo con la community UniMol.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Sezione 1: Percorso & Orari
                _buildSectionTitle('Percorso & Orari'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _departureCityController,
                  decoration: const InputDecoration(
                    labelText: 'Città di partenza *',
                    hintText: 'Es: Campobasso',
                    prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.universityGreen),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Inserisci la città di partenza';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _arrivalCityController,
                  decoration: const InputDecoration(
                    labelText: 'Città di arrivo *',
                    hintText: 'Es: Termoli',
                    prefixIcon: Icon(Icons.flag_outlined, color: AppColors.universityGreen),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Inserisci la città di arrivo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _departureTimeController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Data e Ora di partenza *',
                    prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.universityGreen),
                  ),
                  onTap: () async {
                    final selected = await _selectDateTime();
                    if (selected != null) {
                      setState(() {
                        _departureDateTime = selected;
                        _departureTimeController.text = _formatDateTime(selected);
                      });
                    }
                  },
                  validator: (value) {
                    if (_departureDateTime == null) {
                      return 'Seleziona la data e ora di partenza';
                    }
                    if (_departureDateTime!.isBefore(DateTime.now())) {
                      return 'L\'orario di partenza deve essere nel futuro';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _arrivalTimeEstController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Data e Ora di arrivo stimata *',
                    prefixIcon: Icon(Icons.access_time_outlined, color: AppColors.universityGreen),
                  ),
                  onTap: () async {
                    final selected = await _selectDateTime(
                      initialDate: _departureDateTime ?? DateTime.now().add(const Duration(hours: 1)),
                      firstDate: _departureDateTime ?? DateTime.now(),
                    );
                    if (selected != null) {
                      setState(() {
                        _arrivalTimeEstDateTime = selected;
                        _arrivalTimeEstController.text = _formatDateTime(selected);
                      });
                    }
                  },
                  validator: (value) {
                    if (_arrivalTimeEstDateTime == null) {
                      return 'Seleziona l\'orario di arrivo stimato';
                    }
                    if (_departureDateTime != null && _arrivalTimeEstDateTime!.isBefore(_departureDateTime!)) {
                      return 'L\'arrivo deve essere successivo alla partenza';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Sezione 2: Veicolo & Posti
                _buildSectionTitle('Veicolo & Posti'),
                const SizedBox(height: 12),
                
                // Selettore Posti (Label separata per evitare sovrapposizioni)
                const Text(
                  'Posti disponibili *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _totalSeats,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.airline_seat_recline_normal_outlined, color: AppColors.universityGreen),
                  ),
                  dropdownColor: AppColors.surfaceDark,
                  items: List.generate(8, (index) => index + 1)
                      .map((seats) => DropdownMenuItem<int>(
                            value: seats,
                            child: Text('$seats post${seats == 1 ? 'o' : 'i'}'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _totalSeats = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vehicleModelController,
                  decoration: const InputDecoration(
                    labelText: 'Modello auto (Opzionale)',
                    hintText: 'Es: Fiat Punto',
                    prefixIcon: Icon(Icons.directions_car_outlined, color: AppColors.universityGreen),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vehiclePlateController,
                  decoration: const InputDecoration(
                    labelText: 'Targa auto (Opzionale)',
                    hintText: 'Es: AB123CD',
                    prefixIcon: Icon(Icons.badge_outlined, color: AppColors.universityGreen),
                  ),
                ),
                const SizedBox(height: 24),

                // Sezione 3: Fermate intermedie (Hotspots)
                _buildSectionTitle('Fermate Intermedie (Fino a 3 - Opzionali)'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hotspot1Controller,
                  decoration: const InputDecoration(
                    labelText: 'Fermata 1 (Opzionale)',
                    hintText: 'Es: Isernia (Bivio)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hotspot2Controller,
                  decoration: const InputDecoration(
                    labelText: 'Fermata 2 (Opzionale)',
                    hintText: 'Es: Bojano',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hotspot3Controller,
                  decoration: const InputDecoration(
                    labelText: 'Fermata 3 (Opzionale)',
                    hintText: 'Es: San Massimo',
                  ),
                ),
                const SizedBox(height: 24),

                // Sezione 4: Note aggiuntive
                _buildSectionTitle('Altre informazioni'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _travelPreferencesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Preferenze di viaggio (Opzionale)',
                    hintText: 'Es: No fumo, musica rock, bagaglio piccolo consentito...',
                  ),
                ),
                const SizedBox(height: 32),

                // Pulsante Crea Corsa
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.universityGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Crea Corsa',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.universityGreen,
      ),
    );
  }
}
