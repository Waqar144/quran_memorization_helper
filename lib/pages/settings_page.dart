import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:quran_memorization_helper/utils/utils.dart';

const String appVersion = "1.2.0";

String _themeModeToString(ThemeMode m) {
  return switch (m) {
    ThemeMode.system => "System",
    ThemeMode.light => "Light",
    ThemeMode.dark => "Dark",
  };
}

class SettingsPage extends StatefulWidget {
  final List<int> fontSizes = [20, 22, 24, 26, 28, 30, 32];
  final List<double> wordSpacings = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0];
  final List<ThemeMode> themeModes = ThemeMode.values;
  final ParaAyatModel paraModel;
  SettingsPage(this.paraModel, {super.key});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int initialValue = Settings.instance.fontSize;
  double wordSpacing = Settings.instance.wordSpacing.toDouble();
  ThemeMode themeMode = Settings.instance.themeMode;
  static const platform = MethodChannel('org.quran_rev_helper/backupDB');

  void _showError(String message) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
                const Text(
                    "Please try again. If the error persists please report a bug."),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _createBackupWidget() {
    return ListTile(
      title: const Text("Backup"),
      subtitle: const Text("Backup your data"),
      trailing: ElevatedButton(
        onPressed: () async {
          try {
            final res = await platform.invokeMethod(
                'backupDB', {'data': widget.paraModel.jsonStringify()});
            if (res == "CANCELED") {
              return;
            }
            // success message
            if (mounted) showSnackBarMessage(context, "Backup Succesful");
          } catch (e) {
            // do nothing
            _showError("Error creating backup: $e");
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
          await FilePicker.platform.clearTemporaryFiles();
          FilePickerResult? result = await FilePicker.platform.pickFiles(
              dialogTitle: "Select JSON File",
              type: FileType.custom,
              allowedExtensions: ["json"]);
          if (result == null) return;
          if (result.paths.isEmpty) return;

          String? path = result.paths.first;
          if (path == null) return;
          // ask the para model to load this db
          final (ok, error) = await widget.paraModel.readJsonDB(path: path);
          if (ok) {
            if (mounted) {
              // success message
              showSnackBarMessage(
                  context, "${result.names.first} imported successfully");
            }
            // persist
            widget.paraModel.saveToDisk();
          } else {
            _showError("Error while restoring: $error");
          }
        },
        child: const Text("Restore"),
      ),
    );
  }

  Widget _createThemeModeTile() {
    return ListTile(
      title: const Text("Theme"),
      subtitle: const Text("Switch between light or dark mode"),
      trailing: SizedBox(
        width: 100,
        child: DropdownButtonFormField<ThemeMode>(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          decoration: const InputDecoration(contentPadding: EdgeInsets.all(8)),
          value: themeMode,
          onChanged: (ThemeMode? val) {
            if (val != null) {
              themeMode = val;
              Settings.instance.themeMode = val;
            }
          },
          padding: EdgeInsets.zero,
          items: [
            for (final themeMode in widget.themeModes)
              DropdownMenuItem(
                value: themeMode,
                child: Text(_themeModeToString(themeMode)),
              )
          ],
        ),
      ),
    );
  }

  Widget _createFontSizeTile() {
    return ListTile(
      title: const Text("Ayat font size"),
      subtitle: const Text("Font size in the ayats list (not while reading)"),
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

  Widget _translationInfo() {
    return const ListTile(
      leading: Icon(Icons.translate),
      title: Text("Translation"),
      subtitle: Text("Molana Fateh Muhammad Jalandhari"),
    );
  }

  Widget _version() {
    return ListTile(
      leading: const Icon(Icons.app_settings_alt),
      title: const Text("App version"),
      subtitle: const Text(appVersion),
      onTap: () async {
        await launchUrl(
            Uri.parse(
                "https://github.com/Waqar144/quran_memorization_helper/releases"),
            mode: LaunchMode.externalApplication);
      },
    );
  }

  Widget _reportAnIssue() {
    return ListTile(
      leading: const Icon(Icons.bug_report),
      title: const Text("Report a bug/issue"),
      subtitle:
          const Text("Faced an issue or have a suggestion? Tap to report"),
      onTap: () async {
        await launchUrl(
            Uri.parse(
                "https://github.com/Waqar144/quran_memorization_helper/issues"),
            mode: LaunchMode.externalApplication);
      },
    );
  }

  Widget _email() {
    return ListTile(
      leading: const Icon(Icons.email),
      title: const Text("Email support"),
      subtitle: const Text("Reach out to us via email directly"),
      onTap: () async {
        await launchUrl(Uri.parse("support@streetwriters.co"),
            mode: LaunchMode.externalApplication);
      },
    );
  }

  Widget _licenses() {
    return ListTile(
      leading: const Icon(Icons.policy),
      title: const Text("View licenses"),
      subtitle:
          const Text("View licenses of open source libraries used in this app"),
      onTap: () async {
        showLicensePage(
          context: context,
          applicationVersion: appVersion,
          applicationName: "Quran 16 Line",
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        children: [
          _createThemeModeTile(),
          _createFontSizeTile(),
          _createWordSpacingTile(),
          _createBackupWidget(),
          _restoreBackupWidget(),
          const Divider(),
          _reportAnIssue(),
          _email(),
          const Divider(),
          _translationInfo(),
          _licenses(),
          _version(),
        ],
      ),
    );
  }
}
