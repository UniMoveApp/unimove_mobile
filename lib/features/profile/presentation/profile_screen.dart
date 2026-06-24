import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/domain/user_profile.dart';
import '../../../shared/widgets/skeleton.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: SafeArea(
        child: userProfileAsync.when(
          data: (profile) => profile == null 
            ? const Center(child: Text('Profilo non trovato')) 
            : _buildProfileContent(context, ref, profile),
          loading: () => _buildLoadingSkeleton(),
          error: (err, _) => Center(child: Text('Errore: $err')),
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, WidgetRef ref, UserProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar and Name Section
          _buildHeader(profile, context),
          const SizedBox(height: 32),
          
          // Info Card (Contact + Preferences)
          _buildInfoCard(profile),
          
          const SizedBox(height: 32),
          
          // Reviews Section
          _buildReviewsSection(profile),
          
          const SizedBox(height: 48),
          
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => ref.read(authControllerProvider.notifier).logout(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent.withValues(alpha: 0.7),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Logout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(UserProfile profile, BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.universityGreen.withValues(alpha: 0.5), width: 2),
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.surfaceDark,
            backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
            child: profile.avatarUrl == null 
              ? const Icon(Icons.person, size: 60, color: AppColors.textMuted) 
              : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          profile.fullName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          profile.role == 'DRIVER' ? 'Autista' : 'Studente',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.universityGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified, size: 14, color: AppColors.universityGreen),
              SizedBox(width: 4),
              Text(
                'Studente verificato',
                style: TextStyle(color: AppColors.universityGreen, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(UserProfile profile) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          // Contact Info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.email_outlined, color: AppColors.textMuted, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informazioni di contatto',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.email,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
          
          // Travel Preferences Summary
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.favorite_border, color: AppColors.textMuted, size: 22),
                    SizedBox(width: 16),
                    Text(
                      'Preferenze di viaggio',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildPreferenceBox(Icons.music_note, profile.preferences?.music),
                    _buildPreferenceBox(Icons.chat_bubble_outline, profile.preferences?.talk),
                    _buildPreferenceBox(Icons.pets, profile.preferences?.animals),
                    _buildPreferenceBox(Icons.smoke_free, profile.preferences?.smoke),
                    _buildPreferenceBox(Icons.shopping_bag_outlined, PreferenceLevel.neutral), // Bagaglio
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceBox(IconData icon, PreferenceLevel? level) {
    Color iconColor = AppColors.textMuted;
    if (level == PreferenceLevel.like) iconColor = AppColors.universityGreen;
    if (level == PreferenceLevel.dislike) iconColor = Colors.redAccent.withValues(alpha: 0.5);

    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.deepBlack,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }

  Widget _buildReviewsSection(UserProfile profile) {
    return Column(
      children: [
        const Text(
          'Recensioni',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        if (profile.reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Nessuna recensione ancora',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          )
        else
          ...profile.reviews.map((review) => _buildReviewCard(review)),
      ],
    );
  }

  Widget _buildReviewCard(UserReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.deepBlack,
            backgroundImage: review.authorAvatar != null ? NetworkImage(review.authorAvatar!) : null,
            child: review.authorAvatar == null 
              ? const Icon(Icons.person, size: 20, color: AppColors.textMuted) 
              : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'da ${review.authorName}',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Row(
                  children: List.generate(5, (index) => Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    size: 14,
                    color: index < review.rating ? Colors.amber : AppColors.textMuted,
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        children: [
          Skeleton(width: 100, height: 100, borderRadius: 50),
          SizedBox(height: 24),
          Skeleton(width: 200, height: 24),
          SizedBox(height: 40),
          Skeleton(width: double.infinity, height: 150, borderRadius: 20),
          SizedBox(height: 24),
          Skeleton(width: 120, height: 20),
          SizedBox(height: 16),
          Skeleton(width: double.infinity, height: 80, borderRadius: 16),
        ],
      ),
    );
  }
}
