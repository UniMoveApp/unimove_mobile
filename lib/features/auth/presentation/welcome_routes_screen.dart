import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WelcomeRoutesScreen extends ConsumerStatefulWidget {
  const WelcomeRoutesScreen({super.key});

  @override
  ConsumerState<WelcomeRoutesScreen> createState() => _WelcomeRoutesScreenState();
}

class _WelcomeRoutesScreenState extends ConsumerState<WelcomeRoutesScreen> {
  final TextEditingController _routeController = TextEditingController();
  final List<String> _selectedRoutes = [
    'Campobasso → Pesche',
    'Campobasso → Pesche',
  ];

  @override
  void dispose() {
    _routeController.dispose();
    super.dispose();
  }

  void _addRoute() {
    if (_routeController.text.isNotEmpty && _selectedRoutes.length < 3) {
      setState(() {
        _selectedRoutes.add(_routeController.text);
        _routeController.clear();
      });
    }
  }

  void _removeRoute(int index) {
    setState(() {
      _selectedRoutes.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Sfondo scuro come nel wireframe
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Benvenuto!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Dicci cosa ti interessa. Seleziona le tratte preferite per ricevere notifiche utili e scoprire subito gli eventi più adatti a te.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              
              const Text(
                'Inserisci le tratte (max 3)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _routeController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Città partenza – Città arrivo',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2C),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade800),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _addRoute,
                  ),
                ),
                onSubmitted: (_) => _addRoute(),
              ),
              const SizedBox(height: 24),
              
              if (_selectedRoutes.isNotEmpty) ...[
                const Text(
                  'Tratte scelte:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                ..._selectedRoutes.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _removeRoute(entry.key),
                            child: const Icon(Icons.close, color: Colors.white54, size: 20),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
              
              const SizedBox(height: 48),
              
              ElevatedButton(
                onPressed: () {
                  // Per ora navighiamo alla home
                  context.go('/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C2C2C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade800),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Conferma',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  context.go('/home');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: BorderSide(color: Colors.grey.shade800),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Salta per ora',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
