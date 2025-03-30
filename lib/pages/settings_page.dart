import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:quran_memorization_helper/utils/utils.dart';

const String appVersion = "1.4.0";

class _ChangeTranslationDialog extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ChangeTranslationDialogState();
}

class _ChangeTranslationDialogState extends State<_ChangeTranslationDialog> {
  String error = "";

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text("Change Translation"),
      contentPadding: const EdgeInsets.all(16),
      children: [
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(text: "You can download translations from "),
              TextSpan(
                text: "https://tanzil.net/trans/",
                style: TextStyle(decoration: TextDecoration.underline),
              ),
              TextSpan(
                text:
                    " and then load them using the 'Load' button below. Please select ",
              ),
              TextSpan(
                text: "Text",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
              TextSpan(text: " as the "),
              TextSpan(
                text: "File Format",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
              TextSpan(text: " before downloading."),
            ],
          ),
        ),
        if (error.isNotEmpty)
          Text("Error: $error", style: const TextStyle(color: Colors.red)),
        Wrap(
          direction: Axis.horizontal,
          alignment: WrapAlignment.spaceAround,
          // mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text("Goto tanzil.net"),
              onPressed: () {
                launchUrl(Uri.parse("https://tanzil.net/trans/"));
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.restore),
              label: const Text("Restore Default"),
              onPressed: () {
                Settings.instance.translationFile = "";
                if (context.mounted) {
                  Navigator.of(context).pop();
                  showSnackBarMessage(context, "Restored default translation");
                }
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text("Load..."),
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  dialogTitle: "Select translation File",
                  type: FileType.custom,
                  allowedExtensions: ["txt"],
                );
                if (result == null || !result.isSinglePick) return;
                String? path = result.paths.first;
                if (path == null) return;
                final lines = File(path).readAsLinesSync();
                if (lines.length < 6237) {
                  setState(() {
                    error = "Invalid translation file";
                  });
                } else {
                  Settings.instance.translationFile = path;
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    showSnackBarMessage(context, "Succesfully loaded $path");
                  }
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

String _themeModeToString(ThemeMode m) {
  return switch (m) {
    ThemeMode.system => "System",
    ThemeMode.light => "Light",
    ThemeMode.dark => "Dark",
  };
}

String _mushafToString(Mushaf m) {
  return switch (m) {
    Mushaf.Indopak16Line => "16 Line",
    Mushaf.Uthmani15Line => "15 Line (Uthmani)",
  };
}

class SettingsPage extends StatefulWidget {
  final List<int> fontSizes = [24, 26, 28, 30, 32, 34];
  final List<ThemeMode> themeModes = ThemeMode.values;
  final List<Mushaf> mushafs = Mushaf.values;
  final ParaAyatModel paraModel;
  SettingsPage(this.paraModel, {super.key});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  ThemeMode themeMode = Settings.instance.themeMode;
  Mushaf selectedMushaf = Settings.instance.mushaf;
  static const platform = MethodChannel('org.quran_rev_helper/backupDB');

  void _showError(String message) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message, softWrap: true),
                const Text(
                  "Please try again. If the error persists please report a bug.",
                ),
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
            final res = await platform.invokeMethod('backupDB', {
              'data': widget.paraModel.jsonStringify(),
            });
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
          try {
            // get the file
            await FilePicker.platform.clearTemporaryFiles();
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              dialogTitle: "Select JSON File",
              type: FileType.any,
              // allowedExtensions: ["json"], doesn't work on android <= 9
            );
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
                  context,
                  "${result.names.first} imported successfully",
                );
              }
              // persist
              widget.paraModel.saveToDisk();
            } else {
              _showError("Error while restoring: $error");
            }
          } catch (e) {
            _showError("Exception occurred, please report a bug: $e");
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
        width: 120,
        child: DropdownButton<ThemeMode>(
          isExpanded: true,
          borderRadius: const BorderRadius.all(Radius.circular(5)),
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _createMushafSelectionTile() {
    return ListTile(
      title: const Text("Mushaf"),
      subtitle: const Text("Switch between available Mushafs"),
      trailing: SizedBox(
        width: 120,
        child: DropdownButton<Mushaf>(
          isExpanded: true,
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          value: selectedMushaf,
          onChanged: (Mushaf? val) {
            if (val != null) {
              selectedMushaf = val;
              Settings.instance.mushaf = val;
            }
          },
          padding: EdgeInsets.zero,
          items: [
            for (final mushaf in widget.mushafs)
              DropdownMenuItem(
                value: mushaf,
                child: Text(_mushafToString(mushaf)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _createReflowModeTile() {
    return ListTile(
      title: const Text("Reflow text"),
      subtitle: const Text(
        "Reflow text instead of following page layout strictly. This allows changing font size",
      ),
      trailing: Switch(
        value: Settings.instance.reflowMode,
        onChanged: (bool newValue) {
          Settings.instance.reflowMode = newValue;
        },
      ),
    );
  }

  Widget _createFontSizeTile() {
    return ListTile(
      enabled: Settings.instance.reflowMode,
      title: const Text("Font size"),
      subtitle: const Text("Enable 'Reflow text' to change font size"),
      trailing: SizedBox(
        width: 80,
        child: DropdownButtonFormField(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          decoration: const InputDecoration(contentPadding: EdgeInsets.all(8)),
          value: Settings.instance.fontSize,
          onChanged:
              Settings.instance.reflowMode
                  ? (int? val) {
                    if (val != null) {
                      Settings.instance.fontSize = val;
                    }
                  }
                  : null,
          padding: EdgeInsets.zero,
          items: [
            for (final size in widget.fontSizes)
              DropdownMenuItem(value: size, child: Text(size.toString())),
          ],
        ),
      ),
    );
  }

  Widget _tapToShowTranslationTile() {
    return ListTile(
      title: const Text("Tap to show translation"),
      subtitle: const Text("Long press will mark a mistake"),
      trailing: Switch(
        value: Settings.instance.tapToShowTranslation,
        onChanged: (bool newValue) {
          Settings.instance.tapToShowTranslation = newValue;
        },
      ),
    );
  }

  Widget _customTranslationTile() {
    return ListTile(
      title: const Text("Change Translation"),
      subtitle: const Text("Load a different translation"),
      trailing: ElevatedButton(
        child: const Text("Change..."),
        onPressed: () {
          showDialog<void>(
            context: context,
            builder: (context) {
              return _ChangeTranslationDialog();
            },
          );
        },
      ),
    );
  }

  Widget _translationInfo() {
    return const ListTile(
      leading: Icon(Icons.translate),
      title: Text("Default Translation"),
      subtitle: Text("Fateh Muhammad Jalandhari (Urdu)"),
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
            "https://github.com/Waqar144/quran_memorization_helper/releases",
          ),
          mode: LaunchMode.externalApplication,
        );
      },
    );
  }

  Widget _reportAnIssue() {
    return ListTile(
      leading: const Icon(Icons.bug_report),
      title: const Text("Report a bug/issue"),
      subtitle: const Text(
        "Faced an issue or have a suggestion? Tap to report",
      ),
      onTap: () async {
        await launchUrl(
          Uri.parse(
            "https://github.com/Waqar144/quran_memorization_helper/issues",
          ),
          mode: LaunchMode.externalApplication,
        );
      },
    );
  }

  Widget _email() {
    return ListTile(
      leading: const Icon(Icons.email),
      title: const Text("Email support"),
      subtitle: const Text("Reach out to us via email directly"),
      onTap: () async {
        await launchUrl(
          Uri.parse("support@streetwriters.co"),
          mode: LaunchMode.externalApplication,
        );
      },
    );
  }

  Widget _licenses() {
    return ListTile(
      leading: const Icon(Icons.policy),
      title: const Text("View licenses"),
      subtitle: const Text(
        "View licenses of open source libraries used in this app",
      ),
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
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          _createThemeModeTile(),
          _createMushafSelectionTile(),
          _createReflowModeTile(),
          _createFontSizeTile(),
          _tapToShowTranslationTile(),
          _customTranslationTile(),
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
