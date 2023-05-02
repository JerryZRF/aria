import 'dart:io';

import 'package:aria/main.dart';
import 'package:fluent_ui/fluent_ui.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return SettingsState();
  }
}

class SettingsState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    int cacheSize = 0;
    int copySize = 0;
    List<FileSystemEntity> files = [];
    if (cacheDir.existsSync()) {
      cacheDir.listSync().forEach((file) {
        FileStat stat = file.statSync();
        if (file.path
            .split("\\")
            .last
            .length == 36) {
          copySize += stat.size;
        } else {
          cacheSize += stat.size;
          files.add(file);
        }
      });
    }
    TextEditingController controller = TextEditingController();
    controller.text = proxy == null ? "" : proxy!;
    return ScaffoldPage.scrollable(children: [
      const Text("代理", style: TextStyle(fontSize: 34)),
      const SizedBox(
        height: 16,
      ),
      TextBox(
        placeholder: "地址",
        controller: controller,
        onChanged: (text) => proxy = text,
      ),
      const SizedBox(
        height: 30,
      ),
      const Text("缓存", style: TextStyle(fontSize: 34)),
      Text("在线下载共${(cacheSize / 1024 / 1024).toStringAsFixed(2)}MB"),
      Text("本地导入共${(copySize / 1024 / 1024).toStringAsFixed(2)}MB"),
      FilledButton(
          child: const Text("清除在线下载的缓存"),
          onPressed: () {
            homeKey.currentState!.playing = -1;
            for (var file in files) {
              file.deleteSync();
              setState(() {});
            }
          }),
    ]);
  }
}
