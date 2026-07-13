class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final SeekerData? seekerData;
  final ListenerData? listenerData;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.seekerData,
    this.listenerData,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      seekerData: json['seekerData'] != null
          ? SeekerData.fromJson(json['seekerData'] as Map<String, dynamic>)
          : null,
      listenerData: json['listenerData'] != null
          ? ListenerData.fromJson(json['listenerData'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      if (seekerData != null) 'seekerData': seekerData!.toJson(),
      if (listenerData != null) 'listenerData': listenerData!.toJson(),
    };
  }
}

class SeekerData {
  final double walletBalance;
  final List<String> preferredLanguages;
  final List<String> safeCircle;

  SeekerData({
    required this.walletBalance,
    required this.preferredLanguages,
    required this.safeCircle,
  });

  factory SeekerData.fromJson(Map<String, dynamic> json) {
    return SeekerData(
      walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0.0,
      preferredLanguages: (json['preferredLanguages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      safeCircle: (json['safeCircle'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'walletBalance': walletBalance,
      'preferredLanguages': preferredLanguages,
      'safeCircle': safeCircle,
    };
  }
}

class ListenerData {
  final bool isOnline;
  final String status;
  final List<String> languagesSpoken;
  final List<String> specialties;
  final String bio;
  final ListenerStats? stats;

  ListenerData({
    required this.isOnline,
    required this.status,
    required this.languagesSpoken,
    this.specialties = const [],
    this.bio = '',
    this.stats,
  });

  factory ListenerData.fromJson(Map<String, dynamic> json) {
    return ListenerData(
      isOnline: json['isOnline'] as bool? ?? false,
      status: json['status'] as String? ?? 'offline',
      languagesSpoken: (json['languagesSpoken'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      specialties: (json['specialties'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      bio: json['bio'] as String? ?? '',
      stats: json['stats'] != null
          ? ListenerStats.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isOnline': isOnline,
      'status': status,
      'languagesSpoken': languagesSpoken,
      'specialties': specialties,
      'bio': bio,
      if (stats != null) 'stats': stats!.toJson(),
    };
  }
}

class ListenerStats {
  final double rating;
  final int minutesListened;

  ListenerStats({
    required this.rating,
    required this.minutesListened,
  });

  factory ListenerStats.fromJson(Map<String, dynamic> json) {
    return ListenerStats(
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      minutesListened: (json['minutesListened'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'minutesListened': minutesListened,
    };
  }
}
