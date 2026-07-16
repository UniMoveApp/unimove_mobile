import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../../profile/presentation/reviews_controller.dart';
import '../../auth/presentation/auth_controller.dart';

class LeaveReviewDialog extends ConsumerStatefulWidget {
  final String rideId;
  final String driverName;
  final String driverUsername;

  const LeaveReviewDialog({
    super.key,
    required this.rideId,
    required this.driverName,
    required this.driverUsername,
  });

  static Future<void> show(
    BuildContext context, {
    required String rideId,
    required String driverName,
    required String driverUsername,
    required VoidCallback onSubmitted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: LeaveReviewDialog(
          rideId: rideId,
          driverName: driverName,
          driverUsername: driverUsername,
        ),
      ),
    ).then((value) {
      onSubmitted();
    });
  }

  @override
  ConsumerState<LeaveReviewDialog> createState() => _LeaveReviewDialogState();
}

class _LeaveReviewDialogState extends ConsumerState<LeaveReviewDialog> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  final Map<int, String> _ratingLabels = {
    1: 'Molto scarso',
    2: 'Scarso',
    3: 'Sufficiente',
    4: 'Buono',
    5: 'Eccellente!',
  };

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final success = await ref.read(reviewsControllerProvider.notifier).leaveReview(
          rideId: widget.rideId,
          rating: _rating,
          comment: _commentController.text.trim(),
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        // Forza il refresh del provider di verifica recensione, del profilo e dell'archivio
        ref.invalidate(isRideReviewedProvider((rideId: widget.rideId, driverUsername: widget.driverUsername)));
        ref.invalidate(userProfileProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 10),
                Text('Recensione inviata con successo!'),
              ],
            ),
            backgroundColor: AppColors.universityGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      } else {
        final errorState = ref.read(reviewsControllerProvider);
        String errorMessage = 'Errore durante l\'invio della recensione';
        if (errorState is AsyncError) {
          final error = errorState.error;
          final errorStr = error.toString();
          if (errorStr.contains('gia recensito') || errorStr.contains('già recensito')) {
            errorMessage = 'Hai già recensito questa corsa';
          } else {
            errorMessage = errorStr.replaceAll('Exception:', '').trim();
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Lascia una recensione',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Driver Name
            Text(
              'Come è stato il tuo viaggio con ${widget.driverName}?',
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Interactive Stars Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                final isFilled = starValue <= _rating;
                return GestureDetector(
                  onTap: _isSubmitting ? null : () {
                    setState(() => _rating = starValue);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: Icon(
                      isFilled ? Icons.star : Icons.star_border,
                      color: isFilled ? AppColors.universityGreen : Colors.white24,
                      size: 40,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),

            // Rating textual label
            Text(
              _ratingLabels[_rating] ?? '',
              style: const TextStyle(
                color: AppColors.universityGreen,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Optional Comment Text Field
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 500,
              enabled: !_isSubmitting,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Scrivi un commento opzionale...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                fillColor: AppColors.deepBlack,
                filled: true,
                counterStyle: const TextStyle(color: AppColors.textMuted),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.universityGreen, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Send Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.universityGreen,
                disabledBackgroundColor: AppColors.universityGreen.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Invia Recensione',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
