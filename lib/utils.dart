import 'dart:convert';
import 'dart:io';

import 'package:aria/type/project.dart';
import 'package:aria/type/song.dart';
import 'package:fluent_ui/fluent_ui.dart';

import 'main.dart';

String format(String source) {
  return source.replaceAll(",", ", ").replaceAll(":", ": ");
}

Future saveDialog(BuildContext context) async {
  bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
            title: const Text("保存"),
            content: const Text("数据无价，谨慎操作~"),
            actions: [
              FilledButton(
                  child: const Text("保存"),
                  onPressed: () => Navigator.pop(context, true)),
              Button(
                  child: const Text("不保存"),
                  onPressed: () => Navigator.pop(context, false))
            ],
          ));
  if (result!) {
    await save();
  } else {
    load();
  }
}

Future save() async {
  if (nowProject != -1) {
    projects[nowProject].date = DateTime.now().millisecondsSinceEpoch;
  }
  File file = File("./config.json");
  await file.writeAsString(jsonEncode({"projects": projects}));
}

void load() {
  if (File("./config.json").existsSync()) {
    Map<String, dynamic> config =
    jsonDecode(File("./config.json").readAsStringSync());
    projects.clear();
    (config["projects"] as List).cast().forEach((project) {
      List<Song> songs = [];
      for (var song in (project["songs"] as List)) {
        songs.add(Song(song["name"], song["id"], song["author"], song["poster"]));
        songs.last.url = song["url"];
      }
      projects.add(Project(project["name"], project["date"], songs));
    });
  }
}