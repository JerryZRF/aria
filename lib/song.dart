class Song {
  final String name;
  final int id;
  final String author;
  late String url;

  Song(this.name, this.id, this.author);
  @override
  bool operator ==(other) {
    if (other is! Song) {
      return false;
    }
    final Song song = other;
    return id == song.id;
  }

  @override
  int get hashCode => id;
}
