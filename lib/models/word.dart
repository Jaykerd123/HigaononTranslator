class Word {
  final String higaonon;
  final String tagalog;
  final String partOfSpeech;
  final String english;
  final String exampleHigaonon;
  final String exampleEnglish;

  Word({
    required this.higaonon,
    required this.tagalog,
    required this.partOfSpeech,
    required this.english,
    required this.exampleHigaonon,
    required this.exampleEnglish,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      higaonon: json['higaonon'],
      tagalog: json['tagalog'],
      partOfSpeech: json['part_of_speech'],
      english: json['english'],
      exampleHigaonon: json['example_higaonon'],
      exampleEnglish: json['example_english'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'higaonon': higaonon,
      'tagalog': tagalog,
      'part_of_speech': partOfSpeech,
      'english': english,
      'example_higaonon': exampleHigaonon,
      'example_english': exampleEnglish,
    };
  }
}

