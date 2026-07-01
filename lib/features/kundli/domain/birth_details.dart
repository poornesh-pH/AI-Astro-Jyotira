import 'dart:convert';
import 'package:timezone/timezone.dart' as tz;
 
/// Immutable birth input. Place resolves to lat/lng + IANA tz id (offline
/// city dataset). [toUtc] converts the entered local birth time to UTC so the
/// ephemeris engine receives correct universal time — wrong tz => wrong lagna.
class BirthDetails {
  final String name;
  final String gender; // 'male' | 'female' | 'other'
  final DateTime date; // local Y/M/D
  final int hour; // local 0..23
  final int minute; // local 0..59
  final String placeName;
  final double lat;
  final double lng;
  final String tzId; // IANA, e.g. Asia/Kolkata
 
  const BirthDetails({
    required this.name,
    required this.gender,
    required this.date,
    required this.hour,
    required this.minute,
    required this.placeName,
    required this.lat,
    required this.lng,
    required this.tzId,
  });
 
  DateTime toUtc() {
    final loc = tz.getLocation(tzId);
    final local = tz.TZDateTime(
      loc,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
    return local.toUtc();
  }
 
  Map<String, dynamic> toJson() => {
        'name': name,
        'gender': gender,
        'date': date.toIso8601String(),
        'hour': hour,
        'minute': minute,
        'placeName': placeName,
        'lat': lat,
        'lng': lng,
        'tzId': tzId,
      };
 
  factory BirthDetails.fromJson(Map<String, dynamic> j) => BirthDetails(
        name: j['name'] as String,
        gender: j['gender'] as String,
        date: DateTime.parse(j['date'] as String),
        hour: j['hour'] as int,
        minute: j['minute'] as int,
        placeName: j['placeName'] as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        tzId: j['tzId'] as String,
      );
 
  String encode() => jsonEncode(toJson());
  static BirthDetails decode(String s) =>
      BirthDetails.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
 
/// One city record from the bundled offline dataset.
class City {
  final String name;
  final String state;
  final double lat;
  final double lng;
  final String tzId;
  const City(this.name, this.state, this.lat, this.lng, this.tzId);
 
  String get label => '$name, $state';
 
  factory City.fromJson(Map<String, dynamic> j) => City(
        j['name'] as String,
        j['state'] as String,
        (j['lat'] as num).toDouble(),
        (j['lng'] as num).toDouble(),
        j['tz'] as String,
      );
}
