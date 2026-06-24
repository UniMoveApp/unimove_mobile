import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/services/api_client.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/domain/user_profile.dart';

final profileControllerProvider = StateNotifierProvider<ProfileController, AsyncValue<void>>((ref) {
  return ProfileController(ref);
});

class ProfileController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ProfileController(this._ref) : super(const AsyncValue.data(null));

  Future<bool> updateProfile(UserProfile updatedProfile) async {
    state = const AsyncValue.loading();
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.dio.put(
        'users/me',
        data: updatedProfile.toJson(),
      );

      if (response.statusCode == 200) {
        state = const AsyncValue.data(null);
        _ref.invalidate(userProfileProvider);
        return true;
      }
      state = AsyncValue.error('Errore durante l\'aggiornamento del profilo', StackTrace.current);
      return false;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Errore di rete durante l\'aggiornamento';
      state = AsyncValue.error(message, StackTrace.current);
      return false;
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return false;
    }
  }

  Future<bool> updateFavoriteRoutes(List<String> routes) async {
    state = const AsyncValue.loading();
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.dio.patch(
        'users/me',
        data: {'favoriteRoutes': routes},
      );

      if (response.statusCode == 200) {
        state = const AsyncValue.data(null);
        _ref.invalidate(userProfileProvider);
        return true;
      }
      state = AsyncValue.error('Errore durante l\'aggiornamento delle tratte', StackTrace.current);
      return false;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Errore di rete';
      state = AsyncValue.error(message, StackTrace.current);
      return false;
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return false;
    }
  }
}
