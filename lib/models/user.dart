class User {
  final int id;
  final String? profilePicture;
  final String name;
  final String email;
  final String? contact;
  final String? college;
  final String? year;
  final String? department;
  final String? roll;
  final List<String> gids;
  final bool verified;
  final bool paid;
  final String role;
  final bool profileCreated;
  final String? lastLogin;
  final String? createdAt;
  final String? updatedAt;

  User({
    required this.id,
    this.profilePicture,
    required this.name,
    required this.email,
    this.contact,
    this.college,
    this.year,
    this.department,
    this.roll,
    required this.gids,
    required this.verified,
    required this.paid,
    required this.role,
    required this.profileCreated,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      profilePicture: json['profilePicture'],
      name: json['name'],
      email: json['email'],
      contact: json['contact'],
      college: json['college'],
      year: json['year'],
      department: json['department'],
      roll: json['roll'],
      gids: List<String>.from(json['gids'] ?? []),
      verified: json['verified'] ?? false,
      paid: json['paid'] ?? false,
      role: json['role'] ?? 'USER',
      profileCreated: json['profileCreated'] ?? false,
      lastLogin: json['lastLogin'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profilePicture': profilePicture,
      'name': name,
      'email': email,
      'contact': contact,
      'college': college,
      'year': year,
      'department': department,
      'roll': roll,
      'gids': gids,
      'verified': verified,
      'paid': paid,
      'role': role,
      'profileCreated': profileCreated,
      'lastLogin': lastLogin,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
