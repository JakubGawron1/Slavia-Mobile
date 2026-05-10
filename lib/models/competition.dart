class Competition {
  final String id;
  final String title;
  final DateTime date;
  final String location;
  final String? description;
  final String? category;
  final String? status;

  Competition({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    this.description,
    this.category,
    this.status,
  });

  factory Competition.fromJson(Map<String, dynamic> json) {
    return Competition(
      id: json['id'],
      title: json['title'],
      date: DateTime.parse(json['date']),
      location: json['location'] ?? '',
      description: json['description'],
      category: json['category'],
      status: json['status'],
    );
  }
}
