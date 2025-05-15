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
  });

  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final VoidCallback? onGoto;
  final bool selectionMode;
  final bool showSurahAyahIndex;
  final bool isSelected;
  final Ayat ayah;

  @override
  State<AyatListItem> createState() => _AyatListItemState();
}

class _AyatListItemState extends State<AyatListItem> {
  void _longPress() {
    assert(widget.onLongPress != null);
    widget.onLongPress!();
  }

  VoidCallback? _getLongPressCallback() {
    if (widget.onLongPress != null && !widget.selectionMode) {
      return _longPress;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isIndoPk = isIndoPak(Settings.instance.mushaf);
    return ListTile(
      leading:
          widget.selectionMode
              ? Icon(
                widget.isSelected
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
              )
              : null,
      title: RichText(
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
      ),
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
      onLongPress: _getLongPressCallback(),
      onTap: widget.selectionMode ? widget.onTap : null,
    );
  }
}
