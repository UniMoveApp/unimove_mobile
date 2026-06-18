import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/domain/user_profile.dart';
import '../../../shared/widgets/skeleton.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

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
        return userProfileAsync.when(
          data: (profile) {
            final rides = profile?.upcomingRides ?? [];
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
                        'Non hai ancora corse programmate.',
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
              children: rides.map((ride) {
                final day = ride.departureTime.day.toString().padLeft(2, '0');
                final month = ride.departureTime.month.toString().padLeft(2, '0');
                final departureTime = '${ride.departureTime.hour.toString().padLeft(2, '0')}:${ride.departureTime.minute.toString().padLeft(2, '0')}';
                final arrivalTime = '${ride.arrivalTimeEst.hour.toString().padLeft(2, '0')}:${ride.arrivalTimeEst.minute.toString().padLeft(2, '0')}';
                final stops = ride.hotspots.isEmpty ? 'Nessuna' : ride.hotspots.join(', ');

                return _buildEventCard(
                  day: day,
                  month: month,
                  departure: ride.departureCity,
                  departureTime: departureTime,
                  stops: stops,
                  arrival: ride.arrivalCity,
                  arrivalTime: arrivalTime,
                  actions: [
                    _buildActionButton('Avvia', () {}, isPrimary: true),
                    _buildActionButton('Elimina', () {}),
                  ],
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
              child: Text(
                'Errore nel caricamento delle corse: $err',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
          ),
        );
      case 1:
        return Column(
          children: [
            _buildEventCard(
              day: '25',
              month: '01',
              departure: 'Venafro',
              departureTime: '07:30',
              stops: 'Nessuna',
              arrival: 'Campobasso - Unimol',
              arrivalTime: '08:45',
              actions: [
                _buildActionButton('Traccia', () {}, isPrimary: true),
                _buildActionButton('Abbandona', () {}),
              ],
            ),
          ],
        );
      case 2:
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text('Nessun evento in archivio', style: TextStyle(color: AppColors.textMuted)),
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

  Widget _buildEventCard({
    required String day,
    required String month,
    required String departure,
    required String departureTime,
    required String stops,
    required String arrival,
    required String arrivalTime,
    required List<Widget> actions,
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
                    _buildRouteInfo('Partenza', '$departure, $departureTime', isBold: true),
                    const SizedBox(height: 8),
                    _buildRouteInfo('Fermate', stops, isSmall: true),
                    const SizedBox(height: 8),
                    _buildRouteInfo('Arrivo', '$arrival, $arrivalTime', isBold: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: actions,
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
}