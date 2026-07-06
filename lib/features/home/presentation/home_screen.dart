import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/domain/user_profile.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../profile/presentation/reviews_controller.dart';
import 'leave_review_dialog.dart';
import '../../../core/services/api_client.dart';
import '../../rides/presentation/my_rides_controller.dart';
import '../../rides/presentation/my_bookings_controller.dart';

final archivedRidesProvider = FutureProvider<List<Ride>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.dio.get('rides/archive');
  if (response.statusCode == 200 && response.data != null) {
    final list = response.data as List<dynamic>;
    return list.map((e) => Ride.fromJson(e as Map<String, dynamic>)).toList();
  }
  throw Exception('Impossibile caricare l\'archivio delle corse');
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  String? _activeActionRideId;
  String? _activeBookingActionId;

  Future<void> _handleStartRide(Ride ride) async {
    setState(() => _activeActionRideId = ride.id);
    try {
      await ref.read(myRidesServiceProvider).startRide(ride.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Corsa avviata con successo!'),
            backgroundColor: AppColors.universityGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _activeActionRideId = null);
    }
  }

  Future<void> _handleCompleteRide(Ride ride) async {
    setState(() => _activeActionRideId = ride.id);
    try {
      await ref.read(myRidesServiceProvider).completeRide(ride.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Corsa completata con successo!'),
            backgroundColor: AppColors.universityGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _activeActionRideId = null);
    }
  }

  Future<void> _confirmAndDeleteRide(Ride ride) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 28),
            SizedBox(width: 10),
            Text('Elimina Corsa', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Text(
          'Sei sicuro di voler eliminare la corsa da ${ride.departureCity} a ${ride.arrivalCity}?\n\n'
          'Nota: le corse non possono essere cancellate se mancano meno di 48 ore dalla partenza.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _activeActionRideId = ride.id);
    try {
      await ref.read(myRidesServiceProvider).deleteRide(ride.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Corsa eliminata con successo.'),
            backgroundColor: AppColors.universityGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _activeActionRideId = null);
    }
  }

  Future<void> _handleCancelBooking(PassengerBooking booking) async {
    final ride = booking.ride;
    final isRideInProgress = ride?.status == 'IN_PROGRESS';
    final actionName = isRideInProgress ? 'Abbandona Corsa' : 'Cancella Prenotazione';
    final actionVerb = isRideInProgress ? 'abbandonare' : 'cancellare';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                actionName,
                style: const TextStyle(color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          'Sei sicuro di voler $actionVerb la tua prenotazione${ride != null ? " per la corsa da ${ride.departureCity} a ${ride.arrivalCity}" : ""}?\n\n'
          '${isRideInProgress ? "Stai per abbandonare una corsa attualmente in corso." : "Nota: le prenotazioni non possono essere cancellate se mancano meno di 24 ore dalla partenza."}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isRideInProgress ? 'Abbandona' : 'Cancella', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _activeBookingActionId = booking.id);
    try {
      await ref.read(myBookingsServiceProvider).cancelBooking(booking.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isRideInProgress ? 'Corsa abbandonata.' : 'Prenotazione cancellata con successo.'),
            backgroundColor: AppColors.universityGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _activeBookingActionId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userNameAsync = ref.watch(userNameProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // User Header
          Row(
            children: [
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceDark,
                ),
                padding: const EdgeInsets.all(2),
                child: const CircleAvatar(
                  radius: 35,
                  backgroundColor: AppColors.deepBlack,
                  child: Icon(Icons.person_outline, size: 40, color: AppColors.universityGreen),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  userNameAsync.when(
                    data: (name) => Text(
                      'Ciao ${name ?? 'User'}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    loading: () => const Row(
                      children: [
                        Text(
                          'Ciao ',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Skeleton(width: 80, height: 24, borderRadius: 6),
                      ],
                    ),
                    error: (_, __) => const Text(
                      'Ciao User',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Text(
                    'Inizia il tuo viaggio!',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Reminder Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.deepBlack,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.calendar_today_outlined, color: AppColors.universityGreen),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Promemoria',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Hai due eventi in programma per le prossime ore',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(140, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Visualizza dettagli', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Tab Selection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTabItem(0, 'I miei eventi', Icons.event_note_outlined),
              _buildTabItem(1, 'Prenotazioni', Icons.assignment_outlined),
              _buildTabItem(2, 'Archivio', Icons.archive_outlined),
            ],
          ),
          
          const SizedBox(height: 24),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTabName(_currentIndex),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              _buildTabContent(userProfileAsync),
            ],
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTabContent(AsyncValue<UserProfile?> userProfileAsync) {
    switch (_currentIndex) {
      case 0:
        final myRidesAsync = ref.watch(myRidesProvider);
        return myRidesAsync.when(
          data: (rides) {
            if (rides.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car_outlined, size: 64, color: AppColors.textMuted),
                      SizedBox(height: 16),
                      Text(
                        'Inizia il tuo viaggio!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Non hai ancora corse create.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: rides.map((ride) => _buildDriverRideCard(ride)).toList(),
            );
          },
          loading: () => Column(
            children: [
              _buildSkeletonEventCard(),
              _buildSkeletonEventCard(),
            ],
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Text(
                    'Errore nel caricamento delle corse: $err',
                    style: const TextStyle(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(myRidesProvider),
                    child: const Text('Riprova'),
                  ),
                ],
              ),
            ),
          ),
        );
      case 1:
        final myBookingsAsync = ref.watch(myBookingsProvider);
        return myBookingsAsync.when(
          data: (bookings) {
            if (bookings.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined, size: 64, color: AppColors.textMuted),
                      SizedBox(height: 16),
                      Text(
                        'Nessuna prenotazione attiva',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Cerca una corsa disponibile e prenota il tuo posto!',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: bookings.map((b) => _buildPassengerBookingCard(b)).toList(),
            );
          },
          loading: () => Column(
            children: [
              _buildSkeletonEventCard(),
              _buildSkeletonEventCard(),
            ],
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Text(
                    'Errore nel caricamento delle prenotazioni: $err',
                    style: const TextStyle(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(myBookingsProvider),
                    child: const Text('Riprova'),
                  ),
                ],
              ),
            ),
          ),
        );
      case 2:
        final archivedRidesAsync = ref.watch(archivedRidesProvider);
        final profileAsync = ref.watch(userProfileProvider);
        
        return archivedRidesAsync.when(
          data: (rides) {
            if (rides.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.archive_outlined, size: 64, color: AppColors.textMuted),
                      SizedBox(height: 16),
                      Text(
                        'Nessun evento in archivio',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Le corse completate a cui hai partecipato appariranno qui.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            final profile = profileAsync.value;
            final String myUsername = profile?.username ?? '';

            return Column(
              children: rides.map((ride) {
                final day = ride.departureTime.day.toString().padLeft(2, '0');
                final month = ride.departureTime.month.toString().padLeft(2, '0');
                final departureTime = '${ride.departureTime.hour.toString().padLeft(2, '0')}:${ride.departureTime.minute.toString().padLeft(2, '0')}';
                final arrivalTime = '${ride.arrivalTimeEst.hour.toString().padLeft(2, '0')}:${ride.arrivalTimeEst.minute.toString().padLeft(2, '0')}';
                final stops = ride.hotspots.isEmpty ? 'Nessuna' : ride.hotspots.join(', ');

                final isPassenger = ride.driverUsername != myUsername;

                return _buildArchivedRideCard(
                  ride: ride,
                  day: day,
                  month: month,
                  departureTime: departureTime,
                  arrivalTime: arrivalTime,
                  stops: stops,
                  isPassenger: isPassenger,
                );
              }).toList(),
            );
          },
          loading: () => Column(
            children: [
              _buildSkeletonEventCard(),
              _buildSkeletonEventCard(),
            ],
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Text(
                    'Errore nel caricamento dell\'archivio: $err',
                    style: const TextStyle(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(archivedRidesProvider),
                    child: const Text('Riprova'),
                  ),
                ],
              ),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  static Widget _buildSkeletonEventCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(width: 50, height: 50, borderRadius: 16),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 80, height: 12, borderRadius: 4),
                SizedBox(height: 8),
                Skeleton(width: 150, height: 16, borderRadius: 4),
                SizedBox(height: 16),
                Skeleton(width: 80, height: 12, borderRadius: 4),
                SizedBox(height: 8),
                Skeleton(width: 150, height: 16, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverRideCard(Ride ride) {
    final day = ride.departureTime.day.toString().padLeft(2, '0');
    final month = ride.departureTime.month.toString().padLeft(2, '0');
    final departureTime = '${ride.departureTime.hour.toString().padLeft(2, '0')}:${ride.departureTime.minute.toString().padLeft(2, '0')}';
    final arrivalTime = '${ride.arrivalTimeEst.hour.toString().padLeft(2, '0')}:${ride.arrivalTimeEst.minute.toString().padLeft(2, '0')}';
    final stops = ride.hotspots.isEmpty ? 'Nessuna' : ride.hotspots.join(', ');
    final isActionLoading = _activeActionRideId == ride.id;

    Color statusColor;
    String statusText;
    switch (ride.status) {
      case 'OPEN':
        statusColor = AppColors.universityGreen;
        statusText = 'Aperta';
        break;
      case 'IN_PROGRESS':
        statusColor = Colors.orange;
        statusText = 'In corso';
        break;
      case 'COMPLETED':
        statusColor = Colors.blue[300]!;
        statusText = 'Completata';
        break;
      default:
        statusColor = AppColors.textMuted;
        statusText = ride.status;
    }

    final actions = <Widget>[];
    if (isActionLoading) {
      actions.add(
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.universityGreen,
          ),
        ),
      );
    } else {
      if (ride.status == 'OPEN') {
        actions.add(_buildActionButton('Avvia', () => _handleStartRide(ride), isPrimary: true));
        actions.add(_buildActionButton('Elimina', () => _confirmAndDeleteRide(ride)));
      } else if (ride.status == 'IN_PROGRESS') {
        actions.add(_buildActionButton('Completa', () => _handleCompleteRide(ride), isPrimary: true));
      }
    }

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.deepBlack,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      day,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      month,
                      style: const TextStyle(fontSize: 14, color: AppColors.universityGreen, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildRouteInfo('Partenza', '${ride.departureCity}, $departureTime', isBold: true),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildRouteInfo('Fermate', stops, isSmall: true),
                    const SizedBox(height: 8),
                    _buildRouteInfo('Arrivo', '${ride.arrivalCity}, $arrivalTime', isBold: true),
                    if ((ride.vehicleModel != null && ride.vehicleModel!.isNotEmpty) || ride.totalSeats > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.airline_seat_recline_normal_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            'Posti: ${ride.availableSeats}/${ride.totalSeats}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          if (ride.vehicleModel != null && ride.vehicleModel!.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.directions_car_outlined, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${ride.vehicleModel}${ride.vehiclePlate != null ? " (${ride.vehiclePlate})" : ""}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPassengerBookingCard(PassengerBooking booking) {
    final ride = booking.ride;
    final isActionLoading = _activeBookingActionId == booking.id;

    final departureTime = ride != null
        ? '${ride.departureTime.hour.toString().padLeft(2, '0')}:${ride.departureTime.minute.toString().padLeft(2, '0')}'
        : '--:--';
    final arrivalTime = ride != null
        ? '${ride.arrivalTimeEst.hour.toString().padLeft(2, '0')}:${ride.arrivalTimeEst.minute.toString().padLeft(2, '0')}'
        : '--:--';
    final day = ride != null
        ? ride.departureTime.day.toString().padLeft(2, '0')
        : (booking.createdAt != null ? booking.createdAt!.day.toString().padLeft(2, '0') : '--');
    final month = ride != null
        ? ride.departureTime.month.toString().padLeft(2, '0')
        : (booking.createdAt != null ? booking.createdAt!.month.toString().padLeft(2, '0') : '--');

    final departureCity = ride?.departureCity ?? 'Partenza non specificata';
    final arrivalCity = ride?.arrivalCity ?? 'Arrivo non specificato';
    final driverName = ride?.driverFullName.isNotEmpty == true ? ride!.driverFullName : null;
    final hotspot = booking.hotspotChosen ?? 'Non specificato';

    final isRideInProgress = ride?.status == 'IN_PROGRESS';
    final buttonLabel = isRideInProgress ? 'Abbandona' : 'Cancella';

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.deepBlack,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      day,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      month,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.universityGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildRouteInfo('Partenza', '$departureCity, $departureTime', isBold: true),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isRideInProgress ? Colors.orange : AppColors.universityGreen).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isRideInProgress ? 'In corso' : 'Prenotata',
                            style: TextStyle(
                              color: isRideInProgress ? Colors.orange : AppColors.universityGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildRouteInfo('Punto di Incontro', hotspot, isSmall: true),
                    const SizedBox(height: 8),
                    _buildRouteInfo('Arrivo', '$arrivalCity, $arrivalTime', isBold: true),
                    if (driverName != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Guidatore: $driverName',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isActionLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.universityGreen,
                  ),
                )
              else
                _buildActionButton(buttonLabel, () => _handleCancelBooking(booking)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo(String label, String value, {bool isBold = false, bool isSmall = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSmall ? AppColors.textMuted : AppColors.universityGreen,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isSmall ? 13 : 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isSmall ? AppColors.textSecondary : AppColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed, {bool isPrimary = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? AppColors.universityGreen : AppColors.deepBlack,
          foregroundColor: Colors.white,
          minimumSize: const Size(80, 36),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    bool isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        width: (MediaQuery.of(context).size.width - 60) / 3,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.universityGreen : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTabName(int index) {
    switch (index) {
      case 0: return 'I miei eventi';
      case 1: return 'Prenotazioni';
      case 2: return 'Archivio';
      default: return '';
    }
  }

  Widget _buildArchivedRideCard({
    required Ride ride,
    required String day,
    required String month,
    required String departureTime,
    required String arrivalTime,
    required String stops,
    required bool isPassenger,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.deepBlack,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      day,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      month,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.universityGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRouteInfo('Partenza', '${ride.departureCity}, $departureTime', isBold: true),
                    const SizedBox(height: 8),
                    _buildRouteInfo('Fermate', stops, isSmall: true),
                    const SizedBox(height: 8),
                    _buildRouteInfo('Arrivo', '${ride.arrivalCity}, $arrivalTime', isBold: true),
                    if (isPassenger && ride.driverFullName.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            'Guidatore: ${ride.driverFullName}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPassenger
                      ? Colors.blue.withValues(alpha: 0.15)
                      : AppColors.universityGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPassenger ? 'Passeggero' : 'Conducente',
                  style: TextStyle(
                    color: isPassenger ? Colors.blue[300] : AppColors.universityGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isPassenger)
                Consumer(
                  builder: (context, ref, child) {
                    final isReviewedAsync = ref.watch(isRideReviewedProvider((
                      rideId: ride.id,
                      driverUsername: ride.driverUsername
                    )));
                    
                    return isReviewedAsync.when(
                      data: (isReviewed) {
                        if (isReviewed) {
                          return const Row(
                            children: [
                              Icon(Icons.check_circle, size: 14, color: AppColors.universityGreen),
                              SizedBox(width: 4),
                              Text(
                                'Recensito',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        } else {
                          return _buildActionButton('Recensisci', () {
                            LeaveReviewDialog.show(
                              context,
                              rideId: ride.id,
                              driverName: ride.driverFullName,
                              driverUsername: ride.driverUsername,
                              onSubmitted: () {
                                ref.invalidate(archivedRidesProvider);
                              },
                            );
                          }, isPrimary: true);
                        }
                      },
                      loading: () => const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.universityGreen,
                        ),
                      ),
                      error: (_, __) => const Text('Errore', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}