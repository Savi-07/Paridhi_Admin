class DomainPoster {
  final int id;
  final String domainName;
  final PosterDetails posterDetails;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  DomainPoster({
    required this.id,
    required this.domainName,
    required this.posterDetails,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  factory DomainPoster.fromJson(Map<String, dynamic> json) {
    return DomainPoster(
      id: json['id'],
      domainName: json['domainName'],
      posterDetails: PosterDetails.fromJson(json['posterDetails']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
    );
  }
}

class PosterDetails {
  final String publicId;
  final String secureUrl;

  PosterDetails({
    required this.publicId,
    required this.secureUrl,
  });

  factory PosterDetails.fromJson(Map<String, dynamic> json) {
    return PosterDetails(
      publicId: json['publicId'],
      secureUrl: json['secureUrl'],
    );
  }
}

enum DomainType {
  CODING,
  ROBOTICS,
  CIVIL,
  GENERAL,
  GAMING,
  ELECTRICAL;

  String get displayName {
    return name;
  }
}
