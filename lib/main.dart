import 'dart:io';

import 'package:aria/music_lib.dart';
import 'package:dio/dio.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:get/get.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;

GlobalKey<NavigatorState> nk = GlobalKey();

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
    await windowManager.setSize(const Size(1280, 768));
    await windowManager.center();
    await windowManager.show();
    await windowManager.setPreventClose(true);
    await windowManager.setSkipTaskbar(false);
  });
  runApp(const material.MaterialApp(
    home: HomePage(),
  ));
}

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
    SongListController controller = SongListController();
    Get.put(controller);
    return FluentApp(
      navigatorKey: nk,
      theme: FluentThemeData(
          fontFamily: "HYWenHei", scaffoldBackgroundColor: Colors.grey[110]),
      home: NavigationView(
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
          actions: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: GestureDetector(
              child: const Icon(
                material.Icons.close,
                size: 24,
              ),
              onTap: () {
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
                      if (Get.find<SongListController>().songs.isEmpty) {
                        return;
                      }
                      final ProgressDialog pd = ProgressDialog(context,
                          type: ProgressDialogType.Download,
                          isDismissible: true);
                      pd.style(
                        progress: 0.0,
                        message: "正在连接...",
                        maxProgress: 100.0,
                        messageTextStyle: const TextStyle(
                            fontFamily: "HYWenHei", fontSize: 18),
                      );
                      await pd.show();
                      File listFile = File("./download/list.txt");
                      if (listFile.existsSync()) {
                        listFile.delete();
                      }
                      for (var song in Get.find<SongListController>().songs) {
                        try {
                          // params += "${song.id}.mp3|";
                          await listFile.writeAsString(
                              "file '${song.id}.mp3'\n",
                              mode: FileMode.append);
                          if (File("./download/${song.id}.mp3").existsSync()) {
                            pd.update(
                                progress: 100,
                                message: "下载完成\n点击空白处关闭",
                                isDismissible: true);
                            continue;
                          }
                          Dio dio = Dio();
                          // (dio.httpClientAdapter as DefaultHttpClientAdapter)
                          //     .onHttpClientCreate = (client) {
                          //   client.findProxy = (url) {
                          //     return "PROXY localhost:7891";
                          //   };
                          //   //Trust certificate for https proxy
                          //   client.badCertificateCallback = (cert, host, port) {
                          //     return true;
                          //   };
                          //   return client;
                          // };
                          await dio.downloadUri(
                              Uri.parse(song.url), "./download/${song.id}.mp3",
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
                      //合并音频
                      await Process.run("ffmpeg", [
                        "-y",
                        "-f",
                        "concat",
                        "-safe",
                        "0",
                        "-i",
                        File("./download/list.txt").absolute.path,
                        "-loglevel",
                        "error",
                        "-c",
                        "copy",
                        "./tmp.mp3"
                      ]).then((value) {
                        print(value.exitCode);
                        print(value.stderr);
                      });
                      //询问是否平衡
                      bool? result = await showDialog<bool>(
                        context: nk.currentContext!,
                        builder: (context) => ContentDialog(
                          title: const Text(
                            "平衡音量",
                            style: TextStyle(
                                fontSize: 30, fontWeight: FontWeight.normal),
                          ),
                          content: const Text(
                            "FFmpeg对音量标准化的处理功能。\n即削峰填谷，使整个音频的音量变得平滑",
                            style: TextStyle(fontWeight: FontWeight.w100),
                          ),
                          actions: [
                            Button(
                              child: const Text('算了吧'),
                              onPressed: () => Navigator.pop(context, false),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              style:
                                  ButtonStyle(elevation: ButtonState.all(12)),
                              child: const Text("平衡"),
                            ),
                          ],
                        ),
                      );
                      if (result!) {
                        //显示平衡进度条
                        late BuildContext prc;
                        showDialog(
                            context: nk.currentContext!,
                            builder: (context) {
                              prc = context;
                              return const ContentDialog(
                                title: Text(
                                  "正在平衡音量",
                                  style: TextStyle(fontWeight: FontWeight.w100),
                                ),
                                content: ProgressRing(),
                              );
                            });
                        Process.run("ffmpeg", [
                          "-i",
                          "./tmp.mp3",
                          "-filter:a",
                          "loudnorm",
                          "-loglevel",
                          "error",
                          "-y",
                          "./output.mp3",
                        ]).then((value) {
                          print(value.stderr);
                          print(value.exitCode);
                          Navigator.pop(prc);
                          // File("./tmp.mp3").delete();
                        });
                      }
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
                    children: Get.find<SongListController>().songs.map((song) {
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
                            Get.find<SongListController>().songs.remove(song);
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
                        var item = Get.find<SongListController>()
                            .songs
                            .removeAt(oldIndex);
                        Get.find<SongListController>()
                            .songs
                            .insert(newIndex, item);
                      });
                    },
                  ),
                )),
            PaneItem(
              icon: const Icon(material.Icons.library_music),
              title: const Text("音乐库"),
              body: const ScaffoldPage(content: MusicGetter()),
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
      ),
    );
  }
}
