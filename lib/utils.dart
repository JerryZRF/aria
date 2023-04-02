import 'dart:convert';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';

import 'main.dart';

String format(String source) {
  return source.replaceAll(",", ", ").replaceAll(":", ": ");
}

Future saveDialog(BuildContext context) async{
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
  }
}

Future save() async {
  File file = File("./config.json");
  await file.writeAsString(jsonEncode({"projects": projects}));
}