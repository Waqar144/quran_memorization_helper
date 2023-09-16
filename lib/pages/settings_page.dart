import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:quran_memorization_helper/utils/utils.dart';

class SettingsPage extends StatefulWidget {
  final List<int> fontSizes = [20, 22, 24, 26, 28, 30, 32];
  final List<double> wordSpacings = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0];
  final ParaAyatModel paraModel;
  SettingsPage(this.paraModel, {super.key});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int initialValue = Settings.instance.fontSize;
  double wordSpacing = Settings.instance.wordSpacing.toDouble();
  bool pageView = Settings.instance.pageView;
  static const platform = MethodChannel('org.quran_rev_helper/backupDB');

  Widget _createBackupWidget() {
    return ListTile(
      title: const Text("Backup"),
      subtitle: const Text("Backup your data"),
      trailing: ElevatedButton(
        onPressed: () async {
          try {
            await platform.invokeMethod(
                'backupDB', {'data': widget.paraModel.jsonStringify()});
          } catch (e) {
            // do nothing
            // print("ERROR: $e");
          }
        },
        child: const Text("Backup"),
      ),
    );
  }

  Widget _restoreBackupWidget() {
    return ListTile(
      title: const Text("Restore Backup"),
      subtitle: const Text("Restore previously backed up data"),
      trailing: ElevatedButton(
        onPressed: () async {
          // get the file
          FilePickerResult? result = await FilePicker.platform.pickFiles(
              dialogTitle: "Select JSON File",
              type: FileType.custom,
              allowedExtensions: ["json"]);
          if (result == null) return;
          if (result.paths.isEmpty) return;

          String? path = result.paths.first;
          if (path == null) return;
          // ask the para model to load this db
          final bool readResult = await widget.paraModel.readJsonDB(path: path);
          if (readResult) {
            if (mounted) {
              // success message
              showSnackBarMessage(
                  context, "${result.names.first} imported successfully");
            }
            // persist
            widget.paraModel.saveToDisk();
          }
        },
        child: const Text("Restore"),
      ),
    );
  }

  Widget _createFontSizeTile() {
    return ListTile(
      title: const Text("Ayat font size"),
      subtitle: const Text("Font size in the ayats list (not implemented)"),
      trailing: SizedBox(
        width: 80,
        child: DropdownButtonFormField(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          decoration: const InputDecoration(contentPadding: EdgeInsets.all(8)),
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
        width: 80,
        child: DropdownButtonFormField<double>(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          decoration: const InputDecoration(contentPadding: EdgeInsets.all(8)),
          value: wordSpacing,
          onChanged: (double? val) {
            if (val != null) {
              wordSpacing = val;
              Settings.instance.wordSpacing = val.toInt();
            }
          },
          padding: EdgeInsets.zero,
          items: [
            for (final size in widget.wordSpacings)
              DropdownMenuItem(
                value: size,
                child: Text(size.toString()),
              )
          ],
        ),
      ),
    );
  }

  Widget _createPageViewTile() {
    return ListTile(
      title: const Text("Page View"),
      subtitle: const Text("Show quran page by page or scroll vertically"),
      trailing: Switch(
        value: pageView,
        onChanged: (newValue) {
          pageView = newValue;
          Settings.instance.pageView = pageView;
          setState(() {});
        },
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
          _createPageViewTile(),
          _createBackupWidget(),
          _restoreBackupWidget()
        ],
      ),
    );
  }
}
