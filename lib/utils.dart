import 'dart:convert';
import 'dart:io';

import 'package:aria/type/project.dart';
import 'package:aria/type/song.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:aria/netease.dart' as netease;

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
  await file.writeAsString(jsonEncode({"projects": projects, "proxy": proxy}));
}

void load() {
  if (File("./config.json").existsSync()) {
    Map<String, dynamic> config =
        jsonDecode(File("./config.json").readAsStringSync());
    proxy = config["proxy"];
    projects.clear();
    (config["projects"] as List).cast().forEach((project) {
      List<Song> songs = [];
      for (var song in (project["songs"] as List)) {
        songs.add(
            Song(song["name"], song["id"], song["author"], song["poster"]));
        songs.last.url = song["url"];
      }
      projects.add(Project(project["name"], project["date"], songs));
    });
  }
}

Future<bool> initSong(Song song, BuildContext homeContext) async {
  late BuildContext dialogContext;
  showDialog(
      context: homeContext,
      builder: (context) {
        dialogContext = context;
        return ContentDialog(
          title: const Text("准备开始啦~"),
          content: Row(
            children: const <Widget>[
              Text("正在准备资源，很快就好啦~"),
              Expanded(child: SizedBox()),
              ProgressRing(),
            ],
          ),
        );
      });
  bool ok = true;
  await netease.getSongInfo(song.id).then((value) {
    Map<String, dynamic> map = json.decode(value.body);
    song.url = map["data"][0]["url"];
    if (song.url == null) {
      Navigator.pop(dialogContext);
      showDialog(
          context: homeContext,
          builder: (context) => ContentDialog(
                title: const Text("出错啦！"),
                content: Text("怎么会混进《${song.name}》这首付费歌曲呢?"),
              ),
          barrierDismissible: true);
      ok = false;
    }
  });
  Navigator.pop(dialogContext);
  return ok;
}

Future<bool> downloadSong(Song song, BuildContext homeContext) async {
  BuildContext? dialogContext;
  ValueNotifier<double> progress = ValueNotifier(0);
  Dio dio = Dio();
  CancelToken cancelToken = CancelToken();
  showDialog(
      context: homeContext,
      builder: (context) {
        dialogContext = context;
        return ContentDialog(
          title: const Text("正在下载！"),
          content: Text("正在从网易云音乐的服务器上偷偷爬首\n《${song.name}》"),
          actions: [
            ValueListenableBuilder<double>(
              builder: (c, v, w) {
                return ProgressBar(
                  value: progress.value,
                );
              },
              valueListenable: progress,
            ),
            Container(
              child: FilledButton(child: const Text("取消"), onPressed: () {
                if (progress.value != 1 && !cancelToken.isCancelled) {
                  cancelToken.cancel();
                  Navigator.pop(dialogContext!);
                }
              }),
              padding: const EdgeInsets.only(left: 50),
            )
          ],
        );
      });
  if (proxy != null && proxy!.isNotEmpty) {
    dio.httpClientAdapter = IOHttpClientAdapter(
      onHttpClientCreate: (client) {
        client.findProxy = (uri) {
          return 'PROXY $proxy';
        };
        return client;
      },
    );
  }
  try {
    await dio.downloadUri(
        Uri.parse(song.url!), "${cacheDir.path}/${song.id}.mp3",
        onReceiveProgress: (int count, int total) =>
            progress.value = count / total * 100,
        cancelToken: cancelToken);
  } catch (e) {
    if (cancelToken.isCancelled) return false;
    while (dialogContext == null) {}
    Navigator.pop(dialogContext!);
    showDialog(
        context: homeContext,
        builder: (context) {
          return ContentDialog(
            title: const Text("出错啦！"),
            content: Text("下载《${song.name}》时出现错误：\n$e\n点击空白处关闭"),
          );
        },
        barrierDismissible: true);
    return false;
  }
  Navigator.pop(dialogContext!);
  return true;
}
