import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/domain/user_profile.dart';
import 'profile_controller.dart';

class EditPreferencesScreen extends ConsumerStatefulWidget {
  const EditPreferencesScreen({super.key});

  @override
  ConsumerState<EditPreferencesScreen> createState() => _EditPreferencesScreenState();
}

class _EditPreferencesScreenState extends ConsumerState<EditPreferencesScreen> {
  PreferenceLevel _music = PreferenceLevel.neutral;
  PreferenceLevel _talk = PreferenceLevel.neutral;
  PreferenceLevel _animals = PreferenceLevel.neutral;
  PreferenceLevel _smoke = PreferenceLevel.neutral;
  PreferenceLevel _ac = PreferenceLevel.neutral;

  bool _isSaving = false;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    userProfileAsync.whenData((profile) {
      if (!_initialized && profile != null) {
        final prefs = TravelPreferences.fromString(profile.travelPreferences ?? '');
        _music = prefs.music == PreferenceLevel.dislike ? PreferenceLevel.dislike : PreferenceLevel.like;
        _talk = prefs.talk == PreferenceLevel.dislike ? PreferenceLevel.dislike : PreferenceLevel.like;
        _animals = prefs.animals == PreferenceLevel.dislike ? PreferenceLevel.dislike : PreferenceLevel.like;
        // Ripristiniamo la logica diretta (Sì = fumo consentito, No = fumo non consentito)
        _smoke = prefs.smoke == PreferenceLevel.like ? PreferenceLevel.like : PreferenceLevel.dislike;
        _ac = prefs.ac == PreferenceLevel.dislike ? PreferenceLevel.dislike : PreferenceLevel.like;
        _initialized = true;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: const Text('Preferenze di viaggio'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Le tue preferenze',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Imposta le tue preferenze per definire come preferisci viaggiare. Saranno visualizzate sul tuo profilo e condivise con passeggeri e conducenti.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                // 1. Musica
                _buildPreferenceRow(
                  title: 'Musica a bordo',
                  subtitle: 'Ti piace ascoltare musica durante la corsa?',
                  icon: Icons.music_note_outlined,
                  currentValue: _music,
                  onChanged: (val) => setState(() => _music = val),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Divider(color: Colors.white10),
                ),

                // 2. Conversazione
                _buildPreferenceRow(
                  title: 'Chiacchiere / Conversazione',
                  subtitle: 'Ti piace fare conversazione o preferisci il silenzio?',
                  icon: Icons.forum_outlined,
                  currentValue: _talk,
                  onChanged: (val) => setState(() => _talk = val),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Divider(color: Colors.white10),
                ),

                // 3. Animali
                _buildPreferenceRow(
                  title: 'Animali domestici',
                  subtitle: 'Accetti animali domestici a bordo del veicolo?',
                  icon: Icons.pets_outlined,
                  currentValue: _animals,
                  onChanged: (val) => setState(() => _animals = val),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Divider(color: Colors.white10),
                ),

                // 4. Fumo
                _buildPreferenceRow(
                  title: 'Fumo a bordo',
                  subtitle: 'Accetti che si possa fumare a bordo?',
                  icon: Icons.smoking_rooms_outlined,
                  currentValue: _smoke,
                  onChanged: (val) => setState(() => _smoke = val),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Divider(color: Colors.white10),
                ),

                // 5. Aria condizionata
                _buildPreferenceRow(
                  title: 'Aria condizionata',
                  subtitle: 'Preferisci viaggiare con l\'aria condizionata attiva?',
                  icon: Icons.ac_unit_outlined,
                  currentValue: _ac,
                  onChanged: (val) => setState(() => _ac = val),
                ),
                const SizedBox(height: 48),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _savePreferences,
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
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
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
              'Errore nel caricamento dei dati: $err',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required PreferenceLevel currentValue,
    required ValueChanged<PreferenceLevel> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.universityGreen, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildOptionButton('No', PreferenceLevel.dislike, currentValue, onChanged)),
            const SizedBox(width: 16),
            Expanded(child: _buildOptionButton('Sì', PreferenceLevel.like, currentValue, onChanged)),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionButton(
    String label,
    PreferenceLevel value,
    PreferenceLevel currentValue,
    ValueChanged<PreferenceLevel> onChanged,
  ) {
    final isSelected = currentValue == value;
    return GestureDetector(
      onTap: _isSaving ? null : () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.universityGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.universityGreen : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    
    final travelPrefsStr = TravelPreferences(
      music: _music,
      talk: _talk,
      animals: _animals,
      smoke: _smoke,
      ac: _ac,
    ).toString();

    final success = await ref
        .read(profileControllerProvider.notifier)
        .updatePreferences(travelPrefsStr);
        
    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferenze aggiornate con successo!'),
            backgroundColor: AppColors.universityGreen,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante l\'aggiornamento delle preferenze'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
