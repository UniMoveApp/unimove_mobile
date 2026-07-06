import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/services/api_client.dart';
import '../../../core/data/comuni_molise.dart';
import '../../../shared/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/domain/user_profile.dart';
import '../../../shared/widgets/skeleton.dart';
import 'my_bookings_controller.dart';

class SearchRideScreen extends ConsumerStatefulWidget {
  const SearchRideScreen({super.key});

  @override
  ConsumerState<SearchRideScreen> createState() => _SearchRideScreenState();
}

class _SearchRideScreenState extends ConsumerState<SearchRideScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _driverUsernameController = TextEditingController();
  final _departureCityController = TextEditingController();
  final _arrivalCityController = TextEditingController();
  final _departureDateController = TextEditingController();
  final _departureTimeController = TextEditingController();
  final _arrivalTimeEstController = TextEditingController();

  // FocusNodes for Autocomplete
  final _departureFocusNode = FocusNode();
  final _arrivalFocusNode = FocusNode();

  // State Variables
  DateTime? _selectedDate;
  TimeOfDay? _selectedDepartureTime;
  TimeOfDay? _selectedArrivalTimeEst;
  int _seatsFilter = 1;

  // Travel Preferences Filters (true = active/selected)
  bool _musicFilter = false;
  bool _talkFilter = false;
  bool _animalsFilter = false;
  bool _smokeFilter = false;
  bool _acFilter = false;

  // Search results and states
  bool _isLoading = false;
  bool _showResults = false;
  List<Ride> _allRides = [];
  List<Ride> _filteredRides = [];

  @override
  void dispose() {
    _driverUsernameController.dispose();
    _departureCityController.dispose();
    _arrivalCityController.dispose();
    _departureDateController.dispose();
    _departureTimeController.dispose();
    _arrivalTimeEstController.dispose();
    _departureFocusNode.dispose();
    _arrivalFocusNode.dispose();
    super.dispose();
  }

  // Formatting helpers
  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }



  // Trigger search API call
  Future<void> _performSearch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _showResults = true;
    });

    try {
      final queryParams = <String, dynamic>{};

      if (_driverUsernameController.text.trim().isNotEmpty) {
        queryParams['driverUsername'] = _driverUsernameController.text.trim();
      }
      if (_departureCityController.text.trim().isNotEmpty) {
        queryParams['departureCity'] = _departureCityController.text.trim();
      }
      if (_arrivalCityController.text.trim().isNotEmpty) {
        queryParams['arrivalCity'] = _arrivalCityController.text.trim();
      }
      if (_selectedDate != null) {
        // Format date to ISO date: yyyy-MM-dd
        queryParams['date'] = _selectedDate!.toIso8601String().split('T').first;
      }

      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get(
        'rides/search',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final list = response.data as List<dynamic>;
        final fetchedRides = list.map((e) => Ride.fromJson(e as Map<String, dynamic>)).toList();

        setState(() {
          _allRides = fetchedRides;
          _applyFilters();
        });
      } else {
        throw Exception("Risposta non valida dal server");
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['message'] ?? 'Si è verificato un errore durante la ricerca.';
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

  // Filter rides in memory based on other fields
  void _applyFilters() {
    _filteredRides = _allRides.where((ride) {
      // 1. departureTime filter (must be >= selected time on the selected date)
      if (_selectedDepartureTime != null) {
        final rideDepTime = TimeOfDay.fromDateTime(ride.departureTime);
        if (rideDepTime.hour < _selectedDepartureTime!.hour ||
            (rideDepTime.hour == _selectedDepartureTime!.hour &&
                rideDepTime.minute < _selectedDepartureTime!.minute)) {
          return false;
        }
      }

      // 2. arrivalTimeEst filter (must be <= selected time on the selected date)
      if (_selectedArrivalTimeEst != null) {
        final rideArrTime = TimeOfDay.fromDateTime(ride.arrivalTimeEst);
        if (rideArrTime.hour > _selectedArrivalTimeEst!.hour ||
            (rideArrTime.hour == _selectedArrivalTimeEst!.hour &&
                rideArrTime.minute > _selectedArrivalTimeEst!.minute)) {
          return false;
        }
      }

      // 3. seats filter (must have enough available seats)
      if (ride.availableSeats < _seatsFilter) {
        return false;
      }

      // 4. travel preferences filter using parsed travel preferences
      final ridePrefs = _parseRidePreferences(ride.travelPreferences);
      if (_musicFilter && !ridePrefs['music']!) return false;
      if (_talkFilter && !ridePrefs['talk']!) return false;
      if (_animalsFilter && !ridePrefs['animals']!) return false;
      if (_smokeFilter && !ridePrefs['smoke']!) return false;
      if (_acFilter && !ridePrefs['ac']!) return false;

      return true;
    }).toList();
  }

  // Preferences mapping heuristic for card visualization
  Map<String, bool> _parseRidePreferences(String? travelPrefsText) {
    if (travelPrefsText == null || travelPrefsText.isEmpty) {
      return {'music': true, 'talk': true, 'animals': false, 'smoke': false, 'ac': true};
    }

    final parts = travelPrefsText.split('|');
    final prefsStr = parts.first;

    // Check if it's the structured format: starts with music: or contains key-value pairs
    if (prefsStr.contains('music:') && prefsStr.contains('talk:')) {
      final prefs = TravelPreferences.fromString(prefsStr);
      return {
        'music': prefs.music != PreferenceLevel.dislike,
        'talk': prefs.talk != PreferenceLevel.dislike,
        'animals': prefs.animals == PreferenceLevel.like,
        'smoke': prefs.smoke == PreferenceLevel.like,
        'ac': prefs.ac != PreferenceLevel.dislike,
      };
    }

    // Fallback: use keyword heuristic on the entire text
    final note = travelPrefsText.toLowerCase();
    return {
      'music': !(note.contains('no musica') || note.contains('senza musica') || note.contains('no music')),
      'talk': !(note.contains('no chiacchiere') || note.contains('no conversazione') || note.contains('no talk') || note.contains('silenzio')),
      'animals': note.contains('animali ammessi') || note.contains('accetto animali') || note.contains('cani ok') || note.contains('pets ok') || note.contains('animali ok'),
      'smoke': note.contains('si fuma') || note.contains('fumo ok') || note.contains('fumo consentito') || note.contains('fumatori'),
      'ac': !(note.contains('no ac') || note.contains('no aria condizionata') || note.contains('senza aria')),
    };
  }

  // Booking action: opens modal to select hotspot
  void _openBookingSheet(Ride ride) {
    final currentProfile = ref.read(userProfileProvider).value;
    if (currentProfile != null && currentProfile.username == ride.driverUsername) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Non puoi prenotare la tua stessa corsa!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Collect all options for hotspots
    final hotspotOptions = <String>[];
    hotspotOptions.add(ride.departureCity); // Default meeting point is departure city
    hotspotOptions.addAll(ride.hotspots);
    hotspotOptions.add(ride.arrivalCity); // Arrival city can also be selected

    String selectedHotspot = hotspotOptions.first;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Punto di incontro',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Seleziona l\'hotspot per l\'incontro tra quelli disponibili:',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: hotspotOptions.length,
                        itemBuilder: (context, index) {
                          final option = hotspotOptions[index];
                          final isDeparture = index == 0;
                          final isArrival = index == hotspotOptions.length - 1;

                          String subLabel = 'Fermata intermedia';
                          if (isDeparture) subLabel = 'Punto di partenza';
                          if (isArrival && hotspotOptions.length > 2) subLabel = 'Destinazione finale';

                          return RadioListTile<String>(
                            value: option,
                            groupValue: selectedHotspot,
                            title: Text(
                              option,
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              subLabel,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                            activeColor: AppColors.universityGreen,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => selectedHotspot = val);
                              }
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setModalState(() => isSubmitting = true);
                                try {
                                  final apiClient = ref.read(apiClientProvider);
                                  final response = await apiClient.dio.post(
                                    'bookings',
                                    data: {
                                      'rideId': ride.id,
                                      'hotspotChosen': selectedHotspot,
                                    },
                                  );

                                  if (!context.mounted) return;

                                  if (response.statusCode == 200 || response.statusCode == 201) {
                                    // Refresh user profile upcoming rides, bookings & reviews
                                    ref.invalidate(userProfileProvider);
                                    ref.invalidate(myBookingsProvider);
                                    Navigator.pop(context); // Close bottom sheet

                                    // Show success dialog
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
                                            Text('Prenotazione Inviata!', style: TextStyle(color: AppColors.textPrimary)),
                                          ],
                                        ),
                                        content: Text(
                                          'La tua prenotazione per la corsa di ${ride.driverFullName} è stata registrata con successo.\n\nIncontro: $selectedHotspot',
                                          style: const TextStyle(color: AppColors.textSecondary),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context); // Close dialog
                                              context.go('/home'); // Back to home
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
                                    throw Exception('Impossibile completare la prenotazione');
                                  }
                                } on DioException catch (e) {
                                  final errMsg = e.response?.data?['message'] ?? 'Errore durante la prenotazione.';
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(errMsg),
                                      backgroundColor: Colors.redAccent,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: Colors.redAccent,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } finally {
                                  setModalState(() => isSubmitting = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.universityGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Conferma Prenotazione',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showResults) {
      return _buildResultsView();
    }

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
                  'Cerca Corse',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Filtra per trovare la corsa perfetta per le tue esigenze.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Guidatore
                TextFormField(
                  controller: _driverUsernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username guidatore',
                    hintText: 'n.cognome',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.universityGreen),
                  ),
                ),
                const SizedBox(height: 16),

                // Data di partenza
                TextFormField(
                  controller: _departureDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Data di partenza *',
                    hintText: 'dd/mm/aaaa',
                    prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.universityGreen),
                  ),
                  validator: (value) {
                    if (_selectedDate == null) {
                      return 'Seleziona la data di partenza';
                    }
                    return null;
                  },
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
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
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                        _departureDateController.text = _formatDate(date);
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Città di partenza
                _buildCityAutocomplete(
                  label: 'Città di partenza',
                  hint: 'Es: Campobasso',
                  icon: Icons.location_on_outlined,
                  controller: _departureCityController,
                  focusNode: _departureFocusNode,
                ),
                const SizedBox(height: 16),

                // Orario di partenza
                TextFormField(
                  controller: _departureTimeController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Orario di partenza',
                    hintText: 'hh:mm',
                    prefixIcon: Icon(Icons.access_time_outlined, color: AppColors.universityGreen),
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedDepartureTime ?? TimeOfDay.now(),
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
                    if (time != null) {
                      setState(() {
                        _selectedDepartureTime = time;
                        _departureTimeController.text = _formatTimeOfDay(time);
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Città di arrivo
                _buildCityAutocomplete(
                  label: 'Città di arrivo',
                  hint: 'Es: Pesche',
                  icon: Icons.flag_outlined,
                  controller: _arrivalCityController,
                  focusNode: _arrivalFocusNode,
                ),
                const SizedBox(height: 16),

                // Orario di arrivo stimato
                TextFormField(
                  controller: _arrivalTimeEstController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Orario stimato di arrivo',
                    hintText: 'hh:mm',
                    prefixIcon: Icon(Icons.access_time_outlined, color: AppColors.universityGreen),
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedArrivalTimeEst ?? TimeOfDay.now(),
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
                    if (time != null) {
                      setState(() {
                        _selectedArrivalTimeEst = time;
                        _arrivalTimeEstController.text = _formatTimeOfDay(time);
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Numero posti richiesti
                const Text(
                  'Posti necessari *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _seatsFilter,
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
                      setState(() => _seatsFilter = value);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Preferenze
                const Text(
                  'Preferenze di viaggio',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPreferenceFilterBox(Icons.music_note_outlined, _musicFilter, () {
                      setState(() => _musicFilter = !_musicFilter);
                    }),
                    _buildPreferenceFilterBox(Icons.forum_outlined, _talkFilter, () {
                      setState(() => _talkFilter = !_talkFilter);
                    }),
                    _buildPreferenceFilterBox(Icons.pets_outlined, _animalsFilter, () {
                      setState(() => _animalsFilter = !_animalsFilter);
                    }),
                    _buildPreferenceFilterBox(Icons.smoking_rooms_outlined, _smokeFilter, () {
                      setState(() => _smokeFilter = !_smokeFilter);
                    }),
                    _buildPreferenceFilterBox(Icons.ac_unit_outlined, _acFilter, () {
                      setState(() => _acFilter = !_acFilter);
                    }),
                  ],
                ),
                const SizedBox(height: 32),

                // Cerca button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _performSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.universityGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Cerca',
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

  // Preference Box filter widget
  Widget _buildPreferenceFilterBox(IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isActive ? AppColors.universityGreen.withValues(alpha: 0.15) : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.universityGreen : Colors.white.withValues(alpha: 0.05),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? AppColors.universityGreen : AppColors.textMuted,
          size: 24,
        ),
      ),
    );
  }

  // Results screen view
  Widget _buildResultsView() {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: const Text('Risultati Ricerca'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              _showResults = false;
            });
          },
        ),
        backgroundColor: AppColors.deepBlack,
        elevation: 0,
      ),
      body: _isLoading
          ? _buildLoadingSkeleton()
          : _filteredRides.isEmpty
              ? _buildNoResultsView()
              : _buildResultsList(),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Skeleton(width: 40, height: 40, borderRadius: 20),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(width: 120, height: 16, borderRadius: 4),
                      SizedBox(height: 4),
                      Skeleton(width: 80, height: 12, borderRadius: 4),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              Skeleton(width: double.infinity, height: 14, borderRadius: 4),
              SizedBox(height: 8),
              Skeleton(width: 180, height: 14, borderRadius: 4),
              SizedBox(height: 20),
              Skeleton(width: double.infinity, height: 44, borderRadius: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoResultsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_outlined, size: 72, color: AppColors.textMuted),
            const SizedBox(height: 20),
            const Text(
              'Nessuna corsa trovata',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Prova a modificare i tuoi filtri o la città di partenza/arrivo per visualizzare altri risultati.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showResults = false;
                });
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Modifica ricerca'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredRides.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0, left: 4.0),
            child: Text(
              '${_filteredRides.length} cors${_filteredRides.length == 1 ? 'a trovata' : 'e trovate'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        final ride = _filteredRides[index - 1];
        final ridePrefs = _parseRidePreferences(ride.travelPreferences);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Driver Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.universityGreen.withValues(alpha: 0.15),
                    child: Text(
                      ride.driverFullName.isNotEmpty ? ride.driverFullName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppColors.universityGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.driverFullName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          '@${ride.driverUsername}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.universityGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${ride.availableSeats} posti liberi',
                      style: const TextStyle(
                        color: AppColors.universityGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14.0),
                child: Divider(color: Colors.white10, height: 1),
              ),

              // Route representation
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // vertical dot connector
                  Column(
                    children: [
                      const Icon(Icons.radio_button_checked, color: AppColors.universityGreen, size: 16),
                      Container(
                        width: 2,
                        height: 36,
                        color: Colors.white10,
                      ),
                      const Icon(Icons.location_on, color: AppColors.universityGreen, size: 16),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // departure
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ride.departureCity,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              _formatTimeOfDay(TimeOfDay.fromDateTime(ride.departureTime)),
                              style: const TextStyle(
                                color: AppColors.universityGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        // arrival
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ride.arrivalCity,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              _formatTimeOfDay(TimeOfDay.fromDateTime(ride.arrivalTimeEst)),
                              style: const TextStyle(
                                color: AppColors.universityGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Date info
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Data: ${_formatDate(ride.departureTime)}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),

              // Hotspots if any
              if (ride.hotspots.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.alt_route_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Fermate: ${ride.hotspots.join(", ")}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],

              // Vehicle if any
              if (ride.vehicleModel != null && ride.vehicleModel!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.directions_car, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Veicolo: ${ride.vehicleModel} ${ride.vehiclePlate != null ? "(${ride.vehiclePlate})" : ""}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ],

              // Note box if text notes exist
              if (ride.travelPreferences != null && ride.travelPreferences!.trim().isNotEmpty) ...[
                ...(() {
                  final parts = ride.travelPreferences!.split('|');
                  final displayNote = parts.length > 1 ? parts[1] : (parts.first.contains('music:') ? '' : parts.first);
                  if (displayNote.trim().isEmpty) return <Widget>[];
                  return <Widget>[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                      ),
                      child: Text(
                        'Note: "$displayNote"',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ];
                })(),
              ],

              const SizedBox(height: 14),

              // Ride Preference Icons visualizer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCardPreferenceIcon(Icons.music_note_outlined, ridePrefs['music']!),
                          const SizedBox(width: 6),
                          _buildCardPreferenceIcon(Icons.forum_outlined, ridePrefs['talk']!),
                          const SizedBox(width: 6),
                          _buildCardPreferenceIcon(Icons.pets_outlined, ridePrefs['animals']!),
                          const SizedBox(width: 6),
                          _buildCardPreferenceIcon(Icons.smoking_rooms_outlined, ridePrefs['smoke']!),
                          const SizedBox(width: 6),
                          _buildCardPreferenceIcon(Icons.ac_unit_outlined, ridePrefs['ac']!),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _openBookingSheet(ride),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(80, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      backgroundColor: AppColors.universityGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Prenota',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardPreferenceIcon(IconData icon, bool isActive) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isActive ? AppColors.universityGreen.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? AppColors.universityGreen : Colors.white.withValues(alpha: 0.05),
          width: isActive ? 1.2 : 1,
        ),
      ),
      child: Icon(
        icon,
        color: isActive ? AppColors.universityGreen : AppColors.textMuted,
        size: 14,
      ),
    );
  }

  // City Autocomplete widget matching the style in CreateRideScreen
  Widget _buildCityAutocomplete({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
  }) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return comuniMolise.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          onFieldSubmitted: (value) => onFieldSubmitted(),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.universityGreen),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            color: AppColors.surfaceDark,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Container(
              width: MediaQuery.of(context).size.width - 40,
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (context, index) => Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return ListTile(
                    title: Text(option, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
