class Hotel {
  final String id;
  final String name;
  final String city;
  final String country;
  final String thumbnail;

  Hotel({required this.id, required this.name, this.city = '', this.country = '', this.thumbnail = ''});

  factory Hotel.fromMap(Map<String, dynamic> m) {
    return Hotel(
      id: (m['id'] ?? m['hotelId'] ?? '').toString(),
      name: m['name'] ?? m['hotel_name'] ?? 'Unknown',
      city: m['city'] ?? m['address']?['city'] ?? '',
      country: m['country'] ?? '',
      thumbnail: (m['thumbnail'] ?? (m['images'] is List && (m['images'] as List).isNotEmpty ? m['images'][0] : '')) ?? '',
    );
  }
}
