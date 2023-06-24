import 'package:flutter/material.dart';
import 'ayat.dart';

class SettingsPage extends StatefulWidget {
  final List<int> fontSizes = [16, 24, 28, 32];
  final ParaAyatModel paraModel;
  SettingsPage(this.paraModel, {super.key});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int initialValue = 16;
  String? _backupPath;

  Widget _backupWidget() {
    return ListTile(
      title: const Text("Backup"),
      subtitle: _backupPath != null
          ? Text("Backed up at $_backupPath")
          : const Text("Backup your data to Downloads"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: Column(
        children: [
          ListTile(
            title: const Text("Ayat font size"),
            subtitle:
                const Text("Font size in the ayats list (not implemented)"),
            trailing: SizedBox(
              width: 100,
              child: DropdownButtonFormField(
                value: widget.fontSizes.first,
                onChanged: (int? val) {
                  if (val != null) {}
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
          ),
          const SizedBox(height: 16),
          _backupWidget()
        ],
      ),
    );
  }
}
