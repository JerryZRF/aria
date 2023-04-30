import 'dart:io';

import 'package:aria/type/project.dart';
import 'package:aria/ui/colors.dart';
import 'package:aria/ui/home.dart';
import 'package:aria/ui/projects.dart';
import 'package:aria/utils.dart';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;

GlobalKey<NavigatorState> nk = GlobalKey();
GlobalKey<HomePageState> homeKey = GlobalKey();

List<Project> projects = [];
int nowProject = -1;

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
    windowManager.setMinimumSize(const Size(640, 420));
    await windowManager.center();
    await windowManager.show();
    await windowManager.setPreventClose(true);
    await windowManager.setSkipTaskbar(false);
  });
  load();
  runApp(FluentApp(
    navigatorKey: nk,
    home: const ProjectsPage(),
    theme: FluentThemeData(
      navigationPaneTheme: const NavigationPaneThemeData(backgroundColor:  Color(0xfff2ecde)),
        dialogTheme: const ContentDialogThemeData(
            titleStyle: TextStyle(fontWeight: FontWeight.w100, color: Colors.black, fontSize: 34, fontFamily: "HYWenHei",)),
        fontFamily: "HYWenHei",
        scaffoldBackgroundColor: background),
  ));
}
