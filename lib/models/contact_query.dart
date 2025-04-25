class ContactQuery {
  final int id;
  final String name;
  final String email;
  final String contact;
  final String query;
  final bool resolved;
  final String? response;
  final String? resolvedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContactQuery({
    required this.id,
    required this.name,
    required this.email,
    required this.contact,
    required this.query,
    required this.resolved,
    this.response,
    this.resolvedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContactQuery.fromJson(Map<String, dynamic> json) {
    return ContactQuery(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      contact: json['contact'],
      query: json['query'],
      resolved: json['resolved'],
      response: json['response'],
      resolvedBy: json['resolvedBy'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'contact': contact,
      'query': query,
      'resolved': resolved,
      'response': response,
      'resolvedBy': resolvedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
