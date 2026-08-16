class SentenceMatch {
  final String english;
  final String higaonon;

  SentenceMatch({
    required this.english,
    required this.higaonon,
  });

  factory SentenceMatch.fromJson(Map<String, dynamic> json) {
    return SentenceMatch(
      english: json['example_english'] ?? '',
      higaonon: json['example_higaonon'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'example_english': english,
      'example_higaonon': higaonon,
    };
  }
}
