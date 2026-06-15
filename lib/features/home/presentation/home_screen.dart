import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../../shared/widgets/skeleton.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userNameAsync = ref.watch(userNameProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // User Header
          Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.grey.shade100,
                child: const Icon(Icons.person_outline, size: 40, color: Colors.black54),
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
                        color: Colors.black,
                      ),
                    ),
                    loading: () => const Row(
                      children: [
                        Text(
                          'Ciao ',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
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
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const Text(
                    'Inizia il tuo viaggio!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
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
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.calendar_today_outlined, color: Colors.black),
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
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Hai due eventi in programma per le prossime ore',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text('Visualizza dettagli', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Tab Selection (I miei eventi / Prenotazioni / Archivio)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTabItem(0, 'I miei eventi', Icons.event_note_outlined),
              _buildTabItem(1, 'Prenotazioni', Icons.assignment_outlined),
              _buildTabItem(2, 'Archivio', Icons.archive_outlined),
            ],
          ),
          
          const SizedBox(height: 24),
          
          Text(
            _getTabName(_currentIndex),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildTabContent(),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentIndex) {
      case 0:
        return Column(
          children: [
            _buildEventCard(
              day: '22',
              month: '01',
              departure: 'Campobasso',
              departureTime: '8:30',
              stops: 'Bojano, Capellette',
              arrival: 'Pesche - Unimol',
              arrivalTime: '9:45',
              actions: [
                _buildActionButton('Avvia', () {}),
                _buildActionButton('Elimina', () {}),
              ],
            ),
            _buildEventCard(
              day: '22',
              month: '01',
              departure: 'Campobasso',
              departureTime: '8:30',
              stops: 'Bojano, Capellette',
              arrival: 'Pesche - Unimol',
              arrivalTime: '9:45',
              actions: [
                _buildActionButton('Avvia', () {}),
                _buildActionButton('Elimina', () {}),
              ],
            ),
          ],
        );
      case 1:
        return Column(
          children: [
            _buildEventCard(
              day: '22',
              month: '01',
              departure: 'Campobasso',
              departureTime: '8:30',
              stops: 'Bojano, Capellette',
              arrival: 'Pesche - Unimol',
              arrivalTime: '9:45',
              actions: [
                _buildActionButton('Traccia', () {}),
                _buildActionButton('Abbandona', () {}),
              ],
            ),
            _buildEventCard(
              day: '22',
              month: '01',
              departure: 'Campobasso',
              departureTime: '8:30',
              stops: 'Bojano, Capellette',
              arrival: 'Pesche - Unimol',
              arrivalTime: '9:45',
              actions: [
                _buildActionButton('Traccia', () {}),
                _buildActionButton('Abbandona', () {}),
              ],
            ),
          ],
        );
      case 2:
        return Column(
          children: [
            _buildEventCard(
              day: '22',
              month: '01',
              departure: 'Campobasso',
              departureTime: '8:30',
              stops: 'Bojano, Capellette',
              arrival: 'Pesche - Unimol',
              arrivalTime: '9:45',
              actions: [
                _buildActionButton('Dona', () {}),
                _buildActionButton('Recensisci', () {}),
              ],
            ),
            _buildEventCard(
              day: '22',
              month: '01',
              departure: 'Campobasso',
              departureTime: '8:30',
              stops: 'Bojano, Capellette',
              arrival: 'Pesche - Unimol',
              arrivalTime: '9:45',
              actions: [
                _buildActionButton('Dona', () {}),
                _buildActionButton('Recensisci', () {}),
              ],
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Text(
                    day,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    month,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black, fontSize: 14),
                        children: [
                          const TextSpan(text: 'Partenza: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: '$departure, $departureTime'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black54, fontSize: 13),
                        children: [
                          const TextSpan(text: 'Fermate: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: stops),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black, fontSize: 14),
                        children: [
                          const TextSpan(text: 'Arrivo: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: '$arrival, $arrivalTime'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: actions,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2C2C2C),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(80, 36),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    bool isSelected = _currentIndex == index;
    const accentColor = Color(0xFFE91E63);
    
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        width: (MediaQuery.of(context).size.width - 60) / 3,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFEBEE) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? accentColor.withOpacity(0.1) : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? accentColor : Colors.black45,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? accentColor : Colors.black54,
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
