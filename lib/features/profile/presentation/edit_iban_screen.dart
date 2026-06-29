import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import 'profile_controller.dart';

class EditIbanScreen extends ConsumerStatefulWidget {
  const EditIbanScreen({super.key});

  @override
  ConsumerState<EditIbanScreen> createState() => _EditIbanScreenState();
}

class _EditIbanScreenState extends ConsumerState<EditIbanScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ibanController;
  late final TextEditingController _holderController;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _ibanController = TextEditingController();
    _holderController = TextEditingController();
  }

  @override
  void dispose() {
    _ibanController.dispose();
    _holderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    // Inizializza i controller con i valori correnti
    userProfileAsync.whenData((profile) {
      if (!_initialized && profile != null) {
        _ibanController.text = profile.iban ?? '';
        _holderController.text = profile.ibanHolder ?? '';
        _initialized = true;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: const Text('Informazioni bancarie'),
        backgroundColor: AppColors.deepBlack,
        elevation: 0,
      ),
      body: userProfileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text(
                'Nessun dato profilo disponibile',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Donazioni volontarie',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Inserisci il tuo IBAN per consentire agli altri utenti di inviarti donazioni volontarie.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // IBAN Field
                  const Text(
                    'CODICE IBAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.universityGreen,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _ibanController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'IT00 X 00000 00000 000000000000',
                      prefixIcon: const Icon(Icons.account_balance_outlined, color: AppColors.textMuted),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.universityGreen, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Inserisci l\'IBAN';
                      }
                      final cleaned = value.replaceAll(RegExp(r'\s+'), '').toUpperCase();
                      if (cleaned.startsWith('IT') && cleaned.length != 27) {
                        return 'L\'IBAN italiano deve essere di 27 caratteri (attuale: ${cleaned.length})';
                      }
                      if (cleaned.length < 15 || cleaned.length > 34) {
                        return 'Lunghezza IBAN non valida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // IBAN Holder Field
                  const Text(
                    'INTESTATARIO CONTO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.universityGreen,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _holderController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Nome e Cognome dell\'intestatario',
                      prefixIcon: const Icon(Icons.person_outline, color: AppColors.textMuted),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.universityGreen, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Inserisci l\'intestatario del conto';
                      }
                      if (value.trim().split(' ').length < 2) {
                        return 'Inserisci sia il nome che il cognome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveIban,
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
                              'Salva modifiche',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
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
              'Errore nel caricamento dei dati: $err',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveIban() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    
    // Rimuovi spazi extra e metti tutto maiuscolo per l'IBAN
    final cleanedIban = _ibanController.text.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final holder = _holderController.text.trim();

    final success = await ref
        .read(profileControllerProvider.notifier)
        .updateIban(cleanedIban, holder);
        
    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informazioni bancarie salvate!'),
            backgroundColor: AppColors.universityGreen,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante il salvataggio dei dati'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
