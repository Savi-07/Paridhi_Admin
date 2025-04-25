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

class Event {
  
  final int id;
  final String domain;
  final String name;
  final String eventType;
  final DateTime eventDate;
  final String description;
  final String venue;
  final List<String> coordinatorDetails;
  final ImageDetails? imageDetails;
  final String ruleBook;
  final int minPlayers;
  final int maxPlayers;
  final double registrationFee;
  final double? prizePool;
  final bool registrationOpen;

  Event({
    required this.id,
    required this.domain,
    required this.name,
    required this.eventType,
    required this.eventDate,
    required this.description,
    required this.venue,
    required this.coordinatorDetails,
    this.imageDetails,
    required this.ruleBook,
    required this.minPlayers,
    required this.maxPlayers,
    required this.registrationFee,
    this.prizePool,
    required this.registrationOpen,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? 0,
      domain: json['domain'] ?? '',
      name: json['name'] ?? '',
      eventType: json['eventType'] ?? '',
      eventDate:
          DateTime.parse(json['eventDate'] ?? DateTime.now().toIso8601String()),
      description: json['description'] ?? '',
      venue: json['venue'] ?? '',
      coordinatorDetails: List<String>.from(json['coordinatorDetails'] ?? []),
      imageDetails: json['imageDetails'] != null
          ? ImageDetails.fromJson(json['imageDetails'])
          : null,
      ruleBook: json['ruleBook'] ?? '',
      minPlayers: json['minPlayers'] ?? 1,
      maxPlayers: json['maxPlayers'] ?? 1,
      registrationFee: (json['registrationFee'] ?? 0).toDouble(),
      prizePool: json['prizePool'] != null ? (json['prizePool'] as num).toDouble() : null,
      registrationOpen: json['registrationOpen'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'domain': domain,
      'name': name,
      'eventType': eventType,
      'eventDate': eventDate.toIso8601String(),
      'description': description,
      'venue': venue,
      'coordinatorDetails': coordinatorDetails,
      'ruleBook': ruleBook,
      'minPlayers': minPlayers,
      'maxPlayers': maxPlayers,
      'registrationFee': registrationFee,
      'registrationOpen': registrationOpen,
    };
    
    // Only include these fields if they're not null
    if (imageDetails != null) {
      data['imageDetails'] = imageDetails!.toJson();
    }
    
    if (prizePool != null) {
      data['prizePool'] = prizePool;
    }
    
    return data;
  }
}
