class Ride {
  final String id;
  final String driverUsername;
  final String driverFullName;
  final String departureCity;
  final DateTime departureTime;
  final String arrivalCity;
  final DateTime arrivalTimeEst;
  final List<String> hotspots;
  final String? vehicleModel;
  final String? vehiclePlate;
  final int totalSeats;
  final int availableSeats;
  final String? travelPreferences;
  final String status;

  Ride({
    required this.id,
    required this.driverUsername,
    required this.driverFullName,
    required this.departureCity,
    required this.departureTime,
    required this.arrivalCity,
    required this.arrivalTimeEst,
    required this.hotspots,
    this.vehicleModel,
    this.vehiclePlate,
    required this.totalSeats,
    required this.availableSeats,
    this.travelPreferences,
    required this.status,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'] as String,
      driverUsername: json['driverUsername'] as String? ?? '',
      driverFullName: json['driverFullName'] as String? ?? '',
      departureCity: json['departureCity'] as String? ?? '',
      departureTime: DateTime.parse(json['departureTime'] as String),
      arrivalCity: json['arrivalCity'] as String? ?? '',
      arrivalTimeEst: DateTime.parse(json['arrivalTimeEst'] as String),
      hotspots: (json['hotspots'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      vehicleModel: json['vehicleModel'] as String?,
      vehiclePlate: json['vehiclePlate'] as String?,
      totalSeats: json['totalSeats'] as int? ?? 0,
      availableSeats: json['availableSeats'] as int? ?? 0,
      travelPreferences: json['travelPreferences'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }
}

class UserProfile {
  final String username;
  final String fullName;
  final String email;
  final String role;
  final String? avatarUrl;
  final String? travelPreferences;
  final String? iban;
  final String? ibanHolder;
  final List<Ride> upcomingRides;

  UserProfile({
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.travelPreferences,
    this.iban,
    this.ibanHolder,
    required this.upcomingRides,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'USER',
      avatarUrl: json['avatarUrl'] as String?,
      travelPreferences: json['travelPreferences'] as String?,
      iban: json['iban'] as String?,
      ibanHolder: json['ibanHolder'] as String?,
      upcomingRides: (json['upcomingRides'] as List<dynamic>?)
              ?.map((e) => Ride.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
