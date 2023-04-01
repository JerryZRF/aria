import 'dart:convert';
import 'dart:io';

import 'package:aria/ui/library.dart';
import 'package:aria/ui/projects.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:get/get.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:window_manager/window_manager.dart';

import '../netease.dart' as netease;
import '../main.dart';
import '../type/song.dart';
import '../utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    // SongListController controller = SongListController();
    // Get.put(controller);
    windowManager.show();
    return NavigationView(
      appBar: NavigationAppBar(
        title: const DragToMoveArea(
            child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            "Aria",
            style: TextStyle(fontSize: 18),
          ),
        )),
        height: 50,
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () async {
            await saveDialog(context);
            await windowManager.hide();
            sleep(const Duration(milliseconds: 50));
            await windowManager.setSize(const Size(640, 420));
            await windowManager.center();
            Navigator.of(context).pushAndRemoveUntil(
                PageRouteBuilder(
                    pageBuilder: (context, i, g) => const ProjectsPage()),
                (route) => false);
          },
        ),
        actions: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: GestureDetector(
            child: const Icon(
              material.Icons.close,
              size: 24,
            ),
            onTap: () async {
              await saveDialog(context);
              exit(0);
            },
          ),
        ),
      ),
      pane: NavigationPane(
        displayMode: PaneDisplayMode.compact,
        items: [
          PaneItem(
              icon: const Icon(material.Icons.playlist_play),
              title: const Text("已选歌曲"),
              body: material.Scaffold(
                backgroundColor: Colors.grey[110],
                floatingActionButton: material.FloatingActionButton(
                  child: const Icon(material.Icons.gavel_rounded),
                  onPressed: () async {
                    generate(context);
                  },
                ),
                body: ReorderableListView(
                  header: Container(
                    alignment: const Alignment(-0.96, 0),
                    height: 80,
                    child: Text(
                      '已选歌曲',
                      style: TextStyle(
                          fontSize: 30,
                          color: Colors.blue.lightest,
                          fontFamily: "HYWenHei"),
                    ),
                  ),
                  children: projects[nowProject].songs.map((song) {
                    return GestureDetector(
                      key: UniqueKey(),
                      child: Container(
                        height: 40,
                        width: double.infinity,
                        alignment: const Alignment(-0.97, 0),
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: Colors.grey[30]),
                        child: Text(
                          "${song.name}  -  ${song.author}",
                          style: const TextStyle(fontFamily: "HYWenHei"),
                        ),
                      ),
                      onDoubleTap: () {
                        //TODO Edit song
                      },
                      onSecondaryTap: () {
                        setState(() {
                          projects[nowProject].songs.remove(song);
                        });
                      },
                    );
                  }).toList(),
                  onReorder: (int oldIndex, int newIndex) {
                    setState(() {
                      //交换数据
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      var item = projects[nowProject].songs.removeAt(oldIndex);
                      projects[nowProject].songs.insert(newIndex, item);
                    });
                  },
                ),
              )),
          PaneItem(
            icon: const Icon(material.Icons.library_music),
            title: const Text("音乐库"),
            body: const ScaffoldPage(content: MusicLibrary()),
          ),
          // PaneItem(
          //     icon: const Icon(material.Icons.settings),
          //     body: SettingsPage()
          // ),
        ],
        selected: index,
        onChanged: (newIndex) {
          setState(() {
            index = newIndex;
          });
        },
      ),
    );
  }
}

