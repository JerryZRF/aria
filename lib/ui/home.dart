import 'dart:convert';
import 'dart:io';

import 'package:aria/ui/player.dart';
import 'package:aria/ui/library.dart';
import 'package:aria/ui/projects.dart';
import 'package:aria/ui/songs.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:get/get.dart';
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
  int editing = -1;

  @override
  Widget build(BuildContext context) {
    windowManager.show();
    return NavigationView(
      appBar: NavigationAppBar(
        title: DragToMoveArea(
            child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            "Aria  -  ${projects[nowProject].name}",
            style: const TextStyle(fontSize: 18),
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
            nowProject = -1;
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
      paneBodyBuilder: (item, body) {
        if (index == 0) {
          return editing == -1
              ? const SongList()
              : EditorPage(song: projects[nowProject].songs[editing]);
        } else {
          return body!;
        }
      },
      pane: NavigationPane(
        displayMode: PaneDisplayMode.compact,
        items: [
          PaneItem(
              icon: const Icon(material.Icons.playlist_play),
              title: const Text("已选歌曲"),
              body: const SongList()),
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

void generate(BuildContext homeContext) async {
  bool ok = true;
  if (projects[nowProject].songs.isEmpty) {
    return;
  }
  cacheDir.createSync();
  late BuildContext dialogContext;
  showDialog(
      context: homeContext,
      builder: (context) {
        dialogContext = context;
        return ContentDialog(
          title: const Text("合成中！"),
          content: Row(
            children: const <Widget>[
              Text("正在准备资源，很快就好啦"),
              Expanded(child: SizedBox()),
              ProgressRing(),
            ],
          ),
        );
      });
  File listFile = File("${cacheDir.path}/list.txt");
  if (listFile.existsSync()) {
    await listFile.delete();
  }
  //写入list.txt
  for (Song song in projects[nowProject].songs) {
    if (song.url == null || song.url!.startsWith("http")) {
      //在线歌曲
      await listFile.writeAsString("file '${song.id}.mp3'\n",
          mode: FileMode.append);
      await netease.getSongInfo(song.id).then((value) {
        Map<String, dynamic> map = json.decode(value.body);
        // print(map);
        song.url = map["data"][0]["url"];
      });
    } else {
      //本地歌曲
      await listFile.writeAsString("file '${song.url}'\n",
          mode: FileMode.append);
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
  Navigator.pop(dialogContext);
  for (var song in projects[nowProject].songs) {
    // print(song.toJson());
    if (song.url != null && !song.url!.startsWith("http")) {
      continue;
    }
    try {
      if (File("${cacheDir.path}/${song.id}.mp3").existsSync()) {
        continue;
      }
      // print("${cacheDir.path}/${song.id}.mp3");
      ValueNotifier<double> progress = ValueNotifier(0);
      showDialog(
          context: homeContext,
          builder: (context) {
            dialogContext = context;
            return ContentDialog(
              title: const Text("合成中"),
              content: Text("正在下载《${song.name}》"),
              actions: [
                ValueListenableBuilder<double>(
                  builder: (c, v, w) {
                    return ProgressBar(
                      value: progress.value,
                    );
                  },
                  valueListenable: progress,
                )
              ],
            );
          });
      await dio
          .downloadUri(Uri.parse(song.url!), "${cacheDir.path}/${song.id}.mp3",
              onReceiveProgress: (int count, int total) {
        progress.value = count / total * 100;
      });
      Navigator.pop(dialogContext);
    } catch (e) {
      Navigator.maybePop(dialogContext);
      showDialog(
          context: homeContext,
          builder: (context) {
            return ContentDialog(
              title: const Text("出错啦！"),
              content: Text("下载《${song.name}》时出现错误：\n$e\n点击空白处关闭"),
            );
          },
          barrierDismissible: true);
      // pd.update(
      //   message: "下载《${song.name}》时发生错误：\n$e\n点击空白处关闭",
      //   progress: 0,
      //   isDismissible: true,
      // );
      e.printInfo();
      e.printError();
      return;
    }
  }
  showDialog(
      context: homeContext,
      builder: (context) {
        dialogContext = context;
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
    File("${cacheDir.path}/list.txt").path,
    "-loglevel",
    "error",
    "-c",
    "copy",
    "./tmp.mp3"
  ]).then((value) async {
    if (value.exitCode != 0) {
      print(value.exitCode);
      print(value.stderr);
      Navigator.pop(dialogContext);
      await showDialog(
          context: homeContext,
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
  if (!ok) return;
  Navigator.pop(dialogContext);
  //询问是否平衡
  bool? result = await showDialog<bool>(
    context: homeContext,
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
        context: homeContext,
        builder: (context) {
          dialogContext = context;
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
        Navigator.pop(dialogContext);
        await showDialog(
            context: homeContext,
            builder: (context) => ContentDialog(
                  title: const Text(
                    "出错啦！",
                  ),
                  content: Text(value.stderr +
                      (value.exitCode == 1 ? "\ntip: 请关闭tmp.mp3文件" : "")),
                ),
            barrierDismissible: true);
        return;
      }
    });
  } else {
    try {
      await File("./tmp.mp3").rename("./${projects[nowProject].name}.mp3");
    } catch (e) {
      // Navigator.pop(dialogContext);
      // e.printError();
      await showDialog(
          context: homeContext,
          builder: (context) => ContentDialog(
                title: const Text(
                  "出错啦！",
                ),
                content: Text("$e\ntip: 请关闭${projects[nowProject].name}.mp3文件"),
              ),
          barrierDismissible: true);
      return;
    }
  }
  result = await showDialog<bool>(
      context: homeContext,
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
