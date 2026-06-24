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
  late PreferenceLevel _music;
  late PreferenceLevel _talk;
  late PreferenceLevel _animals;
  late PreferenceLevel _smoke;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider).value;
    final prefs = profile?.preferences ?? TravelPreferences();
    _music = prefs.music;
    _talk = prefs.talk;
    _animals = prefs.animals;
    _smoke = prefs.smoke;
  }

  Future<void> _save() async {
    final currentProfile = ref.read(userProfileProvider).value;
    if (currentProfile == null) return;

    final updatedPrefs = TravelPreferences(
      music: _music,
      talk: _talk,
      animals: _animals,
      smoke: _smoke,
    );

    final updatedProfile = UserProfile(
      username: currentProfile.username,
      fullName: currentProfile.fullName,
      email: currentProfile.email,
      role: currentProfile.role,
      phone: currentProfile.phone,
      university: currentProfile.university,
      degreeCourse: currentProfile.degreeCourse,
      department: currentProfile.department,
      enrollmentYear: currentProfile.enrollmentYear,
      studentId: currentProfile.studentId,
      preferences: updatedPrefs,
      iban: currentProfile.iban,
      ibanHolder: currentProfile.ibanHolder,
      favoriteRoutes: currentProfile.favoriteRoutes,
      upcomingRides: currentProfile.upcomingRides,
    );

    final success = await ref.read(profileControllerProvider.notifier).updateProfile(updatedProfile);
    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferenze aggiornate!'), backgroundColor: AppColors.universityGreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(profileControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: const Text('Preferenze di viaggio'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personalizza la tua esperienza di viaggio impostando le tue preferenze.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),
            
            _buildPreferenceRow('Musica in auto', _music, (val) => setState(() => _music = val), Icons.music_note),
            _buildPreferenceRow('Chiacchiere', _talk, (val) => setState(() => _talk = val), Icons.chat_bubble_outline),
            _buildPreferenceRow('Animali ammessi', _animals, (val) => setState(() => _animals = val), Icons.pets),
            _buildPreferenceRow('Fumo ammesso', _smoke, (val) => setState(() => _smoke = val), Icons.smoke_free),
            
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: isLoading ? null : _save,
                child: isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Salva preferenze', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceRow(String title, PreferenceLevel current, Function(PreferenceLevel) onSelected, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.universityGreen, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildChoiceChip('No', PreferenceLevel.dislike, current == PreferenceLevel.dislike, () => onSelected(PreferenceLevel.dislike)),
              _buildChoiceChip('Indifferente', PreferenceLevel.neutral, current == PreferenceLevel.neutral, () => onSelected(PreferenceLevel.neutral)),
              _buildChoiceChip('Sì', PreferenceLevel.like, current == PreferenceLevel.like, () => onSelected(PreferenceLevel.like)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, PreferenceLevel level, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - 64) / 3,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.universityGreen : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.universityGreen : Colors.white10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
