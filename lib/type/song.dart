class Song {
  final String name;
  final int id;
  final String author;
  String? url;
  String? poster;
  String? lyric;

  Song(this.name, this.id, this.author, this.poster, {this.url, this.lyric});


  Map toJson() {
    // print(url);
    Map map = {};
    map["name"] = name;
    map["author"] = author;
    map["id"] = id;
    map["poster"] = poster;
    if (url != null && !url!.startsWith("http")) {
      map["url"] = url;
    }
    return map;
  }
}