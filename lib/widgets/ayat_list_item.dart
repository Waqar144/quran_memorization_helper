import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/utils/colors.dart';
import 'package:quran_memorization_helper/utils/utils.dart';

class AyatListItem extends StatefulWidget {
  const AyatListItem({
    super.key,
    required this.ayah,
    this.onLongPress,
    this.onTap,
    this.onGoto,
    this.isSelected = false,
    this.selectionMode = false,
    this.showSurahAyahIndex = true,
    this.onSelectedChanged,
  });

  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final VoidCallback? onGoto;
  final Function(bool?)? onSelectedChanged;
  final bool selectionMode;
  final bool showSurahAyahIndex;
  final bool isSelected;
  final Ayat ayah;

  @override
  State<AyatListItem> createState() => _AyatListItemState();
}

class _AyatListItemState extends State<AyatListItem> {
  @override
  Widget build(BuildContext context) {
    final isIndoPk = isIndoPak(Settings.instance.mushaf);

    final text = RichText(
      text: TextSpan(
        children: textSpansForAyah(widget.ayah),
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color,
          fontFamily: getQuranFont(),
          fontSize: Settings.instance.fontSize.toDouble(),
          letterSpacing: 0,
          wordSpacing: Settings.wordSpacing,
          height: isIndoPk ? 1.7 : null,
        ),
      ),
      softWrap: true,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
    );

    if (widget.selectionMode) {
      if (widget.onSelectedChanged == null) {
        throw "Expected an onSelectedChanged handler";
      }
      return CheckboxListTile(
        value: widget.isSelected,
        onChanged: widget.onSelectedChanged,
        title: text,
        subtitle:
            widget.showSurahAyahIndex
                ? Text(widget.ayah.surahAyahText())
                : null,
      );
    }

    return ListTile(
      title: text,
      subtitle: Row(
        children: [
          if (widget.showSurahAyahIndex) Text(widget.ayah.surahAyahText()),
          if (widget.onGoto != null)
            IconButton(
              onPressed: widget.onGoto,
              icon: const Icon(Icons.shortcut),
            ),
        ],
      ),
      onLongPress: widget.onLongPress,
      onTap: widget.onTap,
    );
  }
}
