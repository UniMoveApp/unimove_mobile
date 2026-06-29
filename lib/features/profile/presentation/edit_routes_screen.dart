import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/comuni_molise.dart';
import '../../../shared/theme/app_theme.dart';
import 'routes_controller.dart';

class EditRoutesScreen extends ConsumerStatefulWidget {
  const EditRoutesScreen({super.key});

  @override
  ConsumerState<EditRoutesScreen> createState() => _EditRoutesScreenState();
}

class _EditRoutesScreenState extends ConsumerState<EditRoutesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _departureCityController = TextEditingController();
  final _arrivalCityController = TextEditingController();

  final _departureFocusNode = FocusNode();
  final _arrivalFocusNode = FocusNode();

  bool _isSaving = false;

  @override
  void dispose() {
    _departureCityController.dispose();
    _arrivalCityController.dispose();
    _departureFocusNode.dispose();
    _arrivalFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final from = _departureCityController.text.trim();
    final to = _arrivalCityController.text.trim();

    setState(() => _isSaving = true);
    final success = await ref.read(routesControllerProvider.notifier).addRoute(from, to);
    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        _departureCityController.clear();
        _arrivalCityController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tratta preferita aggiunta!'),
            backgroundColor: AppColors.universityGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante l\'aggiunta della tratta'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _deleteRoute(String id) async {
    final success = await ref.read(routesControllerProvider.notifier).deleteRoute(id);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tratta preferita rimossa!'),
            backgroundColor: AppColors.universityGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante la rimozione della tratta'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(routesControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: const Text('Preferenze tratte'),
        backgroundColor: AppColors.deepBlack,
        elevation: 0,
      ),
      body: routesAsync.when(
        data: (routes) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Le tue tratte preferite',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Seleziona fino a un massimo di 3 tratte preferite. Ti aiuteremo a trovare i viaggi più adatti a te in queste tratte.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                // Lista delle tratte correnti
                if (routes.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.alt_route_outlined, size: 48, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'Nessuna tratta preferita impostata',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: routes.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final route = routes[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_car_outlined, color: AppColors.universityGreen),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                '${route.cityFrom} → ${route.cityTo}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Color(0xFFE57373)),
                              onPressed: () => _deleteRoute(route.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 32),

                // Form per aggiungere tratta
                if (routes.length < 3) ...[
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
                            'Aggiungi tratta',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Partenza Autocomplete
                          _buildCityAutocomplete(
                            label: 'Comune di partenza',
                            hint: 'Es: Campobasso',
                            icon: Icons.location_on_outlined,
                            controller: _departureCityController,
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
                          const SizedBox(height: 16),

                          // Arrivo Autocomplete
                          _buildCityAutocomplete(
                            label: 'Comune di arrivo',
                            hint: 'Es: Pesche',
                            icon: Icons.flag_outlined,
                            controller: _arrivalCityController,
                            focusNode: _arrivalFocusNode,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Inserisci l\'arrivo';
                              }
                              if (!comuniMolise.contains(value.trim())) {
                                return 'Seleziona un comune molisano valido';
                              }
                              if (value.trim() == _departureCityController.text.trim()) {
                                return 'Partenza e arrivo non possono coincidere';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Bottone di Aggiunta
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.universityGreen,
                                disabledBackgroundColor: AppColors.universityGreen.withValues(alpha: 0.5),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Aggiungi tratta preferita',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Messaggio di limite massimo raggiunto
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.universityGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.universityGreen.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.universityGreen),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Hai raggiunto il limite massimo di 3 tratte preferite. Elimina una tratta esistente per poterne inserire una nuova.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.universityGreen),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Errore nel caricamento delle tratte: $err',
              style: const TextStyle(color: Colors.redAccent),
            ),
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
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.universityGreen),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
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
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Container(
              width: MediaQuery.of(context).size.width - 88,
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
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
                    title: Text(
                      option,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
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
