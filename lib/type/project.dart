
import 'package:aria/type/song.dart';

class Project {
  String name;
  int date;
  List<Song> songs;

  Project(this.name, this.date, this.songs);

  Map toJson() {
    Map map = {};
    map["name"] = name;
    map["date"] = date;
    map["songs"] = songs;
    return map;
  }

  @override
  bool operator ==(other) {
    if (other is! Project) {
      return false;
    }
    final Project project = other;
    return name == project.name;
  }
}
