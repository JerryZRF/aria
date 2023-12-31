import 'package:aria/main.dart';
import 'package:aria/type/song.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:mmoo_lyric/lyric.dart';
import 'package:mmoo_lyric/lyric_controller.dart';
import 'package:mmoo_lyric/lyric_util.dart';
import 'package:mmoo_lyric/lyric_widget.dart';

class EditorPage extends StatefulWidget {
  final Song song;
  const EditorPage({super.key, required this.song});

  @override
  State<StatefulWidget> createState() {
    return EditorState();
  }
}

class EditorState extends State<EditorPage> with TickerProviderStateMixin {
  late LyricController controller;
  AudioPlayer player = AudioPlayer();
  bool playing = false;
  ValueNotifier<double> progress = ValueNotifier(0);
  ValueNotifier<Duration> pos = ValueNotifier(Duration.zero);
  ValueNotifier<fluent.IconData> icon = ValueNotifier(fluent.FluentIcons.play);

  @override
  Widget build(BuildContext context) {
    controller = LyricController(vsync: this);
    int total = 0;
    player
        .setSource(DeviceFileSource(widget.song.id == 0
            ? widget.song.url!
            : "${cacheDir.path}/${widget.song.id}.mp3"))
        .then((_) async {
      while (total <= 0) {
        await player.getDuration().then((value) {
          total = value!.inMilliseconds;
        });
      }
    });
    player.onPlayerComplete
        .listen((event) => icon.value = fluent.FluentIcons.play);
    player.onPositionChanged.listen((position) async {
      progress.value = position.inMilliseconds / total * 100;
      pos.value = position;
      controller.progress = position;
    });
    List<Lyric>? lyrics;
    if (widget.song.lyric != null) {
      try {
        lyrics = LyricUtil.formatLyric(widget.song.lyric!);
      } catch (e) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => fluent.displayInfoBar(context,
                builder: (context, close) => const fluent.InfoBar(
                      title: Text("出错啦"),
                      content: Text("加载歌词出错"),
                      severity: fluent.InfoBarSeverity.error,
                    ),
                duration: const Duration(milliseconds: 1500)));
      }
    } else {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => fluent.displayInfoBar(context,
              builder: (context, close) => const fluent.InfoBar(
                    title: Text("有点问题呢"),
                    content: Text("未能获取到该音乐的歌词"),
                    severity: fluent.InfoBarSeverity.warning,
                  ),
              duration: const Duration(milliseconds: 1500)));
    }
    return fluent.ScaffoldPage(
      header: fluent.PageHeader(
          title: const fluent.Text("播放器"),
          leading: Container(
            padding: const EdgeInsets.only(left: 15, right: 10),
            child: fluent.IconButton(
                style: fluent.ButtonStyle(iconSize: fluent.ButtonState.all(26)),
                icon: const Icon(fluent.FluentIcons.back),
                onPressed: () {
                  homeKey.currentState?.playing = -1;
                  homeKey.currentState?.setState(() {});
                }),
          )),
      content: Column(
        children: [
          fluent.Text(
            widget.song.name,
            style: const fluent.TextStyle(fontSize: 25),
          ),
          fluent.Text(
            widget.song.author,
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            children: [
              const SizedBox(
                width: 50,
              ),
              widget.song.poster != null
                  ? CachedNetworkImage(
                      width: 320,
                      height: 320,
                      placeholder: (context, url) => const fluent.ProgressBar(),
                      imageUrl: widget.song.poster!)
                  : const SizedBox(
                      width: 320,
                    ),
              const SizedBox(
                width: 75,
              ),
              lyrics == null
                  ? const SizedBox()
                  : LyricWidget(
                      size: const Size(450, 350),
                      lyrics: lyrics,
                      controller: controller,
                    ),
            ],
          ),
          const SizedBox(
            height: 75,
          ),
          ValueListenableBuilder<Duration>(
            builder: (context, value, child) =>
                fluent.Text("$value / ${Duration(milliseconds: total)}"),
            valueListenable: pos,
          ),
          Container(
            padding: const EdgeInsets.only(left: 100, right: 100),
            child: ValueListenableBuilder<double>(
              builder: (context, value, child) => fluent.Slider(
                  value: progress.value,
                  onChanged: (value) {
                    player.seek(Duration(milliseconds: total * value ~/ 100));
                    controller.progress =
                        Duration(milliseconds: total * value ~/ 100);
                    progress.value = value;
                  }),
              valueListenable: progress,
            ),
          ),
          fluent.IconButton(
            icon: ValueListenableBuilder<fluent.IconData>(
              builder: (context, value, child) => fluent.Icon(value),
              valueListenable: icon,
            ),
            onPressed: () {
              if (playing) {
                icon.value = fluent.FluentIcons.play;
                player.pause();
              } else {
                icon.value = fluent.FluentIcons.pause;
                player.play(
                    DeviceFileSource("${cacheDir.path}/${widget.song.id}.mp3"));
              }
              playing = !playing;
            },
            style: fluent.ButtonStyle(iconSize: fluent.ButtonState.all(30)),
          )
        ],
      ),
    );
  }

  @override
  void deactivate() {
    super.deactivate();
    player.stop();
  }
}
