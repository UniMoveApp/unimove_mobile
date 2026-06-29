import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/domain/user_profile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(userProfileProvider.future),
        color: AppColors.universityGreen,
        child: userProfileAsync.when(
          data: (profile) {
            if (profile == null) {
              return const Center(
                child: Text(
                  'Nessun dato profilo disponibile',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            // Calcola la media delle recensioni ricevute
            double averageRating = 0.0;
            if (profile.reviews.isNotEmpty) {
              final sum = profile.reviews.map((r) => r.rating).reduce((a, b) => a + b);
              averageRating = sum / profile.reviews.length;
            }

            // Parsing delle preferenze di viaggio
            final prefs = TravelPreferences.fromString(profile.travelPreferences ?? '');
            final bool hasMusic = prefs.music != PreferenceLevel.dislike;
            final bool hasTalk = prefs.talk != PreferenceLevel.dislike;
            final bool hasAnimals = prefs.animals != PreferenceLevel.dislike;
            final bool hasSmoke = prefs.smoke == PreferenceLevel.like;
            final bool hasAc = prefs.ac != PreferenceLevel.dislike;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Avatar
                  _buildAvatar(profile.avatarUrl),
                  const SizedBox(height: 16),
                  
                  // Name
                  Text(
                    profile.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  
                  // Role in lowercase
                  Text(
                    _formatRole(profile),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Star rating centered under role
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final isFilled = index < averageRating.round();
                      return Icon(
                        isFilled ? Icons.star : Icons.star_border,
                        color: isFilled ? AppColors.universityGreen : Colors.white24,
                        size: 22,
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  // Contact and Travel Preferences Unified Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Contact Info Section
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.mail_outline,
                              color: AppColors.universityGreen,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Informazioni di contatto',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    profile.email,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(color: Colors.white10, height: 1),
                        ),

                        // Travel Preferences Section
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.favorite_border,
                              color: AppColors.universityGreen,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Preferenze di viaggio',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildPreferenceBox(Icons.music_note_outlined, hasMusic),
                                      _buildPreferenceBox(Icons.forum_outlined, hasTalk),
                                      _buildPreferenceBox(Icons.pets_outlined, hasAnimals),
                                      _buildPreferenceBox(Icons.smoking_rooms_outlined, hasSmoke),
                                      _buildPreferenceBox(Icons.ac_unit_outlined, hasAc),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Reviews Title (Centered)
                  const Text(
                    'Recensioni',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reviews List
                  if (profile.reviews.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        'Nessuna recensione ricevuta',
                        style: TextStyle(color: AppColors.textMuted, fontStyle: FontStyle.italic),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: profile.reviews.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final review = profile.reviews[index];
                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Colored avatar circular
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: _getAvatarColor(review.authorName),
                                child: Text(
                                  review.authorName.isNotEmpty ? review.authorName[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'da ${review.authorName}',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: List.generate(5, (starIndex) {
                                        final isFilled = starIndex < review.rating;
                                        return Icon(
                                          isFilled ? Icons.star : Icons.star_border,
                                          color: isFilled ? AppColors.universityGreen : Colors.white24,
                                          size: 14,
                                        );
                                      }),
                                    ),
                                    if (review.comment.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        review.comment,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        _formatDate(review.date),
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
            child: Text(
              'Errore nel caricamento del profilo: $err',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.startsWith('data:image')) {
      try {
        final base64Str = avatarUrl.split(',').last;
        final bytes = base64Decode(base64Str);
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.universityGreen, width: 2),
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundImage: MemoryImage(bytes),
          ),
        );
      } catch (_) {}
    }
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 2),
      ),
      child: const CircleAvatar(
        radius: 50,
        backgroundColor: AppColors.surfaceDark,
        child: Icon(Icons.person, size: 50, color: AppColors.universityGreen),
      ),
    );
  }

  String _formatRole(UserProfile profile) {
    final role = profile.role.toUpperCase();
    final isFemale = profile.gender?.toUpperCase() == 'F' || profile.gender?.toUpperCase() == 'FEMMINA';
    switch (role) {
      case 'STUDENT':
        return isFemale ? 'studentessa' : 'studente';
      case 'PROFESSOR':
        return 'docente';
      case 'STAFF':
        return 'personale PTA';
      default:
        return role.toLowerCase();
    }
  }

  Widget _buildPreferenceBox(IconData icon, bool isActive) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: isActive ? AppColors.universityGreen.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.universityGreen : Colors.white.withValues(alpha: 0.1),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Icon(
        icon,
        color: isActive ? AppColors.universityGreen : AppColors.textMuted,
        size: 20,
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFFD1E8E2), // Muted green-blue
      const Color(0xFFE2D1F9), // Muted lavender
      const Color(0xFFF9E2D2), // Muted peach
      const Color(0xFFD4F1F4), // Muted sky blue
      const Color(0xFFFBE7C6), // Muted soft yellow
    ];
    final hash = name.codeUnits.fold(0, (prev, element) => prev + element);
    return colors[hash % colors.length];
  }

  String _formatDate(DateTime date) {
    final months = ['gen', 'feb', 'mar', 'apr', 'mag', 'giu', 'lug', 'ago', 'set', 'ott', 'nov', 'dic'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
