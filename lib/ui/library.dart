import 'dart:convert';

import 'package:aria/type/song.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

import '../main.dart';
import '../netease.dart' as netease;
import 'colors.dart';

class MusicLibrary extends StatefulWidget {
  const MusicLibrary({super.key});

  @override
  State<MusicLibrary> createState() => _MusicLibraryState();
}

int _nowIndex = 1;
String _nowValue = "";
List<Song> songs = <Song>[];

class _MusicLibraryState extends State<MusicLibrary> {
  @override
  Widget build(BuildContext context) {
    TextEditingController controller = TextEditingController();
    controller.text = _nowValue;
    return Scaffold(
      backgroundColor: background,
      body: Column(
        children: [
          fluent.Container(
            padding: const EdgeInsets.only(left: 25, right: 25, bottom: 25),
            child: fluent.TextBox(
              placeholder: "请输入你想搜索的歌曲",
              controller: controller,
              onSubmitted: (text) {
                _nowValue = text;
                search();
              },
            ),
          ),
          Expanded(
              child: ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                        onTap: () {
                          projects[nowProject].songs.add(songs[index]);
                          fluent.displayInfoBar(context,
                              builder: (context, close) {
                            return fluent.InfoBar(
                              title: Text("已加入《${songs[index].name}》"),
                              severity: fluent.InfoBarSeverity.success,
                            );
                          }, duration: const Duration(milliseconds: 800));
                        },
                        child: Container(
                            height: 40,
                            width: double.infinity,
                            alignment: const Alignment(-0.97, 0),
                            margin: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: item),
                            child: Text(
                              "${songs[index].name}  -  ${songs[index].author}",
                              style: const TextStyle(fontFamily: "HYWenHei"),
                            )));
                  })),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: "QQ音乐",
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.music_note),
            label: "网易云",
            activeIcon: Icon(
              Icons.music_note,
              color: button,
            ),
          ),
        ],
        selectedLabelStyle: const TextStyle(fontFamily: "HYWenHei"),
        unselectedLabelStyle: const TextStyle(fontFamily: "HYWenHei"),
        currentIndex: _nowIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == _nowIndex) return;
          if (index == 0) {
            fluent.displayInfoBar(context, builder: (context, close) {
              return const fluent.InfoBar(
                title: Text("出错啦"),
                content: Text("QQ音乐暂不受支持"),
                severity: fluent.InfoBarSeverity.error,
              );
            }, duration: const Duration(seconds: 1));
            // fluent.showDialog(context: context, builder: (context) => fluent.ContentDialog(content: fluent.Text("暂不支持QQ音乐"),));
            return;
          }
          setState(() {
            _nowIndex = index;
          });
        },
      ),
    );
  }

  void search() {
    songs.clear();
    //TODO
    if (_nowValue.isEmpty) {
      setState(() {});
      return;
    }
    netease.searchSongs(_nowValue).then((value) {
      setState(() {
        Map<String, dynamic> map = json.decode(value.body);
        if (map["result"] == null || map["result"]["songs"] == null) {
          return;
        }
        List songList = map["result"]["songs"];
        for (int i = 0; i < songList.length; i++) {
          // print(songList[i]);
          if (songList[i]["privilege"]["sp"] != 7) {
            continue;
          }
          String authors = "";
          for (var author in songList[i]["ar"]) {
            authors += author["name"] + ", ";
          }
          songs.add(Song(
              songList[i]["name"],
              songList[i]["id"] as int,
              authors.substring(0, authors.length - 2),
              songList[i]["al"]["picUrl"]));
        }
      });
    });
  }
}
