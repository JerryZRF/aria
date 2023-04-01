import 'dart:convert';
import 'dart:io';

import 'package:aria/ui/library.dart';
import 'package:aria/ui/projects.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:file_selector/file_selector.dart';
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
                floatingActionButton: Stack(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 70),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: material.FloatingActionButton(
                          heroTag: "btn1",
                          onPressed: () => generate(context),
                          child: const Icon(material.Icons.gavel_rounded),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: material.FloatingActionButton(
                        heroTag: "btn2",
                        onPressed: () async {
                          const XTypeGroup musicGroup = XTypeGroup(
                            label: "音频文件",
                            extensions: <String>["mp3", "wma", "wav", "aac"],
                          );
                          final List<XFile> files = await openFiles(
                              acceptedTypeGroups: [musicGroup, XTypeGroup()]);
                          if (files.isEmpty) {
                            return;
                          }
                          bool? result = await showDialog<bool>(
                            context: context,
                            builder: (context) => ContentDialog(
                              title: Text("导入本地文件"),
                              content:
                                  Text("是否复制一份文件？\n可以防止源文件丢失或环境迁移，但会多占用一份空间"),
                              actions: [
                                Button(
                                    child: Text("否"),
                                    onPressed: () =>
                                        Navigator.pop(context, false)),
                                FilledButton(
                                    child: Text("是"),
                                    onPressed: () =>
                                        Navigator.pop(context, true))
                              ],
                            ),
                          );
                          if (result!) {
                            for (XFile f in files) {
                              File file = File(f.path);
                              String md = md5
                                  .convert(file.readAsBytesSync())
                                  .toString();
                              if (!File(
                                      "${cacheDir.path}/${md}.${f.name.split(".").last}")
                                  .existsSync()) {
                                await file.copy(
                                    "${cacheDir.path}/${md}.${f.name.split(".").last}");
                              }
                              projects[nowProject]
                                  .songs
                                  .add(Song(f.name, 0, "Unknown", url: "${md}.${f.name.split(".").last}"));
                              // save();
                            }
                            setState(() {});
                          } else {
                            for (XFile f in files) {
                              projects[nowProject]
                                  .songs
                                  .add(Song(f.name, 0, "Unknown", url: f.path));
                              print(f.path);
                            }
                            setState(() {});
                          }
                        },
                        child: const Icon(
                            material.Icons.insert_drive_file_outlined),
                      ),
                    ),
                  ],
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
    message: "正在加载...",
    maxProgress: 100.0,
    messageTextStyle: const TextStyle(fontFamily: "HYWenHei", fontSize: 18),
  );
  await pd.show();
  File listFile = File("${cacheDir.path}/list.txt");
  if (listFile.existsSync()) {
    await listFile.delete();
  }
  for (Song song in projects[nowProject].songs) {
    await listFile.writeAsString(
        "file '${song.url == null || song.url!.startsWith("http") ? "${song.id}.mp3" : song.url} '\n",
        mode: FileMode.append);
    if (song.url == null || song.url!.startsWith("http")) {
      await netease.getSongInfo(song.id).then((value) {
        Map<String, dynamic> map = json.decode(value.body);
        song.url = map["data"][0]["url"];
      });
    }
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
  for (var song in projects[nowProject].songs) {
    print(song.toJson());
    if (!song.url!.startsWith("http")) {
      continue;
    }
    try {
      if (File("${cacheDir.path}/${song.id}.mp3").existsSync()) {
        pd.update(progress: 100, message: "下载完成", isDismissible: true);
        continue;
      }
      print("${cacheDir.path}/${song.id}.mp3");
      await dio
          .downloadUri(Uri.parse(song.url!), "${cacheDir.path}/${song.id}.mp3",
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
      e.printError();
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
      ),
      content: const Text(
        "FFmpeg对音量标准化的处理功能。\n即削峰填谷，使整个音频的音量变得平滑。\n*不建议使用。\n音频来自网易云音乐，理论上已平衡，使用本功能可能使失去响度变化。\n该功能耗时较长。",
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
