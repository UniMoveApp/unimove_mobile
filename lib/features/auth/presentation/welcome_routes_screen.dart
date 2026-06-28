import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/data/comuni_molise.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../profile/presentation/routes_controller.dart';

class WelcomeRoutesScreen extends ConsumerStatefulWidget {
  const WelcomeRoutesScreen({super.key});

  @override
  ConsumerState<WelcomeRoutesScreen> createState() => _WelcomeRoutesScreenState();
}

class _WelcomeRoutesScreenState extends ConsumerState<WelcomeRoutesScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _arrivalController = TextEditingController();
  final FocusNode _departureFocusNode = FocusNode();
  final FocusNode _arrivalFocusNode = FocusNode();

  final List<Map<String, String?>> _selectedRoutes = [];
  List<RoutePreference> _initialBackendRoutes = [];
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _departureController.dispose();
    _arrivalController.dispose();
    _departureFocusNode.dispose();
    _arrivalFocusNode.dispose();
    super.dispose();
  }

  void _addRoute() {
    if (!_formKey.currentState!.validate()) return;

    final from = _departureController.text.trim();
    final to = _arrivalController.text.trim();

    if (_selectedRoutes.length < 3) {
      // Verifica se la tratta esiste già in lista
      final alreadyExists = _selectedRoutes.any(
        (route) => route['from'] == from && route['to'] == to,
      );

      if (alreadyExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Questa tratta è già presente nella lista.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }

      setState(() {
        _selectedRoutes.add({'id': null, 'from': from, 'to': to});
        _departureController.clear();
        _arrivalController.clear();
      });
      _departureFocusNode.unfocus();
      _arrivalFocusNode.unfocus();
    }
  }

  void _removeRoute(int index) {
    setState(() {
      _selectedRoutes.removeAt(index);
    });
  }

  Future<void> _confirmSelection() async {
    setState(() => _isLoading = true);

    try {
      // 1. Trova ed elimina le tratte rimosse dall'utente
      for (final initialRoute in _initialBackendRoutes) {
        final stillExists = _selectedRoutes.any((r) => r['id'] == initialRoute.id);
        if (!stillExists) {
          await ref.read(routesControllerProvider.notifier).deleteRoute(initialRoute.id);
        }
      }

      // 2. Trova e aggiungi le nuove tratte (id è null)
      for (final route in _selectedRoutes) {
        final isNew = route['id'] == null;
        if (isNew) {
          await ref.read(routesControllerProvider.notifier).addRoute(
                route['from']!,
                route['to']!,
              );
        }
      }
    } catch (e) {
      debugPrint('Errore durante la sincronizzazione iniziale delle tratte: $e');
    }

    // Segna l'onboarding come completato e vai alla home
    await ref.read(authServiceProvider).setOnboardingCompleted();
    
    setState(() => _isLoading = false);

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(routesControllerProvider);

    routesAsync.whenData((routes) {
      if (!_initialized) {
        _initialBackendRoutes = List.from(routes);
        _selectedRoutes.clear();
        for (final route in routes) {
          _selectedRoutes.add({
            'id': route.id,
            'from': route.cityFrom,
            'to': route.cityTo,
          });
        }
        _initialized = true;
      }
    });

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
                'Dicci cosa ti interessa. Seleziona le tue tratte preferite (massimo 3) per ricevere notifiche utili e scoprire subito i passaggi più adatti a te.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),

              // Form di input per tratta (visibile solo se meno di 3)
              if (_selectedRoutes.length < 3) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aggiungi una tratta preferita',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildCityAutocomplete(
                          label: 'Comune di partenza',
                          hint: 'Es: Campobasso',
                          icon: Icons.location_on_outlined,
                          controller: _departureController,
                          focusNode: _departureFocusNode,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Inserisci la partenza';
                            }
                            if (!comuniMolise.contains(value.trim())) {
                              return 'Seleziona un comune molisano valido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildCityAutocomplete(
                          label: 'Comune di arrivo',
                          hint: 'Es: Pesche',
                          icon: Icons.flag_outlined,
                          controller: _arrivalController,
                          focusNode: _arrivalFocusNode,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Inserisci l\'arrivo';
                            }
                            if (!comuniMolise.contains(value.trim())) {
                              return 'Seleziona un comune molisano valido';
                            }
                            if (value.trim() == _departureController.text.trim()) {
                              return 'Partenza e arrivo non possono coincidere';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _addRoute,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.universityGreen,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Aggiungi tratta',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Banner limite raggiunto
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.universityGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.universityGreen.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: AppColors.universityGreen),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Hai inserito il limite massimo di 3 tratte preferite. Rimuovine una se desideri cambiarla.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Lista tratte aggiunte
              if (_selectedRoutes.isNotEmpty) ...[
                const Text(
                  'Le tue tratte preferite selezionate:',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _selectedRoutes.length,
                  itemBuilder: (context, index) {
                    final route = _selectedRoutes[index];
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
                            const Icon(Icons.directions_car_outlined, color: AppColors.universityGreen, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${route['from']} → ${route['to']}',
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _removeRoute(index),
                              child: const Icon(Icons.close, color: Color(0xFFE57373), size: 20),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 48),

              // Bottone di conferma salvataggio
              ElevatedButton(
                onPressed: _isLoading ? null : _confirmSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.universityGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Conferma',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 12),

              // Bottone salta
              if (!_isLoading)
                TextButton(
                  onPressed: () async {
                    await ref.read(authServiceProvider).setOnboardingCompleted();
                    if (context.mounted) {
                      context.go('/home');
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Salta per ora',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityAutocomplete({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String? Function(String?) validator,
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
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.universityGreen, size: 20),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.universityGreen, width: 2),
            ),
          ),
          validator: validator,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            color: AppColors.surfaceDark,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            child: Container(
              width: MediaQuery.of(context).size.width - 88,
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (context, index) => Divider(
                  color: Colors.white.withValues(alpha: 0.05),
                  height: 1,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(
                      option,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    ),
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
