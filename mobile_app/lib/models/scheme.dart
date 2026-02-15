class Scheme {
  final String title;
  final String description;
  final String benefits;
  final String? onlineLink;
  final String offlineInfo;

  Scheme({
    required this.title,
    required this.description,
    required this.benefits,
    this.onlineLink,
    required this.offlineInfo,
  });

  factory Scheme.fromJson(Map<String, dynamic> json) {
    return Scheme(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      benefits: json['benefits'] ?? '',
      onlineLink: json['onlineLink'],
      offlineInfo: json['offlineInfo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'benefits': benefits,
      'onlineLink': onlineLink,
      'offlineInfo': offlineInfo,
    };
  }
}
