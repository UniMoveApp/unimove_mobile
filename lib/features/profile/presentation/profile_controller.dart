import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_client.dart';
import '../../auth/domain/user_profile.dart';

class ProfileController extends StateNotifier<AsyncValue<UserProfile?>> {
  final ApiClient _apiClient;

  ProfileController(this._apiClient) : super(const AsyncValue.loading());

  Future<UserProfile?> fetchProfile() async {
    if (state.value == null) {
      state = const AsyncValue.loading();
    }
    try {
      final response = await _apiClient.dio.get('users/me');
      if (response.statusCode == 200 && response.data != null) {
        var profile = UserProfile.fromJson(response.data as Map<String, dynamic>);
        try {
          final reviewsResponse = await _apiClient.dio.get('reviews/user/${profile.username}');
          if (reviewsResponse.statusCode == 200 && reviewsResponse.data != null) {
            final reviewsList = (reviewsResponse.data as List<dynamic>)
                .map((e) => UserReview.fromJson(e as Map<String, dynamic>))
                .toList();
            profile = profile.copyWith(reviews: reviewsList);
          }
        } catch (e) {
          // Se il recupero delle recensioni fallisce, procediamo comunque con il profilo
          debugPrint('Errore nel caricamento delle recensioni: $e');
        }
        state = AsyncValue.data(profile);
        return profile;
      }
      throw Exception('Impossibile caricare il profilo');
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<bool> updatePreferences(String travelPreferences) async {
    final currentProfile = state.value;
    if (currentProfile == null) return false;

    try {
      final response = await _apiClient.dio.put(
        'users/me/preferences',
        data: {'travelPreferences': travelPreferences},
      );
      if (response.statusCode == 200) {
        final updatedProfile = currentProfile.copyWith(travelPreferences: travelPreferences);
        state = AsyncValue.data(updatedProfile);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateIban(String iban, String ibanHolder) async {
    final currentProfile = state.value;
    if (currentProfile == null) return false;

    try {
      final response = await _apiClient.dio.put(
        'users/me/iban',
        data: {
          'iban': iban,
          'ibanHolder': ibanHolder,
        },
      );
      if (response.statusCode == 200) {
        final updatedProfile = currentProfile.copyWith(iban: iban, ibanHolder: ibanHolder);
        state = AsyncValue.data(updatedProfile);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

final profileControllerProvider = StateNotifierProvider<ProfileController, AsyncValue<UserProfile?>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileController(apiClient);
});

final userReviewsProvider = FutureProvider.family<List<UserReview>, String>((ref, userIdOrUsername) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.dio.get('reviews/user/$userIdOrUsername');
    if (response.statusCode == 200 && response.data != null) {
      return (response.data as List<dynamic>)
          .map((e) => UserReview.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  } catch (e) {
    debugPrint('Errore nel recupero recensioni per $userIdOrUsername: $e');
  }
  return [];
});
