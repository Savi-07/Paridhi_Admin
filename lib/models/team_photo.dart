import 'package:flutter/foundation.dart';

class TeamPhoto {
  final int id;
  final String category;
  final ImageDetails imageDetails;
  final String createdAt;
  final String updatedAt;
  final String createdBy;
  final String updatedBy;

  TeamPhoto({
    required this.id,
    required this.category,
    required this.imageDetails,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  factory TeamPhoto.fromJson(Map<String, dynamic> json) {
    return TeamPhoto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? '',
      imageDetails: ImageDetails.fromJson(
        json['imageDetails'] as Map<String, dynamic>? ?? {},
      ),
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? '',
      updatedBy: json['updatedBy'] as String? ?? '',
    );
  }

  String get secureUrl => imageDetails.secureUrl;
  String get publicId => imageDetails.publicId;
}

class ImageDetails {
  final String publicId;
  final String secureUrl;

  ImageDetails({
    required this.publicId,
    required this.secureUrl,
  });

  factory ImageDetails.fromJson(Map<String, dynamic> json) {
    return ImageDetails(
      publicId: json['publicId'] as String? ?? '',
      secureUrl: json['secureUrl'] as String? ?? '',
    );
  }
}

enum TeamCategory {
  MEGATRONS('MEGATRONS'),
  DEVELOPERS('DEVELOPERS');

  final String name;
  const TeamCategory(this.name);

  String get displayName {
    switch (this) {
      case TeamCategory.MEGATRONS:
        return 'Megatrons';
      case TeamCategory.DEVELOPERS:
        return 'Developers';
    }
  }

  static TeamCategory? fromName(String name) {
    try {
      return TeamCategory.values
          .firstWhere((category) => category.name == name);
    } catch (e) {
      return null;
    }
  }
}
