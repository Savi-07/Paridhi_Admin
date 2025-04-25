import 'event_model.dart';

class ImageDetails {
  final String publicId;
  final String secureUrl;

  ImageDetails({
    required this.publicId,
    required this.secureUrl,
  });

  factory ImageDetails.fromJson(Map<String, dynamic> json) {
    return ImageDetails(
      publicId: json['public_id'] ?? '',
      secureUrl: json['secure_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'public_id': publicId,
      'secure_url': secureUrl,
    };
  }
}

class ComboEvent {
  final ImageDetails? imageDetails;
  final int id;
  final String name;
  final String description;
  final String domain;
  final List<Event> events;
  final double registrationFee;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdByUsername;
  final bool registrationOpen;

  ComboEvent({
    this.imageDetails,
    required this.id,
    required this.name,
    required this.description,
    required this.domain,
    required this.events,
    required this.registrationFee,
    required this.createdAt,
    required this.updatedAt,
    required this.createdByUsername,
    required this.registrationOpen,
  });

  factory ComboEvent.fromJson(Map<String, dynamic> json) {
    return ComboEvent(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      domain: json['domain'] ?? '',
      events: (json['events'] as List<dynamic>)
          .map((event) => Event.fromJson(event))
          .toList(),
      imageDetails: json['imageDetails'] != null
          ? ImageDetails.fromJson(json['imageDetails'])
          : null,
      registrationFee: (json['registrationFee'] ?? 0).toDouble(),
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      createdByUsername: json['createdByUsername'] ?? '',
      registrationOpen: json['registrationOpen'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageDetails': imageDetails?.toJson(),
      'name': name,
      'description': description,
      'domain': domain,
      'eventIds': events.map((event) => event.id).toList(),
      'registrationFee': registrationFee,
      'registrationOpen': registrationOpen,
    };
  }
}
