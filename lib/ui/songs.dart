import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;

import '../main.dart';
import '../type/song.dart';
import 'colors.dart';
import 'home.dart';
import '../netease.dart' as netease;

class SongList extends StatefulWidget {
  const SongList({super.key});

  @override
  State<StatefulWidget> createState() => SongListState();
}

class SongListState extends State<SongList> {
  @override
  Widget build(BuildContext context) {
    return material.Scaffold(
      backgroundColor: background,
      floatingActionButton: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 70),
            child: Align(
              alignment: Alignment.bottomRight,
              child: material.FloatingActionButton(
                heroTag: "btn1",
                backgroundColor: button,
                onPressed: () => generate(context),
                child: const Icon(material.Icons.gavel_rounded),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: material.FloatingActionButton(
              heroTag: "btn2",
              backgroundColor: button,
              onPressed: () async {
                const XTypeGroup musicGroup = XTypeGroup(
                  label: "音频文件",
                  extensions: <String>["mp3", "wma", "wav", "aac"],
                );
                final List<XFile> files = await openFiles(
                    acceptedTypeGroups: [musicGroup, const XTypeGroup()]);
                if (files.isEmpty) {
                  return;
                }
                bool? result = await showDialog<bool>(
                  context: context,
                  builder: (context) => ContentDialog(
                    title: const Text("导入本地文件"),
                    content: const Text("是否复制一份文件？\n可以防止源文件丢失或环境迁移，但会多占用一份空间"),
                    actions: [
                      Button(
                          child: const Text("否"),
                          onPressed: () => Navigator.pop(context, false)),
                      FilledButton(
                          child: const Text("是"),
                          onPressed: () => Navigator.pop(context, true))
                    ],
                  ),
                );
                if (result!) {
                  for (XFile f in files) {
                    File file = File(f.path);
                    String md = md5.convert(file.readAsBytesSync()).toString();
                    if (!File("${cacheDir.path}/$md.${f.name.split(".").last}")
                        .existsSync()) {
                      await file.copy(
                          "${cacheDir.path}/$md.${f.name.split(".").last}");
                    }
                    projects[nowProject].songs.add(Song(
                        f.name, 0, "Unknown", null,
                        url: "${cacheDir.path}/$md.${f.name.split(".").last}"));
                    // save();
                  }
                  setState(() {});
                } else {
                  for (XFile f in files) {
                    projects[nowProject]
                        .songs
                        .add(Song(f.name, 0, "Unknown", null, url: f.path));
                    // print(f.path);
                  }
                  setState(() {});
                }
              },
              child: const Icon(material.Icons.insert_drive_file_outlined),
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
            style:
                TextStyle(fontSize: 34, color: title, fontFamily: "HYWenHei"),
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
                  borderRadius: BorderRadius.circular(10.0), color: item),
              child: Text(
                "${song.name}  -  ${song.author}",
                style: const TextStyle(fontFamily: "HYWenHei"),
              ),
            ),
            onDoubleTap: () async {
              if (song.url == null || song.url!.startsWith("http")) {
                if (!File("${cacheDir.path}/${song.id}.mp3").existsSync()) {
                  late BuildContext dialog;
                  ValueNotifier<double> progress = ValueNotifier(0);
                  showDialog(
                      context: context,
                      builder: (dialogContext) {
                        dialog = dialogContext;
                        return ContentDialog(
                          title: const Text("正在加载歌曲"),
                          content: const Text("请稍等..."),
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
                  bool ok = true;
                  await netease.getSongInfo(song.id).then((value) async {
                    Map<String, dynamic> map = jsonDecode(value.body);
                    song.url = map["data"][0]["url"];
                    if (song.url == null) {
                      Navigator.pop(dialog);
                      await showDialog(
                          context: context,
                          builder: (context) {
                            return ContentDialog(
                              title: const Text("出错啦！"),
                              content: Text("怎么会混进《${song.name}》这首付费歌曲呢?"),
                            );
                          },
                          barrierDismissible: true);

                      ok = false;
                    }
                  });
                  if (!ok) return;
                  await dio.downloadUri(
                      Uri.parse(song.url!), "${cacheDir.path}/${song.id}.mp3");
                  Navigator.pop(dialog);
                }
                await netease.getSongLyric(song.id).then((value) {
                  Map<String, dynamic> map = jsonDecode(value.body);
                  song.lyric = map["lyric"];
                });
              }
              homeKey.currentState?.editing =
                  projects[nowProject].songs.indexOf(song);
              homeKey.currentState?.setState(() {});
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
    );
  }
}
