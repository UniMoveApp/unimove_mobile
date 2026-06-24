import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/domain/user_profile.dart';
import 'profile_controller.dart';

class EditIbanScreen extends ConsumerStatefulWidget {
  const EditIbanScreen({super.key});

  @override
  ConsumerState<EditIbanScreen> createState() => _EditIbanScreenState();
}

class _EditIbanScreenState extends ConsumerState<EditIbanScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _ibanController;
  late TextEditingController _holderController;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider).value;
    _ibanController = TextEditingController(text: profile?.iban);
    _holderController = TextEditingController(text: profile?.ibanHolder);
  }

  @override
  void dispose() {
    _ibanController.dispose();
    _holderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final currentProfile = ref.read(userProfileProvider).value;
    if (currentProfile == null) return;

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
      preferences: currentProfile.preferences,
      iban: _ibanController.text.trim(),
      ibanHolder: _holderController.text.trim(),
      favoriteRoutes: currentProfile.favoriteRoutes,
      upcomingRides: currentProfile.upcomingRides,
    );

    final success = await ref.read(profileControllerProvider.notifier).updateProfile(updatedProfile);
    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('IBAN aggiornato correttamente'), backgroundColor: AppColors.universityGreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(profileControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: const Text('Metodo di pagamento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Inserisci il tuo IBAN per poter ricevere i pagamenti dei passeggeri.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _holderController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Intestatario conto',
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.universityGreen),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Inserisci l\'intestatario' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ibanController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'IBAN',
                  prefixIcon: Icon(Icons.account_balance_outlined, color: AppColors.universityGreen),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Inserisci l\'IBAN';
                  // Simple IBAN validation (can be improved)
                  if (val.length < 15) return 'IBAN non valido';
                  return null;
                },
              ),
              
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _save,
                  child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Salva IBAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'I tuoi dati bancari sono cifrati e gestiti in sicurezza.',
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
