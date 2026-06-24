import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/domain/user_profile.dart';
import 'profile_controller.dart';

class EditPersonalInfoScreen extends ConsumerStatefulWidget {
  const EditPersonalInfoScreen({super.key});

  @override
  ConsumerState<EditPersonalInfoScreen> createState() => _EditPersonalInfoScreenState();
}

class _EditPersonalInfoScreenState extends ConsumerState<EditPersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _universityController;
  late TextEditingController _degreeController;
  late TextEditingController _departmentController;
  late TextEditingController _yearController;
  late TextEditingController _studentIdController;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider).value;
    _fullNameController = TextEditingController(text: profile?.fullName);
    _phoneController = TextEditingController(text: profile?.phone);
    _universityController = TextEditingController(text: profile?.university);
    _degreeController = TextEditingController(text: profile?.degreeCourse);
    _departmentController = TextEditingController(text: profile?.department);
    _yearController = TextEditingController(text: profile?.enrollmentYear);
    _studentIdController = TextEditingController(text: profile?.studentId);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _universityController.dispose();
    _degreeController.dispose();
    _departmentController.dispose();
    _yearController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final currentProfile = ref.read(userProfileProvider).value;
    if (currentProfile == null) return;

    final updatedProfile = UserProfile(
      username: currentProfile.username,
      fullName: _fullNameController.text.trim(),
      email: currentProfile.email,
      role: currentProfile.role,
      phone: _phoneController.text.trim(),
      university: _universityController.text.trim(),
      degreeCourse: _degreeController.text.trim(),
      department: _departmentController.text.trim(),
      enrollmentYear: _yearController.text.trim(),
      studentId: _studentIdController.text.trim(),
      preferences: currentProfile.preferences,
      iban: currentProfile.iban,
      ibanHolder: currentProfile.ibanHolder,
      favoriteRoutes: currentProfile.favoriteRoutes,
      upcomingRides: currentProfile.upcomingRides,
    );

    final success = await ref.read(profileControllerProvider.notifier).updateProfile(updatedProfile);
    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profilo aggiornato con successo!'), backgroundColor: AppColors.universityGreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(profileControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: const Text('Informazioni personali'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Dati Anagrafici'),
              const SizedBox(height: 16),
              _buildTextField(label: 'Nome e Cognome', controller: _fullNameController, icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(label: 'Telefono', controller: _phoneController, icon: Icons.phone_android_outlined, keyboardType: TextInputType.phone),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Dati Istituzionali'),
              const SizedBox(height: 16),
              _buildTextField(label: 'Università', controller: _universityController, icon: Icons.school_outlined),
              const SizedBox(height: 16),
              _buildTextField(label: 'Corso di Studi', controller: _degreeController, icon: Icons.book_outlined),
              const SizedBox(height: 16),
              _buildTextField(label: 'Dipartimento', controller: _departmentController, icon: Icons.account_balance_outlined),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(label: 'Anno Iscrizione', controller: _yearController, icon: Icons.calendar_today_outlined, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(label: 'Matricola', controller: _studentIdController, icon: Icons.badge_outlined)),
                ],
              ),
              
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _save,
                  child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Salva modifiche', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.universityGreen, letterSpacing: 1),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.universityGreen, size: 20),
      ),
      validator: (val) => val == null || val.isEmpty ? 'Campo obbligatorio' : null,
    );
  }
}
