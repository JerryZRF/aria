import 'dart:io';

import 'package:aria/ui/home.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:window_manager/window_manager.dart';

import '../main.dart';
import '../type/project.dart';
import '../utils.dart';
import 'colors.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({Key? key}) : super(key: key);

  @override
  _ProjectsPageState createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  @override
  void initState() {
    super.initState();
    windowManager.show();
  }

  @override
  Widget build(BuildContext context) {
    return material.Scaffold(
      backgroundColor: background,
      appBar: material.PreferredSize(
        preferredSize: const material.Size(640, 80),
        child: DragToMoveArea(
          child: PageHeader(
              title: Container(
                padding: const EdgeInsets.only(left: 10, top: 10),
                child: Text(
                  "项目列表",
                  style: TextStyle(
                      fontSize: 38,
                      color: title,
                      fontFamily: "HYWenHei",
                      fontWeight: FontWeight.w100),
                ),
              ),
              commandBar: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                  child: GestureDetector(
                    child: const Icon(
                      material.Icons.minimize,
                      size: 24,
                    ),
                    onTap: () {
                      windowManager.minimize();
                    },
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: GestureDetector(
                    child: const Icon(
                      material.Icons.close,
                      size: 24,
                    ),
                    onTap: () {
                      saveDialog(context);
                      exit(0);
                    },
                  ),
                ),
              ])),
        ),
      ),
      body: ListView(
        children: projects
            .map((p) => GestureDetector(
                  child: Container(
                    height: 40,
                    width: double.infinity,
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0), color: item),
                    child: ListTile(
                        title: Text(
                            "${p.name}  -  ${DateTime.fromMillisecondsSinceEpoch(p.date).toLocal().toString().split(".")[0]}")),
                  ),
                  onDoubleTap: () async {
                    await windowManager.hide();
                    sleep(const Duration(milliseconds: 100));
                    windowManager.setMinimumSize(const Size(1280, 768));
                    await windowManager.setSize(const Size(1280, 768));
                    await windowManager.center();

                    nowProject = projects.indexOf(p);
                    Navigator.of(context).pushAndRemoveUntil(
                        PageRouteBuilder(
                            pageBuilder: (context, i, g) =>
                                HomePage(key: homeKey)),
                        (route) => false);
                  },
                  onSecondaryLongPress: () {
                    getName(context).then((name) {
                      if (name == null) {
                        return;
                      }
                      p.name = name;
                      setState(() {});
                    });
                  },
                  onSecondaryTap: () async {
                    bool? result = await showDialog<bool>(
                        context: context,
                        builder: (context) => ContentDialog(
                              title: const Text("删除项目"),
                              content: const Text("确定要删除吗？\n数据无价，三思而后行"),
                              actions: [
                                FilledButton(
                                    child: const Text("狠心删除"),
                                    onPressed: () =>
                                        Navigator.pop(context, true)),
                                Button(
                                    child: const Text("算了吧"),
                                    onPressed: () =>
                                        Navigator.pop(context, false))
                              ],
                            ));

                    if (result!) {
                      projects.remove(p);
                      setState(() {});
                    }
                  },
                ))
            .toList(),
      ),
      floatingActionButton: material.FloatingActionButton(
          backgroundColor: button,
          onPressed: () async {
            getName(context).then((name) {
              if (name == null) {
                return;
              }
              projects.add(
                  Project(name, (DateTime.now().millisecondsSinceEpoch), []));
              save();
              setState(() {});
            });
          },
          child: const Icon(FluentIcons.new_team_project)),
    );
  }
}

Future<String?> getName(BuildContext context) async {
  String? name = await showDialog<String>(
      context: context,
      builder: (context) => ContentDialog(
            title: const Text("项目命名"),
            content: InfoLabel(
              label: '请输入项目名:',
              child: TextBox(
                  placeholder: '项目名',
                  expands: false,
                  onSubmitted: (name) {
                    Navigator.pop(context, name);
                  }),
            ),
          ),
      barrierDismissible: true);
  if (name == null || name == "") {
    return null;
  }
  Project existedProject = projects.firstWhere((p) => p.name == name,
      orElse: () => Project("", 0, []));
  if (existedProject != Project("", 0, [])) {
    showDialog(
        context: context,
        builder: (context) => ContentDialog(
              title: const Text("出错了！"),
              content: Text(
                  "这里似乎已经有一个叫做\"$name\"的项目了呢，它上次被修改是在${DateTime.fromMillisecondsSinceEpoch(existedProject.date)}"),
            ),
        barrierDismissible: true);
    return null;
  }
  return name;
}
