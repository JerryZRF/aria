import 'dart:async';
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
  Completer<BuildContext> completer = Completer<BuildContext>();
  showDialog(
      context: homeContext,
      barrierColor: Colors.transparent,
      builder: (context) {
        completer.complete(context);
        return ContentDialog(
          title: const Text("准备开始啦~"),
          content: Row(
            children: <Widget>[
              Expanded(
                child: Text("正在准备\n《${song.name}》\n很快就好啦~"),
              ),
              const ProgressRing(),
            ],
          ),
        );
      });
  bool ok = true;
  await netease.getSongInfo(song.id).then((value) async {
    Map<String, dynamic> map = json.decode(value.body);
    song.url = map["data"][0]["url"];
    await completer.future.then((dialogContext) => Navigator.pop(dialogContext));
    if (song.url == null) {
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
  return ok;
}

Future<bool> downloadSong(Song song, BuildContext homeContext) async {
  ValueNotifier<double> progress = ValueNotifier(0);
  Dio dio = Dio();
  CancelToken cancelToken = CancelToken();
  Completer<BuildContext> completer = Completer<BuildContext>();
  showDialog(
      context: homeContext,
      barrierColor: Colors.transparent,
      builder: (context) {
        completer.complete(context);
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
              padding: const EdgeInsets.only(left: 50),
              child: FilledButton(
                  child: const Text("取消"),
                  onPressed: () async {
                    if (progress.value != 1 && !cancelToken.isCancelled) {
                      cancelToken.cancel();
                      await completer.future.then((dialogContext) => Navigator.pop(dialogContext));
                    }
                  }),
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
    await completer.future.then((dialogContext) => Navigator.pop(dialogContext));
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
  await completer.future.then((dialogContext) => Navigator.pop(dialogContext));
  return true;
}
