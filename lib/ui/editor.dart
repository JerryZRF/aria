import 'package:fluent_ui/fluent_ui.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return EditorState();
  }
}

class EditorState extends State<EditorPage> {
  @override
  Widget build(BuildContext context) {
    return const ScaffoldPage();
  }
}