enum Designation {
  MEGATRON,
  MEMBER,
  APP_DEVELOPER,
  FRONTEND_DEVELOPER,
  BACKEND_DEVELOPER,
  FULL_STACK_DEVELOPER,
  BACKEND_DEVELOPER_AND_APP_DEVELOPER,
  BARA_BHATARI
}

class SocialLinks {
  final String linkedInLink;
  final String instagramLink;
  final String githubLink;
  final String facebookLink;

  SocialLinks({
    this.linkedInLink = '',
    this.instagramLink = '',
    this.githubLink = '',
    this.facebookLink = '',
  });

  bool get hasAnyLinks =>
      linkedInLink.isNotEmpty ||
      instagramLink.isNotEmpty ||
      githubLink.isNotEmpty ||
      facebookLink.isNotEmpty;

  factory SocialLinks.fromJson(Map<String, dynamic> json) {
    return SocialLinks(
      linkedInLink: json['linkedInLink'] ?? '',
      instagramLink: json['instagramLink'] ?? '',
      githubLink: json['githubLink'] ?? '',
      facebookLink: json['facebookLink'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'linkedInLink': linkedInLink,
      'instagramLink': instagramLink,
      'githubLink': githubLink,
      'facebookLink': facebookLink,
    };
  }
}

class TeamMember {
  final int? id;
  final String name;
  final String email;
  final String year;
  final SocialLinks socialLinks;
  final String? imageLink;
  final Designation designation;
  final String? createdAt;
  final String? updatedAt;

  TeamMember({
    this.id,
    required this.name,
    required this.email,
    required this.year,
    required this.socialLinks,
    this.imageLink,
    required this.designation,
    this.createdAt,
    this.updatedAt,
  });

  String? get formattedImageLink {
    if (imageLink == null || imageLink!.isEmpty) return null;

    // Check if it's a Google Drive link
    if (imageLink!.contains('drive.google.com')) {
      // Extract file ID from the link
      final regex = RegExp(r'/d/(.*?)(/|$)');
      final match = regex.firstMatch(imageLink!);
      if (match != null && match.groupCount >= 1) {
        final fileId = match.group(1);
        return 'https://drive.google.com/uc?export=view&id=$fileId';
      }
    }

    return imageLink;
  }

  String get formattedDesignation {
    // Special case for BACKEND_DEVELOPER_AND_APP_DEVELOPER
    if (designation == Designation.BACKEND_DEVELOPER_AND_APP_DEVELOPER) {
      return 'BACKEND & APP DEV';
    }
    
    // Default formatting for other designations
    return designation.toString().split('.').last.replaceAll('_', ' ');
  }

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    print('Parsing TeamMember from JSON: $json');

    // Parse designation with better error handling
    Designation parsedDesignation;
    try {
      String designationStr = json['designation'] ?? 'MEMBER';
      print('Attempting to parse designation: $designationStr');

      // Special case for "Backend Dev & App Dev"
      if (designationStr == 'Backend Dev & App Dev') {
        parsedDesignation = Designation.BACKEND_DEVELOPER_AND_APP_DEVELOPER;
      } else {
        // Make the designation comparison case-insensitive
        parsedDesignation = Designation.values.firstWhere(
          (e) => e.toString().split('.').last.toUpperCase() == designationStr.toUpperCase().replaceAll(' ', '_'),
          orElse: () {
            print(
                'Warning: Could not parse designation: $designationStr, defaulting to MEMBER');
            return Designation.MEMBER;
          },
        );
      }
      print('Successfully parsed designation: $designationStr');
    } catch (e) {
      print('Error parsing designation: ${json['designation']}, error: $e');
      parsedDesignation = Designation.MEMBER;
    }

    return TeamMember(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      year: json['year'],
      socialLinks: json['socialLinks'] != null
          ? SocialLinks.fromJson(json['socialLinks'])
          : SocialLinks(
              linkedInLink: json['linkedInLink'] ?? '',
              instagramLink: json['instagramLink'] ?? '',
              githubLink: json['githubLink'] ?? '',
              facebookLink: json['facebookLink'] ?? '',
            ),
      imageLink: json['imageLink'],
      designation: parsedDesignation,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'year': year,
      'linkedInLink': socialLinks.linkedInLink,
      'facebookLink': socialLinks.facebookLink,
      'instagramLink': socialLinks.instagramLink,
      'githubLink': socialLinks.githubLink,
      'imageLink': imageLink,
      'designation': designation == Designation.BACKEND_DEVELOPER_AND_APP_DEVELOPER 
          ? 'Backend Dev & App Dev' 
          : designation.toString().split('.').last,
    };
  }

  // Helper method to create input format for adding a new member
  Map<String, dynamic> toAddJson() {
    return {
      'name': name,
      'email': email,
      'year': year,
      'linkedInLink': socialLinks.linkedInLink,
      'facebookLink': socialLinks.facebookLink,
      'instagramLink': socialLinks.instagramLink,
      'githubLink': socialLinks.githubLink,
      'imageLink': imageLink,
      'designation': designation == Designation.BACKEND_DEVELOPER_AND_APP_DEVELOPER 
          ? 'Backend Dev & App Dev' 
          : designation.toString().split('.').last,
    };
  }
}

class TeamResponse {
  final List<TeamMember> content;

  TeamResponse({
    required this.content,
  });

  factory TeamResponse.fromJson(dynamic json) {
    print('Parsing TeamResponse from JSON: $json');

    List<TeamMember> allMembers = [];

    // Handle empty response
    if (json == null ||
        (json is List && json.isEmpty) ||
        (json is Map && json.isEmpty)) {
      print('Empty response received');
      return TeamResponse(
        content: [],
      );
    }

    // Handle map response
    if (json is Map<String, dynamic>) {
      // Parse members array
      if (json['members'] != null && json['members'] is List) {
        for (var memberJson in json['members']) {
          try {
            allMembers.add(TeamMember.fromJson(memberJson));
          } catch (e) {
            print('Error parsing member: $e');
            print('Member JSON: $memberJson');
          }
        }
      }

      // Parse developers array
      if (json['developers'] != null && json['developers'] is List) {
        for (var developerJson in json['developers']) {
          try {
            allMembers.add(TeamMember.fromJson(developerJson));
          } catch (e) {
            print('Error parsing developer: $e');
            print('Developer JSON: $developerJson');
          }
        }
      }
    }

    print('Found ${allMembers.length} total members in response');

    return TeamResponse(
      content: allMembers,
    );
  }
}
