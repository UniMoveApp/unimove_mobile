import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_client.dart';
import '../../auth/presentation/auth_controller.dart';

class ReviewsController extends StateNotifier<AsyncValue<void>> {
  final ApiClient _apiClient;

  ReviewsController(this._apiClient) : super(const AsyncValue.data(null));

  Future<bool> leaveReview({
    required String rideId,
    required int rating,
    required String comment,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.dio.post(
        'reviews',
        data: {
          'rideId': rideId,
          'rating': rating,
          'comment': comment,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        state = const AsyncValue.data(null);
        return true;
      }
      throw Exception('Errore durante l\'invio della recensione');
    } catch (e, stack) {
      if (e is DioException && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          state = AsyncValue.error(data['message'].toString(), stack);
          return false;
        } else if (data is String && data.isNotEmpty) {
          state = AsyncValue.error(data, stack);
          return false;
        }
      }
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

final reviewsControllerProvider = StateNotifierProvider<ReviewsController, AsyncValue<void>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReviewsController(apiClient);
});

// Cache per salvare se una determinata corsa è stata recensita
final isRideReviewedProvider = FutureProvider.family<bool, ({String rideId, String driverUsername})>((ref, arg) async {
  final apiClient = ref.watch(apiClientProvider);
  final userProfile = await ref.watch(userProfileProvider.future);
  if (userProfile == null) return false;

  try {
    final response = await apiClient.dio.get('reviews/user/${arg.driverUsername}');
    if (response.statusCode == 200 && response.data != null) {
      final list = response.data as List<dynamic>;
      // Controlla se esiste una recensione per la corsa specifica scritta dall'utente loggato
      return list.any((review) =>
          review['rideId'] == arg.rideId &&
          (review['reviewerUsername'] == userProfile.username ||
           review['authorName'] == userProfile.fullName ||
           review['reviewerFullName'] == userProfile.fullName));
    }
  } catch (e) {
    debugPrint('Errore nella verifica della recensione per la corsa ${arg.rideId}: $e');
  }
  return false;
});
