import 'package:flutter/material.dart';
import 'ayat.dart';
import 'settings.dart';

class SettingsPage extends StatefulWidget {
  final List<int> fontSizes = [16, 24, 28, 32];
  final ParaAyatModel paraModel;
  SettingsPage(this.paraModel, {super.key});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int initialValue = Settings.instance.fontSize;
  double wordSpacing = Settings.instance.wordSpacing.toDouble();
  String? _backupPath;

  Widget _createBackupWidget() {
    return ListTile(
      title: const Text("Backup"),
      subtitle: _backupPath != null
          ? Text("Backed up at $_backupPath")
          : const Text("Backup your data"),
      trailing: ElevatedButton(
        onPressed: () async {
          String path = await widget.paraModel.backup();
          setState(() {
            _backupPath = path;
          });
        },
        child: const Text("Backup"),
      ),
    );
  }

  Widget _createFontSizeTile() {
    return ListTile(
      title: const Text("Ayat font size"),
      subtitle: const Text("Font size in the ayats list (not implemented)"),
      trailing: SizedBox(
        width: 100,
        child: DropdownButtonFormField(
          value: initialValue,
          onChanged: (int? val) {
            if (val != null) {
              Settings.instance.fontSize = val;
              initialValue = val;
            }
          },
          padding: EdgeInsets.zero,
          items: [
            for (final size in widget.fontSizes)
              DropdownMenuItem(
                value: size,
                child: Text(size.toString()),
              )
          ],
        ),
      ),
    );
  }

  Widget _createWordSpacingTile() {
    return ListTile(
      title: const Text("Word spacing"),
      subtitle: const Text("Space between words of an ayah"),
      trailing: SizedBox(
        width: 300,
        child: Slider(
          value: wordSpacing,
          min: 0,
          max: 5,
          divisions: 5,
          label: wordSpacing.toString(),
          onChanged: (double val) {
            setState(() {
              wordSpacing = val;
              Settings.instance.wordSpacing = val.toInt();
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: Column(
        children: [
          _createFontSizeTile(),
          const SizedBox(height: 16),
          _createWordSpacingTile(),
          _createBackupWidget()
        ],
      ),
    );
  }
}
