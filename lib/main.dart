import 'dart:convert';
import 'dart:io';

import 'package:aria/type/project.dart';
import 'package:aria/type/song.dart';
import 'package:aria/ui/projects.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;

GlobalKey<NavigatorState> nk = GlobalKey();

List<Project> projects = [];
late int nowProject;

Directory cacheDir = Directory("./cache");

String? proxy;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await flutter_acrylic.Window.initialize();
  await flutter_acrylic.Window.hideWindowControls();
  await WindowManager.instance.ensureInitialized();
  windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await windowManager.setClosable(true);
    await windowManager.setSize(const Size(640, 420));
    // await windowManager.setSize(const Size(1280, 768));
    await windowManager.center();
    await windowManager.show();
    await windowManager.setPreventClose(true);
    await windowManager.setSkipTaskbar(false);
  });
  Map<String, dynamic> config =
      jsonDecode(File("./config.json").readAsStringSync());
  projects.clear();
  (config["projects"] as List).cast().forEach((project) {
    List<Song> songs = [];
    for (var song in (project["songs"] as List)) {
      songs.add(Song(song["name"], song["id"], song["author"]));
      songs.last.url = song["url"];
    }
    projects.add(Project(project["name"], project["date"], songs));
  });

  runApp(FluentApp(
    navigatorKey: nk,
    home: const ProjectsPage(),
    theme: FluentThemeData(
        dialogTheme: const ContentDialogThemeData(
            titleStyle: TextStyle(fontWeight: FontWeight.w100, color: Colors.black, fontSize: 34, fontFamily: "HYWenHei",)),
        fontFamily: "HYWenHei",
        scaffoldBackgroundColor: Colors.grey[100]),
  ));
}
