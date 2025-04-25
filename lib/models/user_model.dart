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
  final String role; // 'SUPER_ADMIN' or 'ADMIN'

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
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Check if the email is superadmin@paridhi2025.com to determine role
    final isSuperAdmin = json['email'] == 'superadmin@paridhi2025.com';

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
      role: isSuperAdmin ? 'SUPER_ADMIN' : 'ADMIN',
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
    };
  }
}
