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
      status: json['status'] as String? ?? 'OPEN',
    );
  }
}

class UserProfile {
  final String username;
  final String fullName;
  final String email;
  final String role;
  final String? phone;
  final String? gender;
  final String? birthDate;
  final String? university;
  final String? degreeCourse;
  final String? department;
  final String? enrollmentYear;
  final String? studentId;
  final String? avatarUrl;
  final String? travelPreferences;
  final String? iban;
  final String? ibanHolder;
  final List<String> favoriteRoutes;
  final List<Ride> upcomingRides;
  final List<UserReview> reviews;

  UserProfile({
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
    this.gender,
    this.birthDate,
    this.university,
    this.degreeCourse,
    this.department,
    this.enrollmentYear,
    this.studentId,
    this.avatarUrl,
    this.travelPreferences,
    this.iban,
    this.ibanHolder,
    required this.favoriteRoutes,
    required this.upcomingRides,
    this.reviews = const [],
  });

  UserProfile copyWith({
    String? username,
    String? fullName,
    String? email,
    String? role,
    String? phone,
    String? gender,
    String? birthDate,
    String? university,
    String? degreeCourse,
    String? department,
    String? enrollmentYear,
    String? studentId,
    String? avatarUrl,
    String? travelPreferences,
    String? iban,
    String? ibanHolder,
    List<String>? favoriteRoutes,
    List<Ride>? upcomingRides,
    List<UserReview>? reviews,
  }) {
    return UserProfile(
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      university: university ?? this.university,
      degreeCourse: degreeCourse ?? this.degreeCourse,
      department: department ?? this.department,
      enrollmentYear: enrollmentYear ?? this.enrollmentYear,
      studentId: studentId ?? this.studentId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      travelPreferences: travelPreferences ?? this.travelPreferences,
      iban: iban ?? this.iban,
      ibanHolder: ibanHolder ?? this.ibanHolder,
      favoriteRoutes: favoriteRoutes ?? this.favoriteRoutes,
      upcomingRides: upcomingRides ?? this.upcomingRides,
      reviews: reviews ?? this.reviews,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'USER',
      phone: json['phone'] as String?,
      gender: json['gender'] as String?,
      birthDate: json['birthDate'] as String?,
      university: json['university'] as String?,
      degreeCourse: json['degreeCourse'] as String?,
      department: json['department'] as String?,
      enrollmentYear: json['enrollmentYear'] as String?,
      studentId: json['studentId'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      travelPreferences: json['travelPreferences'] as String?,
      iban: json['iban'] as String?,
      ibanHolder: json['ibanHolder'] as String?,
      favoriteRoutes: (json['favoriteRoutes'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      upcomingRides: (json['upcomingRides'] as List<dynamic>?)
              ?.map((e) => Ride.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((e) => UserReview.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      'gender': gender,
      'birthDate': birthDate,
      'university': university,
      'degreeCourse': degreeCourse,
      'department': department,
      'enrollmentYear': enrollmentYear,
      'studentId': studentId,
      'travelPreferences': travelPreferences,
      'iban': iban,
      'ibanHolder': ibanHolder,
      'favoriteRoutes': favoriteRoutes,
    };
  }
}

class TravelPreferences {
  final PreferenceLevel music;
  final PreferenceLevel talk;
  final PreferenceLevel animals;
  final PreferenceLevel smoke;
  final PreferenceLevel ac;

  TravelPreferences({
    this.music = PreferenceLevel.neutral,
    this.talk = PreferenceLevel.neutral,
    this.animals = PreferenceLevel.neutral,
    this.smoke = PreferenceLevel.neutral,
    this.ac = PreferenceLevel.neutral,
  });

  factory TravelPreferences.fromString(String prefStr) {
    // Expected format: "music:1,talk:2,animals:0,smoke:0,ac:1" or similar
    final parts = prefStr.split(',');
    PreferenceLevel music = PreferenceLevel.neutral;
    PreferenceLevel talk = PreferenceLevel.neutral;
    PreferenceLevel animals = PreferenceLevel.neutral;
    PreferenceLevel smoke = PreferenceLevel.neutral;
    PreferenceLevel ac = PreferenceLevel.neutral;

    for (var part in parts) {
      final kv = part.split(':');
      if (kv.length == 2) {
        final key = kv[0].trim();
        final value = int.tryParse(kv[1].trim()) ?? 0;
        final level = PreferenceLevel.fromInt(value);
        if (key == 'music') music = level;
        if (key == 'talk') talk = level;
        if (key == 'animals') animals = level;
        if (key == 'smoke') smoke = level;
        if (key == 'ac') ac = level;
      }
    }
    return TravelPreferences(music: music, talk: talk, animals: animals, smoke: smoke, ac: ac);
  }

  @override
  String toString() {
    return 'music:${music.value},talk:${talk.value},animals:${animals.value},smoke:${smoke.value},ac:${ac.value}';
  }
}

class UserReview {
  final String? id;
  final String? rideId;
  final String? reviewerUsername;
  final String authorName;
  final String? authorAvatar;
  final double rating;
  final String comment;
  final DateTime date;

  UserReview({
    this.id,
    this.rideId,
    this.reviewerUsername,
    required this.authorName,
    this.authorAvatar,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory UserReview.fromJson(Map<String, dynamic> json) {
    final reviewerFullName = json['reviewerFullName'] as String?;
    final authorName = json['authorName'] as String?;
    final reviewerUsername = json['reviewerUsername'] as String?;

    String displayName = 'Utente Anonimo';
    if (reviewerFullName != null && reviewerFullName.trim().isNotEmpty) {
      displayName = reviewerFullName.trim();
    } else if (authorName != null && authorName.trim().isNotEmpty) {
      displayName = authorName.trim();
    } else if (reviewerUsername != null && reviewerUsername.trim().isNotEmpty) {
      displayName = reviewerUsername.trim();
    }

    return UserReview(
      id: json['id'] as String?,
      rideId: json['rideId'] as String?,
      reviewerUsername: reviewerUsername,
      authorName: displayName,
      authorAvatar: json['authorAvatar'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'] as String? ?? '',
      date: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : (json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now()),
    );
  }
}

enum PreferenceLevel {
  dislike(0),
  neutral(1),
  like(2);

  final int value;
  const PreferenceLevel(this.value);

  static PreferenceLevel fromInt(int value) {
    return PreferenceLevel.values.firstWhere((e) => e.value == value, orElse: () => PreferenceLevel.neutral);
  }
}
