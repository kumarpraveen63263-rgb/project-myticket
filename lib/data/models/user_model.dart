class UserModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final int bookingsCount;
  final int savedCount;
  final int rewardPoints;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.avatarUrl,
    this.bookingsCount = 0,
    this.savedCount = 0,
    this.rewardPoints = 0,
  });

  UserModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? avatarUrl,
    int? bookingsCount,
    int? savedCount,
    int? rewardPoints,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bookingsCount: bookingsCount ?? this.bookingsCount,
      savedCount: savedCount ?? this.savedCount,
      rewardPoints: rewardPoints ?? this.rewardPoints,
    );
  }

  /// Serializes the user model to a Map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'avatarUrl': avatarUrl,
      'bookingsCount': bookingsCount,
      'savedCount': savedCount,
      'rewardPoints': rewardPoints,
    };
  }

  /// Deserializes a user model from a Firestore document map.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'MyTickets User',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      bookingsCount: map['bookingsCount'] as int? ?? 0,
      savedCount: map['savedCount'] as int? ?? 0,
      rewardPoints: map['rewardPoints'] as int? ?? 0,
    );
  }
}
