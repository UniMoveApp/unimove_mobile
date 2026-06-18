import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({super.key});

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final List<bool> _preferences = [false, false, false, false, false];
  
  // Descriptive icons for preferences
  final List<IconData> _preferenceIcons = [
    Icons.smoke_free,       // No smoking
    Icons.music_note,       // Music
    Icons.pets,             // Pets allowed
    Icons.chat_bubble_outline, // Chatty
    Icons.ac_unit,          // Air conditioning
  ];

  final List<String> _preferenceLabels = [
    'No fumo',
    'Musica',
    'Animali',
    'Chiacchiere',
    'Aria cond.',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildField(label: 'Data di partenza', hint: 'dd/mm/aaaa'),
          _buildField(label: 'Città (o punto) di partenza', hint: 'Campobasso'),
          _buildField(label: 'Orario di partenza', hint: 'hh:mm'),
          _buildField(label: 'Punto di incontro n.1 (opzionale)', hint: 'hotspot'),
          _buildField(label: 'Punto di incontro n.2 (opzionale)', hint: 'hotspot'),
          _buildField(label: 'Punto di incontro n.3 (opzionale)', hint: 'hotspot'),
          _buildField(label: 'Città (o punto) di arrivo', hint: 'Pesche'),
          _buildField(label: 'Orario stimato di arrivo', hint: 'hh:mm'),
          _buildField(label: 'Modello veicolo', hint: 'BMW'),
          _buildField(label: 'Targa veicolo', hint: '22BGH66'),
          _buildField(label: 'Numero posti', hint: '5'),
          
          const SizedBox(height: 16),
          const Text(
            'Preferenze',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          // Scrollable or wrapping preferences to avoid overflow and allow labels
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            children: List.generate(5, (index) => _buildPreferenceIcon(index)),
          ),
          
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              // Handle creation logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
            child: const Text(
              'Crea',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildField({required String label, required String hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceIcon(int index) {
    bool isSelected = _preferences[index];
    return GestureDetector(
      onTap: () {
        setState(() {
          _preferences[index] = !isSelected;
        });
      },
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.universityGreen.withOpacity(0.2) : AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.universityGreen : Colors.white10,
                width: 1.5,
              ),
            ),
            child: Icon(
              _preferenceIcons[index],
              color: isSelected ? AppColors.universityGreen : AppColors.textMuted,
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _preferenceLabels[index],
            style: TextStyle(
              color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
