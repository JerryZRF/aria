class Song {
  final String name;
  final int id;
  final String author;
  String? url;

  Song(this.name, this.id, this.author, {this.url});


  Map toJson() {
    print(url);
    Map map = {};
    map["name"] = name;
    map["author"] = author;
    map["id"] = id;
    if (url != null && !url!.startsWith("http")) {
      map["url"] = url;
    }
    return map;
  }
}