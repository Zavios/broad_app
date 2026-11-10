/// Application profile model (from /api/profile endpoints).
class UserProfile {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String? verificationStatus;
  final String? dob;
  final String? email;
  final int? phone;
  final String? bio;
  final bool? initialSetup;
  final String? createdAt;

  const UserProfile({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.verificationStatus,
    this.dob,
    this.email,
    this.phone,
    this.bio,
    this.initialSetup,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] ?? '',
    username: json['username'] ?? '',
    firstName: json['firstName'] ?? '',
    lastName: json['lastName'] ?? '',
    verificationStatus: json['verification_status'] as String?,
    dob: json['dob'] as String?,
    email: json['email'] as String?,
    phone: json['phone'] as int?,
    bio: json['bio'] as String?,
    initialSetup: json['initial_setup'] as bool?,
    createdAt: json['created_at'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'firstName': firstName,
    'lastName': lastName,
    'verification_status': verificationStatus,
    'dob': dob,
    'email': email,
    'phone': phone,
    'bio': bio,
    'initial_setup': initialSetup,
    'created_at': createdAt,
  };

  String get fullName => '$firstName $lastName';

  UserProfile copyWith({
    String? id,
    String? username,
    String? firstName,
    String? lastName,
    String? verificationStatus,
    String? dob,
    String? email,
    int? phone,
    String? bio,
    bool? initialSetup,
    String? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      dob: dob ?? this.dob,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      initialSetup: initialSetup ?? this.initialSetup,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Minimal public profile returned when viewing other users.
class PublicProfile {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String? verificationStatus;
  final String? bio;
  final String? createdAt;

  const PublicProfile({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.verificationStatus,
    this.bio,
    this.createdAt,
  });

  factory PublicProfile.fromJson(Map<String, dynamic> json) => PublicProfile(
    id: json['id'] ?? '',
    username: json['username'] ?? '',
    firstName: json['first_name'] ?? json['firstName'] ?? '',
    lastName: json['last_name'] ?? json['lastName'] ?? '',
    verificationStatus: json['verification_status'] as String?,
    bio: json['bio'] as String?,
    createdAt: json['created_at'] as String?,
  );

  String get fullName => '$firstName $lastName';
}
