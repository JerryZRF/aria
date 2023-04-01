import 'dart:io';

import 'package:aria/ui/home.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:window_manager/window_manager.dart';

import '../main.dart';
import '../type/project.dart';
import '../utils.dart';

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
      backgroundColor: Colors.grey[100],
      appBar: material.PreferredSize(
        preferredSize: const material.Size(640, 80),
        child: DragToMoveArea(
          child: PageHeader(
            padding: 20,
            title: Text(
              "项目列表",
              style: TextStyle(
                  fontSize: 34,
                  color: Colors.blue.lightest,
                  fontFamily: "HYWenHei",
                  fontWeight: FontWeight.w100),
            ),
            commandBar: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
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
          ),
        ),
      ),
      body: ListView(
        children: projects
            .map((e) => GestureDetector(
                  child: Container(
                    height: 40,
                    width: double.infinity,
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: Colors.grey[30]),
                    child: ListTile(title: Text(e.name)),
                  ),
                  onDoubleTap: () async {
                    await windowManager.hide();
                    sleep(const Duration(milliseconds: 100));
                    await windowManager.setSize(const Size(1280, 768));
                    await windowManager.center();

                    nowProject = projects.indexOf(e);
                    Navigator.of(context).pushAndRemoveUntil(
                        PageRouteBuilder(
                            pageBuilder: (context, i, g) => const HomePage()),
                        (route) => false);
                  },
                ))
            .toList(),
      ),
      floatingActionButton: material.FloatingActionButton(
        child: const Icon(FluentIcons.new_team_project),
        onPressed: () async {
          String? name = await showDialog<String>(
              context: context,
              builder: (context) => ContentDialog(
                    title: const Text("新建项目"),
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
            return;
          }
          Project existedProject = projects.firstWhere((p) => p.name == name, orElse: () => Project("", 0, []));
          if (existedProject != Project("", 0, [])) {
            showDialog(
                context: context,
                builder: (context) => ContentDialog(
                      title: const Text("出错了！"),
                      content: Text("这里似乎已经有一个叫做\"$name\"的项目了呢，它在${DateTime.fromMillisecondsSinceEpoch(existedProject.date)}被创建"),
                    ),
                barrierDismissible: true);
            return;
          }
          setState(() {
            projects.add(Project(
                name, (DateTime.now().millisecondsSinceEpoch), []));
            save();
          });
        },
      ),
    );
  }
}
