import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/services/api_client.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/presentation/auth_controller.dart';
import 'my_rides_controller.dart';
import '../../home/presentation/home_screen.dart';

class PassengerBooking {
  final String id;
  final String rideId;
  final String passengerUsername;
  final String passengerFullName;
  final String? hotspotChosen;
  final String status;
  final DateTime? createdAt;
  final Ride? ride;

  PassengerBooking({
    required this.id,
    required this.rideId,
    required this.passengerUsername,
    required this.passengerFullName,
    this.hotspotChosen,
    required this.status,
    this.createdAt,
    this.ride,
  });

  factory PassengerBooking.fromJson(Map<String, dynamic> json, {Ride? ride}) {
    return PassengerBooking(
      id: json['id'] as String,
      rideId: json['rideId'] as String,
      passengerUsername: json['passengerUsername'] as String? ?? '',
      passengerFullName: json['passengerFullName'] as String? ?? '',
      hotspotChosen: json['hotspotChosen'] as String?,
      status: json['status'] as String? ?? 'CONFIRMED',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      ride: ride,
    );
  }

  PassengerBooking copyWith({Ride? ride}) {
    return PassengerBooking(
      id: id,
      rideId: rideId,
      passengerUsername: passengerUsername,
      passengerFullName: passengerFullName,
      hotspotChosen: hotspotChosen,
      status: status,
      createdAt: createdAt,
      ride: ride ?? this.ride,
    );
  }
}

final myBookingsProvider = FutureProvider<List<PassengerBooking>>((ref) async {
  // Guard: non effettuare chiamate API se l'utente non è autenticato
  final authState = ref.watch(authControllerProvider);
  if (authState.status != AuthStatus.authenticated) return [];

  final apiClient = ref.watch(apiClientProvider);

  // 1. Fetch passenger bookings
  final bookingsResponse = await apiClient.dio.get('bookings/my');
  if (bookingsResponse.statusCode != 200 || bookingsResponse.data == null) {
    throw Exception('Impossibile caricare le tue prenotazioni');
  }

  final bookingsRawList = bookingsResponse.data as List<dynamic>;
  final bookings = bookingsRawList
      .map((e) => PassengerBooking.fromJson(e as Map<String, dynamic>))
      .toList();

  if (bookings.isEmpty) {
    return [];
  }

  // 2. Costruisci la rideMap usando rides/search (OPEN) + rides/my?status=IN_PROGRESS
  // rides/search restituisce solo OPEN, rides/my restituisce le proprie corse come driver.
  // Per le corse altrui IN_PROGRESS non abbiamo un endpoint diretto, ma possiamo
  // usare rides/search senza filtro status per OPEN e tollerare null per le IN_PROGRESS.
  final Map<String, Ride> rideMap = {};

  try {
    // Corse aperte (dove il passeggero può prenotare): rides/search → solo OPEN
    final searchResponse = await apiClient.dio.get('rides/search');
    if (searchResponse.statusCode == 200 && searchResponse.data != null) {
      final ridesList = (searchResponse.data as List<dynamic>)
          .map((e) => Ride.fromJson(e as Map<String, dynamic>))
          .toList();
      for (final r in ridesList) {
        rideMap[r.id] = r;
      }
    }
  } catch (_) {}

  try {
    // Corse in cui l'utente è driver e sono IN_PROGRESS (copre il caso driver/passeggero)
    final inProgressResponse = await apiClient.dio.get(
      'rides/my',
      queryParameters: {'status': 'IN_PROGRESS'},
    );
    if (inProgressResponse.statusCode == 200 && inProgressResponse.data != null) {
      final ridesList = (inProgressResponse.data as List<dynamic>)
          .map((e) => Ride.fromJson(e as Map<String, dynamic>))
          .toList();
      for (final r in ridesList) {
        rideMap[r.id] = r;
      }
    }
  } catch (_) {}

  // 3. Associa ogni booking alla sua corsa e filtra:
  //    - Se ride trovata: mostra solo se OPEN o IN_PROGRESS
  //    - Se ride NON trovata (es. corsa completata non accessibile via search): escludi
  return bookings
      .map((b) => b.copyWith(ride: rideMap[b.rideId]))
      .where((b) {
        final rideStatus = b.ride?.status;
        if (rideStatus == null) return false; // corsa non trovata = completata o cancellata
        return rideStatus == 'OPEN' || rideStatus == 'IN_PROGRESS';
      })
      .toList();
});


class MyBookingsService {
  final ApiClient _apiClient;
  final Ref _ref;

  MyBookingsService(this._apiClient, this._ref);

  Future<void> cancelBooking(String bookingId) async {
    try {
      final response = await _apiClient.dio.delete('bookings/$bookingId');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _ref.invalidate(myBookingsProvider);
        _ref.invalidate(userProfileProvider);
        _ref.invalidate(myRidesProvider);
        _ref.invalidate(archivedRidesProvider);
      } else {
        throw Exception('Errore durante la cancellazione della prenotazione');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ?? e.response?.data?['message'] ?? e.message ?? 'Impossibile cancellare la prenotazione';
      throw Exception(msg);
    }
  }
}

final myBookingsServiceProvider = Provider<MyBookingsService>((ref) {
  return MyBookingsService(ref.watch(apiClientProvider), ref);
});