void generate(BuildContext context) async {
  bool ok = true;
  if (projects[nowProject].songs.isEmpty) {
    return;
  }
  cacheDir.createSync();
  final ProgressDialog pd = ProgressDialog(context,
      type: ProgressDialogType.Download, isDismissible: true);
  pd.style(
    progress: 0.0,
    message: "正在连接...",
    maxProgress: 100.0,
    messageTextStyle: const TextStyle(fontFamily: "HYWenHei", fontSize: 18),
  );
  await pd.show();
  for (Song song in projects[nowProject].songs) {
    await netease.getSongInfo(song.id).then((value) {
      Map<String, dynamic> map = json.decode(value.body);
      song.url = map["data"][0]["url"];
    });
  }
  File listFile = File("${cacheDir.path}/list.txt");
  if (listFile.existsSync()) {
    listFile.delete();
  }
  for (var song in projects[nowProject].songs) {
    try {
      // params += "${song.id}.mp3|";
      await listFile.writeAsString("file '${song.id}.mp3'\n",
          mode: FileMode.append);
      if (File("${cacheDir.path}/${song.id}.mp3").existsSync()) {
        pd.update(progress: 100, message: "下载完成", isDismissible: true);
        continue;
      }
      Dio dio = Dio();
      if (proxy != null) {
        dio.httpClientAdapter = IOHttpClientAdapter(
          onHttpClientCreate: (client) {
            client.findProxy = (uri) {
              return 'PROXY $proxy';
            };
            return client;
          },
        );
      }
      print("${cacheDir.path}/${song.id}.mp3");
      await dio.downloadUri(Uri.parse(song.url), "${cacheDir.path}/${song.id}.mp3",
          onReceiveProgress: (int count, int total) {
        pd.update(
          progress: count / total * 100,
          message: "正在下载《${song.name}》",
          isDismissible: false,
        );
      }).then((value) => value.printInfo());
    } catch (e) {
      pd.update(
        message: "下载《${song.name}》时发生错误：\n$e\n点击空白处关闭",
        progress: 0,
        isDismissible: true,
      );
      e.printInfo();
      return;
    }
  }
  pd.hide();
  late BuildContext dialog;
  showDialog(
      context: context,
      builder: (context) {
        dialog = context;
        return const ContentDialog(
          title: Text(
            "正在合并音频",
            style: TextStyle(fontWeight: FontWeight.w100),
          ),
          content: ProgressRing(),
        );
      });
  //合并音频
  await Process.run("ffmpeg", [
    "-y",
    "-f",
    "concat",
    "-safe",
    "0",
    "-i",
    File("${cacheDir.path}/list.txt").absolute.path,
    "-loglevel",
    "error",
    "-c",
    "copy",
    "./tmp.mp3"
  ]).then((value) async {
    if (value.exitCode != 0) {
      print(value.exitCode);
      print(value.stderr);
      await showDialog(
          context: context,
          builder: (context) => ContentDialog(
                title: const Text(
                  "出错啦！",
                  style: TextStyle(fontWeight: FontWeight.w100),
                ),
                content: Text(value.stderr +
                    (value.exitCode == 1 ? "\ntip: 请关闭tmp.mp3文件" : "")),
              ),
          barrierDismissible: true);
      ok = false;
    }
  });
  Navigator.pop(dialog);
  if (!ok) return;
  //询问是否平衡
  bool? result = await showDialog<bool>(
    context: context,
    builder: (context) => ContentDialog(
      title: const Text(
        "平衡音量",
        style: TextStyle(fontWeight: FontWeight.w100),
      ),
      content: const Text(
        "FFmpeg对音量标准化的处理功能。\n即削峰填谷，使整个音频的音量变得平滑。\n*不建议使用。\n音频来自网易云音乐，理论上已平衡，使用本功能可能使失去响度变化。\n该功能耗时较长。",
        style: TextStyle(fontWeight: FontWeight.w100),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: ButtonStyle(elevation: ButtonState.all(12)),
          child: const Text("平衡"),
        ),
        Button(
          child: const Text('算了吧'),
          onPressed: () => Navigator.pop(context, false),
        ),
      ],
    ),
  );
  if (result!) {
    //显示平衡进度条
    showDialog(
        context: context,
        builder: (context) {
          dialog = context;
          return const ContentDialog(
            title: Text(
              "正在平衡音量",
              style: TextStyle(fontWeight: FontWeight.w100),
            ),
            content: ProgressRing(),
          );
        });
    await Process.run("ffmpeg", [
      "-i",
      "./tmp.mp3",
      "-filter:a",
      "loudnorm",
      "-loglevel",
      "error",
      "-y",
      "./${projects[nowProject].name}.mp3",
    ]).then((value) async {
      print(value.stderr);
      print(value.exitCode);
      if (value.exitCode != 0) {
        await showDialog(
            context: context,
            builder: (context) => ContentDialog(
                  title: const Text(
                    "出错啦！",
                    style: TextStyle(fontWeight: FontWeight.w100),
                  ),
                  content: Text(value.stderr +
                      (value.exitCode == 1 ? "\ntip: 请关闭tmp.mp3文件" : "")),
                ),
            barrierDismissible: true);
        ok = false;
      }
      Navigator.pop(dialog);
      File("./tmp.mp3").delete();
      if (!ok) return;
    });
  } else {
    File("./tmp.mp3").rename("./${projects[nowProject].name}.mp3");
  }
  result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
            title: const Text(
              "完成",
              style: TextStyle(fontWeight: FontWeight.w100),
            ),
            content: const Text("看上去没有出错呢"),
            actions: [
              FilledButton(
                  child: const Text("点我打开"),
                  onPressed: () => Navigator.pop(context, true)),
              Button(
                  child: const Text("关闭"),
                  onPressed: () => Navigator.pop(context, false))
            ],
          ));
  if (result!) {
    Process.run("explorer",
        ["/select,", File("${projects[nowProject].name}.mp3").absolute.path]);
  }
}