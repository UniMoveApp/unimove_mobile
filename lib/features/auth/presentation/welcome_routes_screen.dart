import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/theme/app_theme.dart';

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
      backgroundColor: AppColors.deepBlack,
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
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Dicci cosa ti interessa. Seleziona le tratte preferite per ricevere notifiche utili e scoprire subito gli eventi più adatti a te.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              
              const Text(
                'Inserisci le tratte (max 3)',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _routeController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Città partenza – Città arrivo',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add, color: AppColors.universityGreen),
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
                    color: AppColors.textSecondary,
                    fontSize: 13,
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
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _removeRoute(entry.key),
                            child: const Icon(Icons.close, color: AppColors.universityGreen, size: 20),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              
              const SizedBox(height: 48),
              
              ElevatedButton(
                onPressed: () async {
                  await ref.read(authServiceProvider).setOnboardingCompleted();
                  if (context.mounted) {
                    context.go('/home');
                  }
                },
                child: const Text(
                  'Conferma',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await ref.read(authServiceProvider).setOnboardingCompleted();
                  if (context.mounted) {
                    context.go('/home');
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  padding: const EdgeInsets.symmetric(vertical: 18),
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
