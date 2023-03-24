import 'dart:convert';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:aria/song.dart';
import 'package:flutter/material.dart';
import 'package:ftoast/ftoast.dart';
import 'package:get/get.dart';

import 'netease.dart' as netease;

class MusicGetter extends StatefulWidget {
  const MusicGetter({super.key});

  @override
  State<MusicGetter> createState() => _MusicGetterState();
}

class _MusicGetterState extends State<MusicGetter> {
  int _nowIndex = 1;
  String _nowValue = "";
  List<Song> songs = <Song>[];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SearchBarWidget(
          onchangeValue: (value) {
            _nowValue = value;
          },
          onEditingComplete: () {
            songs.clear();
            //TODO
            netease.searchSongs(_nowValue).then((value) {
              Map<String, dynamic> map = json.decode(value.body);
              List songList = map["result"]["songs"];
              for (int i = 0; i < songList.length; i++) {
                songs.add(Song(songList[i]["name"], songList[i]["id"] as int,
                    songList[i]["ar"][0]["name"]));
              }
              setState(() {});
            });
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
              child: ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                        onTap: () {
                          print(songs[index].id);
                          netease.getSongInfo(songs[index].id).then((value) {
                            Map<String, dynamic> map = json.decode(value.body);
                            if (map["data"][0]["url"] == null) {
                              FToast.toast(context,
                                  msg: "该歌曲是VIP单曲！暂不支持",
                                  msgStyle:
                                      const TextStyle(fontFamily: "HYWenHei"),
                                  color: Colors.grey.shade400, duration: 800);
                              return;
                            }
                            songs[index].url = map["data"][0]["url"];
                            if (!Get.find<SongListController>().add(songs[index])) {
                              FToast.toast(context,
                                  msg: "《${songs[index].name}》已经在播放列表中",
                                  msgStyle:
                                  const TextStyle(fontFamily: "HYWenHei"),
                                  color: Colors.grey.shade400,
                                  duration: 500);
                              return;
                            }
                            FToast.toast(context,
                                msg: "已加入《${songs[index].name}》",
                                msgStyle:
                                const TextStyle(fontFamily: "HYWenHei"),
                                color: Colors.grey.shade400,
                                duration: 500);
                            print(map["data"][0]["url"]);
                          });
                        },
                        child: Container(
                            width: double.infinity,
                            height: 50,
                            alignment: Alignment.center,
                            margin: const EdgeInsets.all(3),
                            child: Text(
                              "${songs[index].name}  -  ${songs[index].author}",
                              style: const TextStyle(fontFamily: "HYWenHei"),
                            )));
                  })),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: "QQ音乐",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: "网易云",
          ),
        ],
        selectedLabelStyle: const TextStyle(fontFamily: "HYWenHei"),
        unselectedLabelStyle: const TextStyle(fontFamily: "HYWenHei"),
        currentIndex: _nowIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == _nowIndex) return;
          if (index == 0) {
            FToast.toast(context,
                msg: "QQ音乐暂不受支持",
                msgStyle: const TextStyle(fontFamily: "HYWenHei"),
                color: Colors.grey.shade400,
                duration: 800);
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

  void onClickSongInfo(int index) {}
}

class SearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onchangeValue;
  final VoidCallback onEditingComplete;
  const SearchBarWidget(
      {required this.onchangeValue, required this.onEditingComplete, Key? key})
      : super(key: key);

  @override
  SearchBarWidgetState createState() => SearchBarWidgetState();
}

class SearchBarWidgetState extends State<SearchBarWidget> {
  ///编辑控制器
  late TextEditingController _controller;

  ///是否显示删除按钮
  bool _hasDeleteIcon = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  Widget buildTextField() {
    //theme设置局部主题
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      keyboardType: TextInputType.text,
      maxLines: 1,
      decoration: InputDecoration(
        //输入框decoration属性
        contentPadding:
            const EdgeInsets.symmetric(vertical: 6, horizontal: 1.0),
        //设置搜索图片
        prefixIcon: const Icon(Icons.search),
        prefixIconConstraints: const BoxConstraints(
          //设置搜索图片左对齐
          minWidth: 30,
          minHeight: 25,
        ),
        border: InputBorder.none, //无边框
        hintText: "请输入歌曲名",
        hintStyle: const TextStyle(
            fontSize: 15, color: Colors.grey, fontFamily: "HYWenHei"),
        //设置清除按钮
        suffixIcon: Container(
          padding: EdgeInsetsDirectional.only(
            start: 2.0,
            end: _hasDeleteIcon ? 0.0 : 0,
          ),
          child: _hasDeleteIcon
              ? InkWell(
                  onTap: (() {
                    setState(() {
                      /// 保证在组件build的第一帧时才去触发取消清空内容
                      WidgetsBinding.instance
                          .addPostFrameCallback((_) => _controller.clear());
                      _hasDeleteIcon = false;
                    });
                  }),
                  child: const Icon(
                    Icons.cancel,
                    size: 18.0,
                    color: Colors.grey,
                  ),
                )
              : const Text(''),
        ),
      ),
      onChanged: (value) {
        setState(() {
          if (value.isEmpty) {
            _hasDeleteIcon = false;
          } else {
            _hasDeleteIcon = true;
          }
          widget.onchangeValue(_controller.text);
        });
      },
      onEditingComplete: () {
        FocusScope.of(context).requestFocus(FocusNode());
        widget.onEditingComplete();
      },
      style: const TextStyle(fontSize: 14, color: Colors.black),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      //背景与圆角
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12, width: 1.0), //边框
        color: Colors.black12,
        borderRadius: const BorderRadius.all(Radius.circular(18)),
      ),
      alignment: Alignment.center,
      height: 36,
      padding: const EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
      child: buildTextField(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}

class SongListController extends GetxController {
  final List<Song> songs = [];
  bool add(Song song) {
    if (songs.contains(song)) {
      return false;
    }
    songs.add(song);
    return true;
  }
}
